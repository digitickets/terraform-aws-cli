#!/usr/bin/env bash
echo 'Start  : tests/bad_arn'

if [[ ! "$(terraform plan -var-file='tests/bad_arn/terraform.tfvars' -no-color 2>&1)" == *'variable "assume_role_arn"'* ]]; then
  echo 'Failed to detect invalid ARN.';
  exit 1;
fi

echo 'Passed : tests/bad_arn'
