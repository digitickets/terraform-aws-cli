#!/usr/bin/env bash

function underline() {
  U="${1//?/${2:--}}"
  echo -e "\n$1\n${U:0:${#1}}\n"
}

function indent() {
  if [ ! -z "$1" ]; then
    echo "$1" | sed 's/^/          /'
  else
    cat - | sed 's/^/          /'
  fi
}

function validate_init() {
  if [ ! -f "${TERRAFORM_INIT_LOG}" ]; then
    echo "FAILED : ${TERRAFORM_INIT_LOG} failed to be created"
    echo ''
    exit 11;
  fi

  if [ -s "${TERRAFORM_INIT_ERROR_LOG}" ]; then
    echo "FAILED : ${TERRAFORM_INIT_ERROR_LOG} is not empty"
    echo ""
    cat ${TERRAFORM_INIT_ERROR_LOG} | indent
    echo ''
    exit 12;
  fi
}

function validate_plan() {
  jq -r '
    .variables |
    walk(
      if type == "object" and has("value") then
        .value
      else
        .
      end
    )
    ' "${TERRAFORM_PLAN_SHOW_JSON}" > "${TERRAFORM_PLAN_SHOW_EXTRACTED_VARIABLES_JSON}"

  if [ -f "${EXPECTED_VARIABLES}" ]; then
    DIFFERENCE_IN_EXPECTED_VARIABLES=$(diff -U 3 -W 120 --suppress-common-lines "${EXPECTED_VARIABLES}" "${TERRAFORM_PLAN_SHOW_EXTRACTED_VARIABLES_JSON}")
    if [ ! -z "${DIFFERENCE_IN_EXPECTED_VARIABLES}" ]; then
      echo 'FAILED : Difference in expected variables'
      echo "${DIFFERENCE_IN_EXPECTED_VARIABLES}" | indent
      echo ''
      exit 21
    else
      echo 'Variables processed successfully' | indent
    fi
  fi

  jq -r '
    [
      .checks[] |
      select(.status == "fail") |
      {
        variable: .address.to_display,
        problems: .instances[].problems[].message
      }
    ] |
    group_by(.variable) |
    map(
      {
      variable: .[0].variable,
      problems: map(.problems)
      }
    ) |
    select(length > 0)
    ' "${TERRAFORM_PLAN_SHOW_JSON}" > "${TERRAFORM_PLAN_SHOW_EXTRACTED_ERRORS_JSON}"

  if [ -f "${EXPECTED_ERRORS}" ]; then
    DIFFERENCE_IN_EXPECTED_ERRORS=$(diff -U 3 -W 120 --suppress-common-lines "${EXPECTED_ERRORS}" "${TERRAFORM_PLAN_SHOW_EXTRACTED_ERRORS_JSON}")
    if [ ! -z "${DIFFERENCE_IN_EXPECTED_ERRORS}" ]; then
      echo 'FAILED : Difference in expected errors'
      echo "${DIFFERENCE_IN_EXPECTED_ERRORS}" | indent
      echo ''
      exit 22
    else
      echo 'Expected errors generated successfully' | indent
    fi
  else
    if [ -s "${TERRAFORM_PLAN_SHOW_EXTRACTED_ERRORS_JSON}" ]; then
      echo 'FAILED : Generated unexpected errors'
      cat "${TERRAFORM_PLAN_SHOW_EXTRACTED_ERRORS_JSON}" | indent
      echo ''
      exit 23
    else
      echo 'No unexpected errors generated' | indent
    fi
  fi
}

function validate_apply() {
  jq -r '
    .values.outputs |
    walk(
      if type == "object" and has("value") then
        .value
      else
        .
      end
    )
    ' "${TERRAFORM_APPLY_SHOW_JSON}" > "${TERRAFORM_APPLY_SHOW_EXTRACTED_OUTPUTS_JSON}"

    if [ -f "${EXPECTED_OUTPUTS}" ]; then
    DIFFERENCE_IN_EXPECTED_OUTPUTS=$(diff -U 3 -W 120 --suppress-common-lines "${EXPECTED_OUTPUTS}" "${TERRAFORM_APPLY_SHOW_EXTRACTED_OUTPUTS_JSON}")
    if [ ! -z "${DIFFERENCE_IN_EXPECTED_OUTPUTS}" ]; then
      echo 'FAILED : Difference in expected outputs'
      echo "${DIFFERENCE_IN_EXPECTED_OUTPUTS}" | indent
      echo ''
      exit 31
    else
      echo 'Expected outputs generated successfully' | indent
    fi
  else
    if [ -s "${TERRAFORM_APPLY_SHOW_EXTRACTED_OUTPUTS_JSON}" ]; then
      echo 'FAILED : Generated unexpected outputs'
      cat "${TERRAFORM_APPLY_SHOW_EXTRACTED_OUTPUTS_JSON}" | indent
      echo ''
      exit 32
    else
      echo 'No unexpected outputs generated' | indent
    fi
  fi
}

function run_function() {
  function_name="${1:-true}"

  if type -t "$function_name" > /dev/null; then
      echo "Running : $function_name" | indent
      "$function_name"
  fi
}

