#!/usr/bin/env bash
# Script-level tests for modules/cli-read/scripts/aws_cli_runner.sh and modules/cli-exec/scripts/aws_cli_exec.sh.
#
# Both scripts are run directly against the fake `aws` (tests/stubs/aws), which records the exact argv it receives. No
# real AWS CLI is ever invoked. Run via tests/run.sh, or directly with bash.

# Several checks pass a single-quoted snippet to `bash -c` that uses its own positional parameters, and several test
# descriptions mention `$()` literally; neither must be expanded by this shell.
# shellcheck disable=SC2016

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
READ_SCRIPT="${ROOT}/modules/cli-read/scripts/aws_cli_runner.sh"
EXEC_SCRIPT="${ROOT}/modules/cli-exec/scripts/aws_cli_exec.sh"
export PATH="${ROOT}/tests/stubs:${PATH}"

SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/terraform-aws-cli-tests.XXXXXXXX")
trap 'rm -rf "${SANDBOX}"' EXIT
export TMPDIR="${SANDBOX}/tmp"
mkdir -p "${TMPDIR}"
export FAKE_AWS_LOG="${SANDBOX}/aws.log"
CANARY="${SANDBOX}/canary"

FAILURES=0
pass() { printf '  pass: %s\n' "$1"; }
failed() {
  printf '  FAIL: %s\n' "$1"
  FAILURES=$((FAILURES + 1))
}
check() {
  local description="$1"
  shift
  if "$@"; then pass "${description}"; else failed "${description}"; fi
}
reset_log() { : >"${FAKE_AWS_LOG}"; }
# The argv of the Nth (1-based) logged aws invocation, as compact JSON.
logged_argv() { sed -n "${1}p" "${FAKE_AWS_LOG}" | jq -c '.argv'; }
log_lines() { wc -l <"${FAKE_AWS_LOG}" | tr -d ' '; }
no_leftover_temp_files() { [ -z "$(ls -A "${TMPDIR}")" ]; }

# Arguments that would do something if they ever reached a shell.
HOSTILE_ARGS=$(
  jq -cn --arg canary "${CANARY}" '[
    "value with spaces",
    "single '\''quoted'\'' and double \"quoted\"",
    "$(touch \($canary))",
    "`touch \($canary)`",
    "; touch \($canary) #",
    "| touch \($canary)",
    "&& touch \($canary)",
    "line one\nline two\n",
    "*",
    "~",
    "$HOME ${PATH} \\n \\\\",
    "-- --leading-dashes",
    ""
  ]'
)

echo 'cli-read script'

reset_log
INPUT=$(jq -cn --argjson hostile "${HOSTILE_ARGS}" '{
  aws_cli_commands: (["ec2", "describe-instances"] + $hostile),
  aws_cli_query: "Reservations[?Name == '\''$(touch x)'\'']",
  credentials: {mode: "ambient"}, profile: "", region: "", retries_max_attempts: "4", retries_mode: "standard",
  debug_log_dir: ""
}')
OUTPUT=$(jq -cn --arg input "${INPUT}" '{input: $input}' | bash "${READ_SCRIPT}")
EXPECTED=$(jq -cn --argjson hostile "${HOSTILE_ARGS}" \
  '["ec2", "describe-instances"] + $hostile + ["--query", "Reservations[?Name == '\''$(touch x)'\'']", "--output", "json"]')
check 'arguments with spaces, quotes, $(), backticks, newlines and globs reach aws literally' \
  test "$(logged_argv 1)" = "${EXPECTED}"
check 'the AWS CLI output is returned in-band as content' \
  test "$(printf '%s' "${OUTPUT}" | jq -c '.content | fromjson | .argv')" = "${EXPECTED}"
check 'no embedded shell command was executed' test ! -e "${CANARY}"
check 'no temporary files are left behind' no_leftover_temp_files

reset_log
INPUT=$(jq -cn '{
  aws_cli_commands: ["ec2", "describe-instances"], aws_cli_query: "",
  credentials: {mode: "assume_role", role_arn: "arn:aws:iam::777788889999:role/reader", session_name: "",
    external_id: "", profile: "source", region: ""},
  profile: "source", region: "", retries_max_attempts: "4", retries_mode: "standard", debug_log_dir: ""
}')
OUTPUT=$(jq -cn --arg input "${INPUT}" '{input: $input}' | AWS_PROFILE=inherited bash "${READ_SCRIPT}")
check 'the assumed credentials are used, with no profile, once a role is assumed' \
  test "$(sed -n 2p "${FAKE_AWS_LOG}" | jq -c '[.argv, .access_key_id, .aws_profile]')" = \
  '[["ec2","describe-instances","--output","json"],"ASIAFAKE777788889999",""]'
check 'the credentials are not in the output' bash -c '! grep -q fake-secret <<<"$1"' _ "${OUTPUT}"
check 'no temporary files are left behind after assuming a role' no_leftover_temp_files

