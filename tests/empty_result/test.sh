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

# Validate the presence of the plan error file.
if [[ ! -f $PLAN_ERROR_FILE ]]; then
  echo "Failed to generate plan error file - $PLAN_ERROR_FILE";
  exit 4;
fi

# Validate the plan error file is empty.
if [[ -s $PLAN_ERROR_FILE ]]; then
  echo "Plan error file is not empty - $PLAN_ERROR_FILE";
  exit 5;
fi
}

# Set to true to allow this test to run
RUN_TEST=false
if [[ "$RUN_TEST" == "false" ]]; then
  echo "Start   : $(dirname $0)";
  echo "Skipped : $(dirname $0) : See $(dirname $0)/notes.txt";
else
  . tests/common.sh $0
fi