function common_setup() {
  TEST_PATH=$(dirname "${1}")
  TEST_NAME=$(basename "${TEST_PATH}")

  echo "Start   : ${TEST_PATH}"

  TERRAFORM_TFVARS="${TEST_PATH}/terraform.tfvars"
  EXPECTED_VARIABLES="${TEST_PATH}/expected_variables.json"
  EXPECTED_ERRORS="${TEST_PATH}/expected_plan_errors.json"
  EXPECTED_OUTPUTS="${TEST_PATH}/expected_apply_outputs.json"

  ROOT_DIRECTORY="test-reports/${TEST_NAME}/terraform"
  mkdir -p "${ROOT_DIRECTORY}"

  ## Terraform init output, errors, and trace
  TERRAFORM_INIT_LOG="${ROOT_DIRECTORY}/init.log"
  TERRAFORM_INIT_ERROR_LOG="${ROOT_DIRECTORY}/init_error.log"
  TERRAFORM_INIT_TRACE_LOG="${ROOT_DIRECTORY}/init_trace.log"

  ## Terraform plan output, errors, and trace
  TERRAFORM_PLAN="${ROOT_DIRECTORY}/terraform.plan"
  TERRAFORM_PLAN_LOG="${ROOT_DIRECTORY}/plan.log"
  TERRAFORM_PLAN_ERROR_LOG="${ROOT_DIRECTORY}/plan_error.log"
  TERRAFORM_PLAN_TRACE_LOG="${ROOT_DIRECTORY}/plan_trace.log"

  ## Terraform show json, errors, and trace from plan
  TERRAFORM_PLAN_SHOW_JSON="${ROOT_DIRECTORY}/plan_show.json"
  TERRAFORM_PLAN_SHOW_ERROR_LOG="${ROOT_DIRECTORY}/plan_show_error.log"
  TERRAFORM_PLAN_SHOW_TRACE_LOG="${ROOT_DIRECTORY}/plan_show_trace.log"

  ## Extracted data
  TERRAFORM_PLAN_SHOW_EXTRACTED_VARIABLES_JSON="${ROOT_DIRECTORY}/plan_show_extracted_variables.json"
  TERRAFORM_PLAN_SHOW_EXTRACTED_ERRORS_JSON="${ROOT_DIRECTORY}/plan_show_extracted_errors.json"
  TERRAFORM_APPLY_SHOW_EXTRACTED_OUTPUTS_JSON="${ROOT_DIRECTORY}/apply_show_extracted_outputs.json"

  ## Terraform apply output, errors, and trace
  TERRAFORM_APPLY_STATE_FILE="${ROOT_DIRECTORY}/terraform.state"
  TERRAFORM_APPLY_LOG="${ROOT_DIRECTORY}/apply.log"
  TERRAFORM_APPLY_ERROR_LOG="${ROOT_DIRECTORY}/apply_error.log"
  TERRAFORM_APPLY_TRACE_LOG="${ROOT_DIRECTORY}/apply_trace.log"

  ## Terraform show json, errors, and trace from apply
  TERRAFORM_APPLY_SHOW_JSON="${ROOT_DIRECTORY}/apply_show.json"
  TERRAFORM_APPLY_SHOW_ERROR_LOG="${ROOT_DIRECTORY}/apply_show_error.log"
  TERRAFORM_APPLY_SHOW_TRACE_LOG="${ROOT_DIRECTORY}/apply_show_trace.log"

  # Some tests may not be able to be run
  export ALLOW_PLAN=true

  # Tell the AWS Script to hold onto all the log files
  export MODULE_TERRAFORM_AWS_CLI_RETAIN_LOGS=true
}

function run_test() {
  if [ "${ALLOW_PLAN}" == "true" ]; then
    # Turn off coloured Terraform output (makes logs a little easier to read in an IDE)
    export TF_CLI_ARGS="-no-color"

    # Enable full trace mode when running Terraform
    export TF_LOG=TRACE

    # Initialise Terraform.
    TF_LOG_PATH="${TERRAFORM_INIT_TRACE_LOG}" \
      terraform init \
      >"${TERRAFORM_INIT_LOG}" \
      2> "${TERRAFORM_INIT_ERROR_LOG}"
    validate_init

    TF_LOG_PATH="${TERRAFORM_PLAN_TRACE_LOG}" \
      terraform plan \
      -var-file=${TERRAFORM_TFVARS} \
      -out=${TERRAFORM_PLAN} \
      >"${TERRAFORM_PLAN_LOG}" \
      2> "${TERRAFORM_PLAN_ERROR_LOG}"

    TF_LOG_PATH="${TERRAFORM_PLAN_SHOW_TRACE_LOG}" \
      terraform show \
      -json \
      "${TERRAFORM_PLAN}" \
      >"${TERRAFORM_PLAN_SHOW_JSON}"
    validate_plan

    if [ "${ALLOW_APPLY}" == "true" ]; then
      TF_LOG_PATH="${TERRAFORM_APPLY_TRACE_LOG}" \
        terraform apply \
          -auto-approve \
          -backup=- \
          -state-out "${TERRAFORM_APPLY_STATE_FILE}" \
          "${TERRAFORM_PLAN}" \
          > "${TERRAFORM_APPLY_LOG}" \
          2> "${TERRAFORM_APPLY_ERROR_LOG}"

      TF_LOG_PATH="${TERRAFORM_APPLY_SHOW_TRACE_LOG}" \
        terraform show \
          -json \
          "${TERRAFORM_APPLY_STATE_FILE}" \
          >"${TERRAFORM_APPLY_SHOW_JSON}" \
          2>"${TERRAFORM_APPLY_SHOW_ERROR_LOG}"

      validate_apply
    fi

    run_function test_teardown

    echo "Passed  : $TEST_PATH"
  else
    echo "Skipped : $TEST_PATH"
  fi

  echo ''
}

# Prepare everything for running the test that is common to all tests
common_setup "${1}"

# Prepare anything specific to the actual test (optional function in the tests test.sh script)
run_function test_setup

# Run the test! This will also, if required, run the optional test_teardown function if that exists.
run_test