reset_log
INPUT=$(jq -cn --arg dir "${SANDBOX}/debug" '{
  aws_cli_commands: ["ec2", "describe-instances", "--fake-error=UnauthorizedOperation"], aws_cli_query: "",
  credentials: {mode: "assume_role", role_arn: "arn:aws:iam::777788889999:role/reader"},
  profile: "", region: "", retries_max_attempts: "4", retries_mode: "standard", debug_log_dir: $dir
}')
OUTPUT=$(jq -cn --arg input "${INPUT}" '{input: $input}' | bash "${READ_SCRIPT}")
check 'AWS errors are returned as an error document' \
  test "$(printf '%s' "${OUTPUT}" | jq -r '.content | fromjson | .error')" = \
  'aws: [ERROR]: An error occurred (UnauthorizedOperation) when calling the StubOperation operation: stub failure'
check 'the debug log is created only when asked for, and is private' \
  test "$(stat -c '%a' "${SANDBOX}/debug" 2>/dev/null || stat -f '%Lp' "${SANDBOX}/debug")" = 700
check 'the debug log records the call and the failure' \
  test "$(jq -r '.event' "${SANDBOX}/debug/cli-read.log" | tr '\n' ' ')" = 'call failure '
check 'the debug log never contains credentials' bash -c '! grep -rq -e fake-secret -e fake-token "$1"' _ "${SANDBOX}/debug"
check 'no temporary files are left behind after an AWS error' no_leftover_temp_files

reset_log
INPUT=$(jq -cn '{
  aws_cli_commands: ["ec2", "describe-instances"], aws_cli_query: "",
  credentials: {mode: "assume_role", role_arn: "arn:aws:iam::777788889999:role/denied"},
  profile: "", region: "", retries_max_attempts: "4", retries_mode: "standard", debug_log_dir: ""
}')
if ERROR=$(jq -cn --arg input "${INPUT}" '{input: $input}' | bash "${READ_SCRIPT}" 2>&1 >/dev/null); then
  failed 'a failure to assume the role fails the script'
else
  pass 'a failure to assume the role fails the script'
fi
check 'the role assumption error explains why' bash -c 'grep -q "AccessDenied" <<<"$1"' _ "${ERROR}"
check 'the command is not run when the role cannot be assumed' test "$(log_lines)" = 1
check 'no temporary files are left behind after a role assumption failure' no_leftover_temp_files

echo 'cli-exec script'

run_exec() {
  TF_AWS_CLI_EXEC_INPUT="$1" bash "${EXEC_SCRIPT}"
}

reset_log
INPUT=$(jq -cn --argjson hostile "${HOSTILE_ARGS}" '{
  commands: [(["ec2", "create-tags"] + $hostile), ["ec2", "create-tags", "--second"]],
  credentials: {mode: "assume_role", role_arn: "arn:aws:iam::123412341234:role/deployer", session_name: "S1",
    external_id: "", profile: "", region: "eu-west-2"},
  region: "eu-west-2", show_output: false, ignore_error_codes: []
}')
STDOUT=$(run_exec "${INPUT}")
check 'arguments with spaces, quotes, $(), backticks, newlines and globs reach aws literally' \
  test "$(logged_argv 2)" = "$(jq -cn --argjson hostile "${HOSTILE_ARGS}" '["ec2", "create-tags"] + $hostile')"
check 'commands run in order, with the assumed credentials' \
  test "$(sed -n 3p "${FAKE_AWS_LOG}" | jq -c '[.argv, .access_key_id]')" = '[["ec2","create-tags","--second"],"ASIAFAKE123412341234"]'
check 'no embedded shell command was executed' test ! -e "${CANARY}"
check 'the AWS CLI output is discarded unless show_output is true' bash -c '! grep -q argv <<<"$1"' _ "${STDOUT}"
check 'no temporary files are left behind' no_leftover_temp_files

reset_log
INPUT=$(jq -cn '{commands: [["ec2", "create-tags", "--shown"]], credentials: {mode: "ambient"}, region: "",
  show_output: true, ignore_error_codes: []}')
STDOUT=$(run_exec "${INPUT}")
check 'the AWS CLI output is shown when show_output is true' bash -c 'grep -q -- "--shown" <<<"$1"' _ "${STDOUT}"

reset_log
INPUT=$(jq -cn '{
  commands: [["logs", "create-log-group", "--fake-error=ResourceAlreadyExistsException"], ["ec2", "after-ignored"]],
  credentials: {mode: "ambient"}, region: "", show_output: false,
  ignore_error_codes: ["ResourceAlreadyExistsException"]
}')
if STDOUT=$(run_exec "${INPUT}"); then pass 'an error code in ignore_error_codes is treated as success'; else failed 'an error code in ignore_error_codes is treated as success'; fi
check 'commands after an ignored error still run' test "$(logged_argv 2)" = '["ec2","after-ignored"]'
check 'an ignored error is reported' bash -c 'grep -q "ignored error code ResourceAlreadyExistsException" <<<"$1"' _ "${STDOUT}"

