#!/usr/bin/env bash

set -o pipefail

validate_credentials() {
  if [[ "$AWS_SESSION_TOKEN" == "" ]]; then
    echo 'Missing or expired AWS credentials.' >&2
    echo 'This may cause TFLint to fail.' >&2
    exit 1
  fi
}

setup_tflint() {
  terraform-config-inspect --json . |
    jq -r '
      [.required_providers[].aliases]
      | flatten
      | del(.[] | select(. == null))
      | reduce .[] as $entry (
        {};
        .provider[$entry.name] //= []
        | .provider[$entry.name] += [{"alias": $entry.alias}]
      )' > aliased-providers.tf.json || true
}

teardown_tflint() {
  rm -f aliased-providers.tf.json
}

# Check if a function name was provided
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 {setup|teardown}"
    exit 1
fi

# Call the function based on the first argument
case "$1" in
    setup)
        setup_tflint
        validate_credentials
        ;;
    teardown)
        teardown_tflint
        ;;
    *)
        echo "Invalid argument: $1"
        echo "Usage: $0 {setup|teardown}"
        exit 1
        ;;
esac
