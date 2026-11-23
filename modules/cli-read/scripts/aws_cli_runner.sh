#!/usr/bin/env bash
# Runs a single, read-only AWS CLI call on behalf of the cli-read module (via Terraform's `external` data source).
#
# Input (stdin) : {"input": "<JSON document built by modules/cli-read/main.tf>"}
# Output (stdout): {"content": "<the AWS CLI stdout, or a JSON {\"error\": \"...\"} document>"}
#
# No value is ever passed through `eval` or re-parsed by a shell: every argument is read from JSON as a NUL-delimited
# list and used as a single element of a bash array. This script must remain compatible with bash 3.2 (macOS).

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../../scripts/lib/aws_credentials.sh
. "${SCRIPT_DIR}/../../../scripts/lib/aws_credentials.sh"

fail() {
  printf 'cli-read: %s\n' "$1" >&2
  exit 1
}

command -v aws >/dev/null 2>&1 || fail 'aws cli is not installed'
command -v jq >/dev/null 2>&1 || fail 'jq is not installed'

QUERY_JSON=$(cat)
INPUT=$(printf '%s' "${QUERY_JSON}" | jq -er '.input') || fail 'no input supplied'
printf '%s' "${INPUT}" | jq -e 'type == "object"' >/dev/null || fail 'input is not a JSON object'

# Read a scalar string from the input document.
input_string() {
  printf '%s' "${INPUT}" | jq -r --arg key "$1" '.[$key] // "" | tostring'
}

# Read a list of strings from the input document into the global ARGV array. Items are NUL-delimited so that any
# character (spaces, quotes, newlines, `$()`) survives literally. NUL itself cannot appear in an argument, so reject it.
read_argv() {
  printf '%s' "${INPUT}" | jq -e --arg key "$1" \
    '(.[$key] | type == "array") and all(.[$key][]; type == "string" and (contains("\u0000") | not))' >/dev/null ||
    fail "$1 must be a list of strings without NUL characters"
  ARGV=()
  while IFS= read -r -d '' item; do
    ARGV+=("${item}")
  done < <(printf '%s' "${INPUT}" | jq -j --arg key "$1" '.[$key][] | (., "\u0000")')
}

read_argv aws_cli_commands
AWS_CLI_COMMANDS=(${ARGV[@]+"${ARGV[@]}"})
[ "${#AWS_CLI_COMMANDS[@]}" -gt 0 ] || fail 'aws_cli_commands cannot be empty'

AWS_CLI_QUERY=$(input_string aws_cli_query)
PROFILE_NAME=$(input_string profile)
REGION_NAME=$(input_string region)
RETRIES_MAX_ATTEMPTS=$(input_string retries_max_attempts)
RETRIES_MODE=$(input_string retries_mode)
CREDENTIALS=$(printf '%s' "${INPUT}" | jq -c '.credentials // {"mode": "ambient"}')
CREDENTIALS_MODE=$(printf '%s' "${CREDENTIALS}" | jq -r '.mode // "ambient"')

WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/terraform-aws-cli.XXXXXXXX")
trap 'rm -rf "${WORK_DIR}"' EXIT

# Options shared by every AWS CLI call.
COMMON_OPTIONS=()
if [ -n "${REGION_NAME}" ]; then
  COMMON_OPTIONS+=("--region" "${REGION_NAME}")
fi

# Acquire credentials. When a role is assumed, the temporary credentials are exported into this process only, and
# `--profile` is never passed to the AWS CLI afterwards, as an explicit profile would override them
# (see https://github.com/digitickets/terraform-aws-cli/issues/11). Without a role, the profile is used for the call.
aws_credentials_acquire "${CREDENTIALS}" "${WORK_DIR}" || exit 1
PROFILE_OPTIONS=()
if [ "${CREDENTIALS_MODE}" = "ambient" ] && [ -n "${PROFILE_NAME}" ]; then
  PROFILE_OPTIONS+=("--profile" "${PROFILE_NAME}")
fi

# Do we have a query? Passed as a single argument, so JMESPath quotes need no escaping.
QUERY_OPTIONS=()
if [ -n "${AWS_CLI_QUERY}" ]; then
  QUERY_OPTIONS+=("--query" "${AWS_CLI_QUERY}")
fi

# Disable any assigned pager and configure retries.
export AWS_PAGER=""
export AWS_RETRY_MODE="${RETRIES_MODE}"
export AWS_MAX_ATTEMPTS="${RETRIES_MAX_ATTEMPTS}"

# Run the AWS CLI command. The output is returned in-band, so no results file is left behind.
if aws "${AWS_CLI_COMMANDS[@]}" \
  ${PROFILE_OPTIONS[@]+"${PROFILE_OPTIONS[@]}"} \
  ${COMMON_OPTIONS[@]+"${COMMON_OPTIONS[@]}"} \
  ${QUERY_OPTIONS[@]+"${QUERY_OPTIONS[@]}"} \
  --output json \
  >"${WORK_DIR}/aws_call.json" 2>"${WORK_DIR}/aws_call_error.log"; then
  jq -Rsc '{content: .}' <"${WORK_DIR}/aws_call.json"
else
  # Convert the error into a JSON document, returned as the content.
  jq -Rsc '{content: ({error: gsub("^\n+|\n+$"; "")} | tojson)}' <"${WORK_DIR}/aws_call_error.log"
fi
