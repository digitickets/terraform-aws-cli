#!/usr/bin/env bash

set -o pipefail

# Get the branch being pushed
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Exit early if the current branch is master
if [ "$current_branch" = "master" ]; then
    exit 0
fi

# Check if CHANGELOG.md is in the list of files supplied by the pre-commit application.
if ! echo "$@" | grep -q "CHANGELOG.md"; then
    echo "Warning: You are pushing to '$current_branch' without modifying CHANGELOG.md."
    echo "Consider updating the CHANGELOG.md before pushing."
    echo ""
    echo "You can use the --no-verify option to ignore this restriction."
    exit 1  # Fails the push
fi

exit 0
