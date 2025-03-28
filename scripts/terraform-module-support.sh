#!/usr/bin/env bash

set -o pipefail

remote="$1"
url="$2"

# Get the branch being pushed
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Find the range of commits being pushed
upstream_commit=$(git merge-base HEAD origin/"$current_branch")
changes=$(git diff --name-only "$upstream_commit" HEAD)

# Check if CHANGELOG.md is in the list of changed files
if ! echo "$changes" | grep -q "CHANGELOG.md"; then
    echo "Warning: You are pushing to '$current_branch' without modifying CHANGELOG.md."
    echo "Consider updating the changelog before pushing."
    echo ""
    echo "You can use --no-verify to ignore this."
    exit 1  # Fails the push
fi

exit 0
