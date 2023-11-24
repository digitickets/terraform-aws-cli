#!/usr/bin/env bash

function run_test() {
if [[ ! "$(cat $PLAN_ERROR_FILE)" == *'The optional ARN must match the format documented in'* ]]; then
  echo 'Failed to detect invalid ARN.';
  exit 1;
fi
}

. tests/common.sh $0
