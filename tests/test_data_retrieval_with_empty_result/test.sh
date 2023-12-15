#!/usr/bin/env bash

function test_setup() {
  if [ -f .env ]; then
    . .env
    export ALLOW_APPLY=true

    EXISTING_DETECTOR_ID=$(aws guardduty list-detectors --query='DetectorIds[0]' | jq -cr .)

    if [ "${EXISTING_DETECTOR_ID}" == "null" ]; then
      DETECTOR_ID=$(aws guardduty create-detector --enable --output json | jq -r '.DetectorId')
      echo "Created detector : ${DETECTOR_ID}" | indent
    else
      DETECTOR_ID=${EXISTING_DETECTOR_ID}
      echo "Reusing detector : ${DETECTOR_ID}" | indent
    fi

    sed -i.bak 's/"--detector-id=.*"/"--detector-id='${DETECTOR_ID}'"/' $(dirname $0)/terraform.tfvars
    sed -i.bak 's/"--detector-id=.*"/"--detector-id='${DETECTOR_ID}'"/' $(dirname $0)/expected_variables.json
    rm -rf $(dirname $0)/terraform.tfvars.bak
    rm -rf $(dirname $0)/expected_variables.json.bak

  else
    export ALLOW_PLAN=false
    export ALLOW_APPLY=false
    echo 'Test skipped as AWS credentials are required in the .env file.' | indent
  fi
}

function test_teardown() {
  if [ -f .env ]; then
    aws guardduty delete-detector --detector-id $DETECTOR_ID
    echo "Deleted detector : ${DETECTOR_ID}" | indent

    DETECTOR_ID=01234567890123456789012345678901
    sed -i.bak 's/"--detector-id=.*"/"--detector-id='${DETECTOR_ID}'"/' $(dirname $0)/terraform.tfvars
    sed -i.bak 's/"--detector-id=.*"/"--detector-id='${DETECTOR_ID}'"/' $(dirname $0)/expected_variables.json
    rm -rf $(dirname $0)/terraform.tfvars.bak
    rm -rf $(dirname $0)/expected_variables.json.bak
  fi
}

. tests/common.sh $0
