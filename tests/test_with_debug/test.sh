#!/usr/bin/env bash

function run_test() {
if [[ ! -f $PLAN_FILE ]]; then
  echo "Failed to generate a plan - $PLAN_FILE";
  exit 1;
fi

if [[ ! "$(terraform show -json $PLAN_FILE | jq -MSr .variables)" == "$(cat $EXPECTED_VARIABLES)" ]]; then
  echo 'Failed to incorporate expected variable values into plan.';
  exit 2;
fi

terraform apply -auto-approve -backup=- -state-out $STATE_FILE -var-file $TERRAFORM_TFVARS > $APPLY_LOG_FILE 2> $APPLY_ERROR_FILE

if [[ ! -f $STATE_FILE ]]; then
  echo "Failed to generate state file - $STATE_FILE";
  exit 3;
fi

# Extract some content the state file.
if [[ ! "$(cat $STATE_FILE)" == *'0ae8f910a30bc83fd81c4e3c1a6bbd9bab0afe4e0762b56a2807d22fcd77d517'* ]]; then
  echo 'Failed to retrieve expected content from AWS.';
  exit 4;
fi

# Extract some content from the apply log.
if [[ ! "$(cat $APPLY_LOG_FILE)" == *"0ae8f910a30bc83fd81c4e3c1a6bbd9bab0afe4e0762b56a2807d22fcd77d517"* ]]; then
  echo 'Failed to present expected content to Terraform.';
  exit 5;
fi

# Validate the presence of the debug log.
if [[ ! -f $DEBUG_LOG_FILE ]]; then
  echo "Failed to generate debug.log file - $DEBUG_LOG_FILE";
  exit 6;
fi
}

. tests/common.sh $0
