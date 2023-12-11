#!/usr/bin/env bash

function run_test() {
if [[ ! "$(cat $PLAN_ERROR_FILE)" == *"Provided region_name 'US East (Ohio) us-east-2' doesn't match a supported"* ]]; then
  echo 'Failed to generate error from bad region.';
  exit 1;
fi
}

. tests/common.sh $0
