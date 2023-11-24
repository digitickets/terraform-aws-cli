#!/usr/bin/env bash

function run_test() {
if [[ ! "$(cat $PLAN_ERROR_FILE)" == *'The role session name must be less than or equal to 64 characters'* ]]; then
  echo 'Failed to detect too long role_session_name.';
  exit 1;
fi
}

. tests/common.sh $0
