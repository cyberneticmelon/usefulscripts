#!/bin/bash

if ! command -v cargo &>/dev/null; then
  echo "Cargo not found! Please install Rust and Cargo first."
  exit 1
fi

# Check for the -nobg flag
nobg_flag=false
for arg in "$@"; do
  if [[ "$arg" == "-nobg" ]]; then
    nobg_flag=true
    break
  fi
done

# Create the StardustXR folder
mkdir -p StardustXR
cd StardustXR || exit

# Array of repository URLs (replace with your actual URLs)
repos=(
  "https://github.com/StardustXR/armillary"
  "https://github.com/StardustXR/atmosphere"
  "https://github.com/StardustXR/black-hole"
  "https://github.com/StardustXR/comet"
  "https://github.com/StardustXR/flatland"
  "https://github.com/StardustXR/gravity"
  "https://github.com/StardustXR/magnetar"
  "https://github.com/StardustXR/non-spatial-input"
  "https://github.com/StardustXR/protostar"
  "https://github.com/StardustXR/server"
  "https://github.com/StardustXR/telescope"
  # Add more repos if you'd like
)

# Clone all repositories
for repo in "${repos[@]}"; do
  git clone "$repo"
done

# Initialize arrays to store build results
successful_builds=()
failed_builds=()
no_cargo_toml=()

# Loop through each directory and build Rust projects
for dir in */; do
  if [[ -d "$dir" ]]; then
    if [[ -f "$dir/Cargo.toml" ]]; then
      echo "🛠 Building project in $dir..."
      (cd "$dir" && cargo build >/dev/null 2>&1)
      if [[ $? -eq 0 ]]; then
        successful_builds+=("$dir")
        echo "✅ Successfully built project in $dir."
      else
        failed_builds+=("$dir")
        echo "❌ Failed to build project in $dir."
      fi
    else
      no_cargo_toml+=("$dir")
      echo "ℹ No Cargo.toml file found in $dir."
    fi
  fi
done

# Print the build report
echo ""
echo "=== Build Report ==="
echo "✅ Successful builds:"
for dir in "${successful_builds[@]}"; do
  echo "  - $dir"
done

echo ""
echo "❌ Failed builds:"
for dir in "${failed_builds[@]}"; do
  echo "  - $dir"
done

echo ""
echo "ℹ Directories without Cargo.toml:"
for dir in "${no_cargo_toml[@]}"; do
  echo "  - $dir"
done

echo ""
echo "Done with builds!"

# Initialize arrays to store symlink creation results
symlinks_created=()
no_elf_found=()
not_a_repo=()

# Ensure ~/.local/bin exists
mkdir -p ~/.local/bin

