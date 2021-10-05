#!/usr/bin/env bash
echo 'Start  : tests/role_session_name_invalid_characters'

TERRAFORM_TFVARS='tests/role_session_name_invalid_characters/terraform.tfvars'

PLAN_FILE='test-reports/role_session_name_invalid_characters.plan'
PLAN_LOG_FILE='test-reports/role_session_name_invalid_characters.plan.log'
PLAN_ERROR_FILE='test-reports/role_session_name_invalid_characters.plan.error.log'

terraform plan -var-file=${TERRAFORM_TFVARS} -out=${PLAN_FILE} > ${PLAN_LOG_FILE} 2> ${PLAN_ERROR_FILE}

if [[ -f ${PLAN_FILE} ]]; then
  echo 'Generated a plan file for invalid variables.';
  exit 1;
fi

if [[ ! "$(cat ${PLAN_LOG_FILE})" = "" ]]; then
  echo 'Generated a plan log file for invalid variables.';
  exit 2;
fi

if [[ ! "$(cat ${PLAN_ERROR_FILE})" =~ 'The role session name match the regular expression' ]]; then
  echo 'Failed to detect invalid characters in role_session_name.';
  exit 3;
fi

echo 'Passed : tests/role_session_name_invalid_characters'
