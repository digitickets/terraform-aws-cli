#!/usr/bin/env bash
# Runs every check for this repository. Used by CI and locally. Never contacts AWS: a fake `aws` (tests/stubs/aws) is
# put first on PATH, and the AWS CLI configuration and credentials are pointed at nothing.
#
# Requires: terraform, jq, shellcheck, bash.

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT}"

export PATH="${ROOT}/tests/stubs:${PATH}"
export AWS_CONFIG_FILE=/dev/null AWS_SHARED_CREDENTIALS_FILE=/dev/null
unset AWS_PROFILE AWS_DEFAULT_PROFILE AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
export TF_IN_AUTOMATION=1 TF_CLI_ARGS="-no-color"

section() { printf '\n== %s ==\n' "$1"; }

[ "$(command -v aws)" = "${ROOT}/tests/stubs/aws" ] || {
  echo 'The fake aws is not first on PATH; refusing to run.' >&2
  exit 1
}

TERRAFORM_DIRECTORIES=(.)
for directory in modules/* examples/*; do
  if [ -d "${directory}" ]; then
    TERRAFORM_DIRECTORIES+=("${directory}")
  fi
done

section 'shellcheck'
SCRIPTS=()
while IFS= read -r -d '' script; do
  SCRIPTS+=("${script}")
done < <(find . -path ./.terraform -prune -o -path '*/.terraform' -prune -o -type f \( -name '*.sh' -o -path ./tests/stubs/aws \) -print0 | sort -z)
shellcheck "${SCRIPTS[@]}"
printf '%s\n' "${SCRIPTS[@]}"

section 'terraform fmt'
terraform fmt -check -recursive -diff

section 'terraform validate'
for directory in "${TERRAFORM_DIRECTORIES[@]}"; do
  printf -- '-- %s: ' "${directory}"
  (cd "${directory}" && terraform init -backend=false -input=false >/dev/null && terraform validate)
done

section 'script tests'
bash tests/script/test_scripts.sh

section 'terraform test'
for directory in . modules/cli-read modules/cli-exec; do
  printf -- '-- %s\n' "${directory}"
  export FAKE_AWS_LOG="${ROOT}/${directory}/.fake_aws.log"
  rm -f "${FAKE_AWS_LOG}"
  (cd "${directory}" && terraform init -backend=false -input=false >/dev/null && terraform test)
  rm -f "${FAKE_AWS_LOG}"
done

section 'All checks passed'
