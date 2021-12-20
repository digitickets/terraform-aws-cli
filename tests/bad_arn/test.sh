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

if [[ ! "$(cat $PLAN_ERROR_FILE)" == *'The optional ARN must match the format documented in'* ]]; then
  echo 'Failed to detect invalid ARN.';
  exit 3;
fi
}

. tests/common.sh $0
