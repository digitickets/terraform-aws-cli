#!/usr/bin/env bash
echo 'Start  : tests/role_session_name_too_long'

TERRAFORM_TFVARS='tests/role_session_name_too_long/terraform.tfvars'

PLAN_FILE='test-reports/role_session_name_too_long.plan'
PLAN_LOG_FILE='test-reports/role_session_name_too_long.plan.log'
PLAN_ERROR_FILE='test-reports/role_session_name_too_long.plan.error.log'

terraform plan -var-file=${TERRAFORM_TFVARS} -out=${PLAN_FILE} > ${PLAN_LOG_FILE} 2> ${PLAN_ERROR_FILE}

if [[ -f ${PLAN_FILE} ]]; then
  echo 'Generated a plan file for invalid variables.';
  exit 1;
fi

if [[ ! "$(cat ${PLAN_LOG_FILE})" = "" ]]; then
  echo 'Generated a plan log file for invalid variables.';
  exit 2;
fi

if [[ ! "$(cat ${PLAN_ERROR_FILE})" =~ 'The role session name must be less than or equal to 64 characters' ]]; then
  echo 'Failed to detect too long role_session_name.';
  exit 3;
fi

echo 'Passed : tests/role_session_name_too_long'
