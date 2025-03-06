#!/bin/bash

# Check if cargo is installed
if ! command -v cargo &> /dev/null; then
  echo "Cargo not found! Please install Rust and Cargo first."
  exit 1
fi

# Initialize arrays to store results
successful_builds=()
failed_builds=()
no_cargo_toml=()

# Loop through each directory in the current folder
for dir in */; do
  # Check if it's a directory
  if [[ -d "$dir" ]]; then
    # Check if it contains a Cargo.toml file
    if [[ -f "$dir/Cargo.toml" ]]; then
      echo "🛠️ Building project in $dir..."
      (cd "$dir" && cargo build > /dev/null 2>&1)
      if [[ $? -eq 0 ]]; then
        successful_builds+=("$dir")
        echo "✅ Successfully built project in $dir."
      else
        failed_builds+=("$dir")
        echo "❌ Failed to build project in $dir."
      fi
    else
      no_cargo_toml+=("$dir")
      echo "ℹ️ No Cargo.toml file found in $dir."
    fi
  fi
done

# Print the final report
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
echo "ℹ️ Directories without Cargo.toml:"
for dir in "${no_cargo_toml[@]}"; do
  echo "  - $dir"
done

echo ""
echo "Done!"
