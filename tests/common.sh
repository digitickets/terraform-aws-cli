#!/usr/bin/env bash

TEST_PATH=$(dirname $1)
TEST_NAME=$(basename $TEST_PATH)

echo "Start  : $TEST_PATH"

TERRAFORM_TFVARS=$TEST_PATH/terraform.tfvars
EXPECTED_VARIABLES=$TEST_PATH/expected_variables.json

RESOURCE_PATH=test-reports/$TEST_NAME
mkdir -p $RESOURCE_PATH

INIT_LOG_FILE=$RESOURCE_PATH/init.log
INIT_ERROR_FILE=$RESOURCE_PATH/init.error.log
PLAN_FILE=$RESOURCE_PATH/terraform.plan
PLAN_LOG_FILE=$RESOURCE_PATH/plan.log
PLAN_ERROR_FILE=$RESOURCE_PATH/plan.error.log
STATE_FILE=$RESOURCE_PATH/terraform.tfstate
APPLY_LOG_FILE=$RESOURCE_PATH/apply.log
APPLY_ERROR_FILE=$RESOURCE_PATH/apply.error.log
DEBUG_LOG_FILE=$RESOURCE_PATH/debug.log

terraform init > $INIT_LOG_FILE 2> $INIT_ERROR_FILE

terraform plan -var-file=$TERRAFORM_TFVARS -out=$PLAN_FILE > $PLAN_LOG_FILE 2> $PLAN_ERROR_FILE

run_test

echo "Passed : $TEST_PATH"