reset_log
INPUT=$(jq -cn '{
  commands: [["logs", "create-log-group", "--fake-error=AccessDeniedException"], ["ec2", "never-run"]],
  credentials: {mode: "ambient"}, region: "", show_output: false,
  ignore_error_codes: ["ResourceAlreadyExistsException"]
}')
if ERROR=$(run_exec "${INPUT}" 2>&1 >/dev/null); then failed 'an error code not in ignore_error_codes fails'; else pass 'an error code not in ignore_error_codes fails'; fi
check 'the failing error is shown' bash -c 'grep -q "AccessDeniedException" <<<"$1"' _ "${ERROR}"
check 'no further commands run after a failure' test "$(log_lines)" = 1
check 'no temporary files are left behind after a failure' no_leftover_temp_files

reset_log
INPUT=$(jq -cn '{commands: [["ec2", "create-tags"]],
  credentials: {mode: "assume_role", role_arn: "arn:aws:iam::123412341234:role/deployer"},
  region: "", show_output: true, ignore_error_codes: []}')
ALL_OUTPUT=$(TF_AWS_CLI_EXEC_INPUT="${INPUT}" bash -x "${EXEC_SCRIPT}" 2>&1)
check 'the script ran under bash -x' bash -c 'grep -q "cli-exec: command 1/1" <<<"$1"' _ "${ALL_OUTPUT}"
check 'credentials are never printed, even if tracing is requested by the caller' \
  bash -c '! grep -q -e fake-secret -e fake-token <<<"$1"' _ "${ALL_OUTPUT}"

reset_log
INPUT=$(jq -cn '{commands: [], credentials: {mode: "ambient"}, region: "", show_output: false, ignore_error_codes: [],
  for_each_item_commands: [{
    list: ["logs", "describe-log-groups", "--fake-output=[\"a & b \\\\1\", \"$(touch '"${CANARY}"')\", 7]"],
    query: "logGroups[].logGroupName",
    command: ["logs", "put-retention-policy", "--log-group-name", "x-{{item}}-{{item}}"],
    max_items: 3
  }]}')
run_exec "${INPUT}" >/dev/null
check 'per-item commands substitute each item literally' \
  test "$(jq -c '.argv[3]' "${FAKE_AWS_LOG}" | sed -n '2,4p' | tr '\n' ' ')" = \
  "\"x-a & b \\\\1-a & b \\\\1\" \"x-\$(touch ${CANARY})-\$(touch ${CANARY})\" \"x-7-7\" "
check 'no item was executed by a shell' test ! -e "${CANARY}"

reset_log
INPUT=$(jq -cn '{commands: [], credentials: {mode: "ambient"}, region: "", show_output: false, ignore_error_codes: [],
  for_each_item_commands: [{list: ["logs", "describe-log-groups", "--fake-output=[\"a\", \"b\", \"c\"]"],
    query: "q", command: ["logs", "delete-log-group", "{{item}}"], max_items: 2}]}')
if ERROR=$(run_exec "${INPUT}" 2>&1 >/dev/null); then failed 'more items than max_items fails'; else pass 'more items than max_items fails'; fi
check 'nothing is run when there are more items than max_items' test "$(log_lines)" = 1

reset_log
INPUT=$(jq -cn '{commands: [], credentials: {mode: "ambient"}, region: "", show_output: false, ignore_error_codes: [],
  for_each_item_commands: [{list: ["logs", "describe-log-groups", "--fake-output=null"],
    query: "q", command: ["logs", "delete-log-group", "{{item}}"], max_items: 2}]}')
check 'a null list is treated as empty' bash -c 'TF_AWS_CLI_EXEC_INPUT="$1" bash "$2" >/dev/null' _ "${INPUT}" "${EXEC_SCRIPT}"
check 'nothing is run for an empty list' test "$(log_lines)" = 1

reset_log
INPUT=$(jq -cn '{commands: [], credentials: {mode: "ambient"}, region: "", show_output: false, ignore_error_codes: [],
  for_each_item_commands: [{list: ["logs", "describe-log-groups", "--fake-output={\"not\": \"a list\"}"],
    query: "q", command: ["logs", "delete-log-group", "{{item}}"], max_items: 2}]}')
if run_exec "${INPUT}" >/dev/null 2>&1; then failed 'a list query that is not an array fails'; else pass 'a list query that is not an array fails'; fi

if [ "${FAILURES}" -gt 0 ]; then
  printf '%s script test(s) failed\n' "${FAILURES}"
  exit 1
fi
echo 'All script tests passed'
