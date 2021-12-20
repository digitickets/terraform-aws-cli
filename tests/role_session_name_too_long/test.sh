#!/usr/bin/env bash

function run_test() {
if [[ -f $PLAN_FILE ]]; then
  echo "Incorrectly generated a plan - $PLAN_FILE";
  exit 1;
fi

if [[ ! -z "$(cat $PLAN_LOG_FILE)" ]]; then
  echo "Incorrectly generated content in the plan log file - $PLAN_LOG_FILE";
  exit 2;
fi

if [[ ! "$(cat $PLAN_ERROR_FILE)" == *'The role session name must be less than or equal to 64 characters'* ]]; then
  echo 'Failed to detect too long role_session_name.';
  exit 3;
fi
}

. tests/common.sh $0
