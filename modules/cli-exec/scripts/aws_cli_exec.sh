#!/usr/bin/env bash
# Runs mutating AWS CLI commands on behalf of the cli-exec module, from a `local-exec` provisioner (apply time only).
#
# Input: the environment variable TF_AWS_CLI_EXEC_INPUT, a JSON document built by modules/cli-exec/main.tf.
#
# No value is ever passed through `eval` or re-parsed by a shell: every argument is read from JSON as a NUL-delimited
# list and used as a single element of a bash array. Credentials are held in this process's environment only. The AWS
# CLI's stdout is discarded unless show_output is true. This script must remain compatible with bash 3.2 (macOS).

# The jq filters below use jq's own $variables, which must not be expanded by the shell.
# shellcheck disable=SC2016

set -euo pipefail
# Never trace: tracing would print the assumed credentials.
set +x
# Everything this script creates is private to the current user.
umask 077

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../../scripts/lib/aws_credentials.sh
. "${SCRIPT_DIR}/../../../scripts/lib/aws_credentials.sh"

fail() {
  printf 'cli-exec: %s\n' "$1" >&2
  exit 1
}

command -v aws >/dev/null 2>&1 || fail 'aws cli is not installed'
command -v jq >/dev/null 2>&1 || fail 'jq is not installed'

INPUT="${TF_AWS_CLI_EXEC_INPUT:-}"
[ -n "${INPUT}" ] || fail 'TF_AWS_CLI_EXEC_INPUT is not set'
printf '%s' "${INPUT}" | jq -e 'type == "object"' >/dev/null || fail 'TF_AWS_CLI_EXEC_INPUT is not a JSON object'

# Run a jq filter (a constant in this script) against the input, followed by any extra jq arguments.
input_jq() {
  local filter="$1"
  shift
  printf '%s' "${INPUT}" | jq "$@" "${filter}"
}

# Read the list of strings produced by a jq filter into the global ARGV array. Items are NUL-delimited so that any
# character (spaces, quotes, newlines, `$()`) survives literally. NUL itself cannot appear in an argument.
read_argv() {
  local filter="$1"
  shift
  input_jq "(${filter}) | (type == \"array\") and all(.[]; type == \"string\" and (contains(\"\\u0000\") | not))" -e "$@" >/dev/null ||
    fail 'every command must be a list of strings without NUL characters'
  ARGV=()
  while IFS= read -r -d '' item; do
    ARGV+=("${item}")
  done < <(input_jq "(${filter})[] | (., \"\\u0000\")" -j "$@")
}

SHOW_OUTPUT=$(input_jq '.show_output // false' -r)
REGION_NAME=$(input_jq '.region // ""' -r)
CREDENTIALS=$(input_jq '.credentials // {"mode": "ambient"}' -c)

WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/terraform-aws-cli.XXXXXXXX")
trap 'rm -rf "${WORK_DIR}"' EXIT

aws_credentials_acquire "${CREDENTIALS}" "${WORK_DIR}" || exit 1

export AWS_PAGER=""
if [ -n "${REGION_NAME}" ]; then
  export AWS_REGION="${REGION_NAME}" AWS_DEFAULT_REGION="${REGION_NAME}"
fi

ERROR_CODE_PATTERN='An error occurred \(([A-Za-z0-9._-]+)\)'

# Is the AWS error code in the ignore list?
is_ignored_error_code() {
  input_jq '(.ignore_error_codes // []) | index($code) != null' -e --arg code "$1" >/dev/null
}

# run_aws <label> <stdout-file> <argv...>
# Runs one AWS CLI command. Fails the apply unless it succeeds, or fails with an error code in ignore_error_codes.
run_aws() {
  local label="$1"
  local stdout_file="$2"
  shift 2
  local error_output error_code

  printf 'cli-exec: %s: aws %s %s\n' "${label}" "${1:-}" "${2:-}"
  if aws "$@" >"${stdout_file}" 2>"${WORK_DIR}/stderr.log"; then
    return 0
  fi

  error_output=$(cat "${WORK_DIR}/stderr.log")
  if [[ ${error_output} =~ ${ERROR_CODE_PATTERN} ]]; then
    error_code="${BASH_REMATCH[1]}"
    if is_ignored_error_code "${error_code}"; then
      printf 'cli-exec: %s: ignored error code %s\n' "${label}" "${error_code}"
      return 0
    fi
  fi
  printf '%s\n' "${error_output}" >&2
  fail "${label} failed"
}

# Where the AWS CLI's stdout goes: the terminal (Terraform's apply output) if show_output, otherwise nowhere.
if [ "${SHOW_OUTPUT}" = "true" ]; then
  COMMAND_OUTPUT=/dev/stdout
else
  COMMAND_OUTPUT=/dev/null
fi

# Run the commands, in order.
COMMAND_COUNT=$(input_jq '.commands // [] | length' -r)
index=0
while [ "${index}" -lt "${COMMAND_COUNT}" ]; do
  read_argv '.commands[$i]' --argjson i "${index}"
  [ "${#ARGV[@]}" -gt 0 ] || fail "command $((index + 1)) is empty"
  run_aws "command $((index + 1))/${COMMAND_COUNT}" "${COMMAND_OUTPUT}" "${ARGV[@]}"
  index=$((index + 1))
done
