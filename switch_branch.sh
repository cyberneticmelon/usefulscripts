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
    if git rev-parse --git-dir > /dev/null 2>&1; then
      # Try to switch to the specified branch
      if git switch "$branch" > /dev/null 2>&1; then
        echo "✅ Successfully switched to '$branch' in $dir"
      else
        echo "❌ Failed to switch to '$branch' in $dir (branch may not exist)"
      fi
    else
      echo "❌ $dir is not a Git repository"
    fi

    # Go back to the parent directory
    cd - > /dev/null 2>&1
  fi
done

echo "Done!"
