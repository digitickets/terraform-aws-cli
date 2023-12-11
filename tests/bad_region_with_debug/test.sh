#!/usr/bin/env bash

function run_test() {
if [[ ! "$(cat $DEBUG_LOG_FILE)" == *"Provided region_name 'US East (Ohio) us-east-2' doesn't match a supported format."* ]]; then
  echo 'Failed to generate error from bad region.';
  exit 1;
fi
}

. tests/common.sh $0
