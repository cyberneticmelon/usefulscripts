#!/bin/bash

# Default branch to switch to if not specified
branch="${1:-main}"

# Loop through each directory in the current folder
for dir in */; do
  # Check if it's a directory
  if [[ -d "$dir" ]]; then
    echo "Checking $dir..."

    # Navigate into the directory
    cd "$dir" || continue

    # Check if it's a Git repository
    if git rev-parse --git-dir >/dev/null 2>&1; then
      # Try to switch to the specified branch and capture the output and error
      switch_output=$(git switch "$branch" 2>&1)
      if [[ $? -eq 0 ]]; then
        echo "✅ Successfully switched to '$branch' in $dir"
      else
        echo "❌ Failed to switch to '$branch' in $dir"
        echo "   Error: $switch_output"
      fi
    else
      echo "❌ $dir is not a Git repository"
    fi

    # Go back to the parent directory
    cd - >/dev/null 2>&1
  fi
done

echo "Done!"
