#!/usr/bin/env bash

set -euo pipefail

# ------------------------
# Validate AWS credentials
# ------------------------
validate_credentials() {
  if [[ -z "${AWS_SESSION_TOKEN:-}" ]]; then
    echo 'Missing or expired AWS credentials.' >&2
    echo 'This may cause Terraform Validation to fail.' >&2
    exit 1
  fi
}

# -------------------------------
# Generate aliased-providers.json
# -------------------------------
setup_module() {
  output=$(terraform-config-inspect --json . | jq -r '
    [.required_providers[].aliases]
    | flatten
    | del(.[] | select(. == null))
    | reduce .[] as $entry (
        {};
        .provider[$entry.name] //= []
        | .provider[$entry.name] += [{"alias": $entry.alias}]
      )')

  # Only write if jq produced valid non-empty JSON with providers
  if jq -e '.provider | length > 0' <<<"$output" >/dev/null 2>&1; then
    echo "$output" > aliased-providers.tf.json
  fi
}

# -----------------------------
# Remove aliased-providers.json
# -----------------------------
teardown_module() {
  rm -f aliased-providers.tf.json
}

# ------------------------
# Check and parse argument
# ------------------------
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 {setup|teardown}"
  exit 1
fi

action=$1
case "$action" in
  setup) validate_credentials ;;
  teardown) ;;
  *)
    echo "Invalid argument: $action"
    echo "Usage: $0 {setup|teardown}"
    exit 1
    ;;
esac

# -------------------------------
# Iterate over module directories
# -------------------------------
while IFS= read -r dir; do
  echo "Running $action in $dir"
  (
    cd "$dir" || { echo "Failed to cd into $dir"; exit 1; }
    case "$action" in
      setup) setup_module ;;
      teardown) teardown_module ;;
    esac
  )
done < <(find ./modules -type f -name "versions.tf" -exec dirname {} \; | sort -u)
