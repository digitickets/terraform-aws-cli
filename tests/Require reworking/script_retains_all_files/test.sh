#!/usr/bin/env bash

export ALLOW_APPLY=true

function test_teardown() {
  ROOT_DIRECTORY="test-reports/${TEST_NAME}/aws"

  # Build all the paths for all the files.

  ## Results file
  RESULTS_FILE="${ROOT_DIRECTORY}/results.json"

  ## JQ json and error log
  JQ_JSON="${ROOT_DIRECTORY}/jq_data.json"
  JQ_ERROR_LOG="${ROOT_DIRECTORY}/jq_error.log"

  ## AWS STS json and error log
  AWS_STS_JSON="${ROOT_DIRECTORY}/aws_sts.json"
  AWS_STS_ERROR_LOG="${ROOT_DIRECTORY}/aws_sts_error.log"

  ## The actual AWS call json and error log
  AWS_CALL_JSON="${ROOT_DIRECTORY}/aws_call.json"
  AWS_CALL_ERROR_LOG="${ROOT_DIRECTORY}/aws_call_error.log"

  # Not all the files are created as the test does not generate these errors
  AWS_SCRIPT_FILENAMES=(
    "${JQ_JSON}" "${JQ_ERROR_LOG}"
    "${AWS_STS_JSON}" "${AWS_STS_ERROR_LOG}"
    "${AWS_CALL_JSON}" "${AWS_CALL_ERROR_LOG}"
  )

  TEST_PASSED=true
  for AWS_SCRIPT_FILENAME in "${AWS_SCRIPT_FILENAMES[@]}"; do
    if [[ ! -f "${AWS_SCRIPT_FILENAME}" ]]; then
      echo "Failed to retain '${AWS_SCRIPT_FILENAME}'" | indent
      TEST_PASSED=false
    fi
  done

  if [ ! -f "${RESULTS_FILE}" ]; then
    echo "Failed to retain '${RESULTS_FILE}'" | indent
    TEST_PASSED=false
  fi

  if [ "${TEST_PASSED}" != "true" ]; then
    exit 1;
  fi
}

. tests/common.sh $0
