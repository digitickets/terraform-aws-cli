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

if [[ ! "$(cat $DEBUG_LOG_FILE)" == *'The config profile (this_profile_does_not_exist) could not be found'* ]]; then
  echo 'Failed to generate error from bad profile name.';
  exit 3;
fi
}

. tests/common.sh $0
