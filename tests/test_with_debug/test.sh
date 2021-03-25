#!/usr/bin/env bash
echo 'Start  : tests/test_with_debug'

TERRAFORM_TFVARS='tests/test_with_debug/terraform.tfvars'
EXPECTED_VARIABLES='tests/test_with_debug/expected_variables'

PLAN_FILE='test-reports/test_with_debug.plan'
PLAN_LOG_FILE='test-reports/test_with_debug.plan.log'
PLAN_ERROR_FILE='test-reports/test_with_debug.plan.error.log'
STATE_FILE='test-reports/test_with_debug.tfstate'
APPLY_LOG_FILE='test-reports/test_with_debug.apply.log'
APPLY_ERROR_FILE='test-reports/test_with_debug.apply.error.log'

terraform plan -var-file=${TERRAFORM_TFVARS} -out=${PLAN_FILE} > ${PLAN_LOG_FILE} 2> ${PLAN_ERROR_FILE}
if [[ ! -f ${PLAN_FILE} ]]; then
  echo 'Failed to generate plan file.';
  exit 1;
fi

if [[ ! "$(terraform show -json ${PLAN_FILE} | jq -cMSr .variables)" == "$(cat ${EXPECTED_VARIABLES})" ]]; then
  echo 'Failed to incorporate expected variable values into plan.';
  exit 2;
fi

# Waiting for a mechanism to be able to make calls to AWS that do not require authentication and can return JSON.

#terraform apply -auto-approve -backup=- -state-out ${STATE_FILE} -var-file ${TERRAFORM_TFVARS} > ${APPLY_LOG_FILE} 2> ${APPLY_ERROR_FILE}
#
#if [[ ! -f ${STATE_FILE} ]]; then
#  echo 'Failed to generate state file.';
#  exit 3;
#fi
#
## Extract some content the state file.
#if [[ ! "$(cat ${STATE_FILE})" =~ "AWSCertificateManager" ]]; then
#  echo 'Failed to retrieve expected content from AWS.';
#  exit 4;
#fi
#
#if [[ ! -f test-reports/test_with_debug.debug.log ]]; then
#  echo 'Failed to generate debug.log file.';
#  exit 5;
#fi

echo 'Passed : tests/test_with_debug'