# Loop through each directory and create/update symlinks for ELF executables
for dir in */; do
  if [[ -d "$dir" ]]; then
    echo "Checking $dir..."

    # Check if it's a Git repository
    if git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
      # Get the current Git branch
      branch=$(git -C "$dir" branch --show-current)

      # Check if the target/debug folder exists
      if [[ -d "$dir/target/debug" ]]; then
        # Find all ELF executables in target/debug
        elf_files=($(find "$dir/target/debug" -maxdepth 1 -type f -executable -exec file {} + | grep "ELF" | cut -d: -f1))

        if [[ ${#elf_files[@]} -gt 0 ]]; then
          # Initialize a variable to track symlinks for this repo
          repo_symlinks=()

          # Loop through each ELF file
          for elf_file in "${elf_files[@]}"; do
            # Get the filename (without path)
            elf_name=$(basename "$elf_file")

            # Create a symlink name with "_dev" appended
            symlink_name="${elf_name}_dev"
            symlink_path="$HOME/.local/bin/$symlink_name"

            # Create a temporary symlink
            temp_symlink=$(mktemp -u "$HOME/.local/bin/${symlink_name}.XXXXXX")
            ln -s "$(realpath "$elf_file")" "$temp_symlink"

            # Atomically replace the existing symlink (if it exists)
            mv -f "$temp_symlink" "$symlink_path"
            repo_symlinks+=("$symlink_name")
            echo "✅ Created/updated symlink '$symlink_name' for ELF file '$elf_name' in $dir (branch: $branch)"
          done

          # Add repo info to the report
          symlinks_created+=("$dir (branch: $branch): ${repo_symlinks[*]}")
        else
          no_elf_found+=("$dir (branch: $branch)")
          echo "ℹ No ELF executables found in $dir/target/debug (branch: $branch)"
        fi
      else
        no_elf_found+=("$dir (branch: $branch)")
        echo "ℹ No target/debug folder found in $dir (branch: $branch)"
      fi
    else
      not_a_repo+=("$dir")
      echo "❌ $dir is not a Git repository"
    fi
  fi
done

# Print the symlink creation report
echo ""
echo "=== Symlink Creation Report ==="
echo "✅ Symlinks created/updated for the following folders:"
for entry in "${symlinks_created[@]}"; do
  echo "  - $entry"
done

echo ""
echo "ℹ No ELF executables found in the following folders:"
for entry in "${no_elf_found[@]}"; do
  echo "  - $entry"
done

echo ""
echo "❌ The following folders are not Git repositories:"
for entry in "${not_a_repo[@]}"; do
  echo "  - $entry"
done

echo ""
echo "Done! Symlinks have been created/updated in ~/.local/bin."

# Create a config file in ~/.config/stardust
config_dir="$HOME/.config/stardust"
config_file="$config_dir/startup"

# Check if the config directory exists, and create it if it doesn't
if [[ ! -d "$config_dir" ]]; then
  echo "ℹ Creating config directory: $config_dir"
  mkdir -p "$config_dir"
fi

# Check if the config file already exists
if [[ -f "$config_file" ]]; then
  echo "ℹ Startup file already located in $config_file. Updating atomically..."

  # Create a temporary file
  temp_file=$(mktemp)
  cat <<EOF >"$temp_file"
#!/usr/bin/env bash

xwayland-satellite :10 &
export DISPLAY=:10

hexagon_launcher_dev &
flatland_dev &
atmosphere_dev show the_grid & # OPTIONAL ATMOSPHERE

WAYLAND_DISPLAY=$FLAT_WAYLAND_DISPLAY manifold_dev | simular_dev
EOF

  # Make the temporary file executable
  chmod +x "$temp_file"

  # Atomically replace the existing file
  mv "$temp_file" "$config_file"
  echo "✅ Updated startup config file atomically: $config_file"
else
  echo "ℹ Creating startup config file: $config_file"
  cat <<EOF >"$config_file"
#!/usr/bin/env bash

xwayland-satellite :10 &
export DISPLAY=:10

hexagon_launcher_dev &
flatland_dev &
atmosphere_dev show the_grid & # OPTIONAL ATMOSPHERE

WAYLAND_DISPLAY=$FLAT_WAYLAND_DISPLAY manifold_dev | simular_dev
EOF

  # Make the config file executable
  chmod +x "$config_file"
  echo "✅ Created and made executable: $config_file"
fi

# Handle the -nobg flag
if [[ "$nobg_flag" == true ]]; then
  echo "ℹ -nobg flag detected. Commenting out the 'OPTIONAL ATMOSPHERE' line in the config file."

  # Create a temporary file
  temp_file=$(mktemp)
  sed '/# OPTIONAL ATMOSPHERE/s/^/# /' "$config_file" >"$temp_file"

  # Atomically replace the existing file
  mv "$temp_file" "$config_file"
  echo "✅ Updated config file atomically to comment out 'OPTIONAL ATMOSPHERE'."
else
  echo "ℹ No -nobg flag detected. Proceeding with the_grid setup."

  # Locate the the_grid folder using the full absolute path
  the_grid_folder="$(pwd)/atmosphere/default_envs/the_grid"
  if [[ -d "$the_grid_folder" ]]; then
    echo "ℹ Found the_grid folder: $the_grid_folder"

    # Check if the destination environment already exists
    environment_dir="$HOME/.local/share/xr_environments/the_grid"
    if [[ -d "$environment_dir" ]]; then
      echo "ℹ Environment 'the_grid' already exists at $environment_dir. Skipping installation."
    else
      echo "ℹ Running 'atmosphere_dev install default_envs/the_grid'..."
      atmosphere_dev install "$the_grid_folder"
    fi

    echo "ℹ Running 'atmosphere_dev set-default the_grid'..."
    atmosphere_dev set-default the_grid
  else
    echo "❌ the_grid folder not found at: $the_grid_folder"
  fi
fi
