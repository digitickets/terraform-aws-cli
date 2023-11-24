#!/usr/bin/env bash

function run_test() {
if [[ ! "$(cat $PLAN_ERROR_FILE)" == *'The role session name match the regular expression'* ]]; then
  echo 'Failed to detect invalid characters in role_session_name.';
  exit 1;
fi
}

. tests/common.sh $0
