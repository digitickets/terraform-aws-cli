#!/usr/bin/env sh

# Validate required commands
if [ ! -x "$(command -v aws)" ]; then
  echo '{"error":"aws cli is not installed"}'
  exit 1
fi
if [ ! -x "$(command -v jq)" ]; then
  echo '{"error":"jq is not installed"}'
  exit 2
fi

# Validate required results file as the first argument
if [ -z "${1}" ]; then
  echo '{"error":"No results filename supplied"}'
  exit 3
fi

# Extract directory from results file name for all logs.
RESULTS_FILE="${1}"
ROOT_DIRECTORY=$(dirname "${RESULTS_FILE}")

# Build all the paths for all the files.
## JQ json and error log
JQ_JSON="${ROOT_DIRECTORY}/jq_data.json"
JQ_ERROR_LOG="${ROOT_DIRECTORY}/jq_error.log"

## AWS STS json and error log
AWS_STS_JSON="${ROOT_DIRECTORY}/aws_sts.json"
AWS_STS_ERROR_LOG="${ROOT_DIRECTORY}/aws_sts_error.log"

## The actual AWS call json and error log
AWS_CALL_JSON="${ROOT_DIRECTORY}/aws_call.json"
AWS_CALL_ERROR_LOG="${ROOT_DIRECTORY}/aws_call_error.log"

# Remove any files that would match the above list
mkdir -p "${ROOT_DIRECTORY}"
rm -rf \
  "${JQ_JSON}" \
  "${JQ_ERROR_LOG}" \
  "${AWS_STS_JSON}" \
  "${AWS_STS_ERROR_LOG}" \
  "${AWS_CALL_JSON}" \
  "${AWS_CALL_ERROR_LOG}" \
  "${RESULTS_FILE}" \

# Get the query and store it
jq -Mcr . >"${JQ_JSON}" 2>"${JQ_ERROR_LOG}"

# Extract the query attributes
AWS_CLI_COMMANDS=$( jq -r '.aws_cli_commands'  "${JQ_JSON}" 2>>"${JQ_ERROR_LOG}")
AWS_CLI_QUERY=$(    jq -r '.aws_cli_query'     "${JQ_JSON}" 2>>"${JQ_ERROR_LOG}")
ASSUME_ROLE_ARN=$(  jq -r '.assume_role_arn'   "${JQ_JSON}" 2>>"${JQ_ERROR_LOG}")
ROLE_SESSION_NAME=$(jq -r '.role_session_name' "${JQ_JSON}" 2>>"${JQ_ERROR_LOG}")
EXTERNAL_ID=$(      jq -r '.external_id'       "${JQ_JSON}" 2>>"${JQ_ERROR_LOG}")
PROFILE_NAME=$(     jq -r '.profile'           "${JQ_JSON}" 2>>"${JQ_ERROR_LOG}")
REGION_NAME=$(      jq -r '.region'            "${JQ_JSON}" 2>>"${JQ_ERROR_LOG}")
KEEP_LOGS=$(        jq -r '.keep_logs'         "${JQ_JSON}" 2>>"${JQ_ERROR_LOG}")

# Build the required parameters for the AWS calls.

## Do we have a profile?
if [ -n "${PROFILE_NAME}" ]; then
  AWS_CLI_PROFILE_PARAM="--profile=${PROFILE_NAME}"
fi

## Do we have a region?
if [ -n "${REGION_NAME}" ]; then
  AWS_CLI_REGION_PARAM="--region=${REGION_NAME}"
fi

## Do we need to assume a role?
if [ -n "${ASSUME_ROLE_ARN}" ]; then

  ### Do we have an external ID?
  if [ -n "${EXTERNAL_ID}" ]; then
    AWS_CLI_EXTERNAL_ID_PARAM="--external-id=${EXTERNAL_ID}"
  fi

  ### Get temporary credentials from AWS STS
  if ! eval "aws sts assume-role \
    --role-arn ${ASSUME_ROLE_ARN} \
    ${AWS_CLI_EXTERNAL_ID_PARAM:-} \
    --role-session-name ${ROLE_SESSION_NAME:-AssumingRole} \
    --output json \
    --debug \
    ${AWS_CLI_PROFILE_PARAM:-} \
    ${AWS_CLI_REGION_PARAM:-} \
    " \
    >"${AWS_STS_JSON}" \
    2>"${AWS_STS_ERROR_LOG}"; then
      echo '{"error":"The call to AWS to get temporary credentials failed"}' >&2
      exit 4
    fi
  export AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' "$AWS_STS_JSON")
  export AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' "$AWS_STS_JSON")
  export AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' "$AWS_STS_JSON")

  ### Having assumed a role, drop the profile as that will override any credentials retrieved by the assumed role when
  ### reused as part of the AWS CLI call.
  ### References :
  ### 1. https://github.com/digitickets/terraform-aws-cli/issues/11 - Thank you Garrett Blinkhorn.
  ### 2. https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_use-resources.html#using-temp-creds-sdk-cli
  unset AWS_CLI_PROFILE_PARAM
fi

# Do we have a query?
if [ -n "${AWS_CLI_QUERY}" ]; then
  AWS_CLI_QUERY_PARAM="--query='${AWS_CLI_QUERY}'"
fi

# Disable any assigned pager
export AWS_PAGER=""

# Configure adaptive retry mode
export AWS_RETRY_MODE=adaptive

# Run the AWS_CLI command
AWS_COMMAND_LINE=""
if ! eval "aws \
  ${AWS_CLI_COMMANDS} \
  ${AWS_CLI_PROFILE_PARAM:-} \
  ${AWS_CLI_REGION_PARAM:-} \
  ${AWS_CLI_QUERY_PARAM:-} \
  --output json \
  " \
  >"${AWS_CALL_JSON}" \
  2> "${AWS_CALL_ERROR_LOG}"; then
  # Convert the error into a JSON string and exit
  jq -MRcs '{"error":gsub("^\n+|\n+$"; "")}' "${AWS_CALL_ERROR_LOG}" > "${RESULTS_FILE}"
  cat "${RESULTS_FILE}"
  exit 0
fi

# All is good.
cp "${AWS_CALL_JSON}" "${RESULTS_FILE}"
echo '{"result":"'"${RESULTS_FILE}"'"}'

# Clean up, but allow a test mode to retain all files except the result
if [ "${MODULE_TERRAFORM_AWS_CLI_RETAIN_LOGS}" != "true" ]; then
  rm -rf \
    "${JQ_JSON}" \
    "${JQ_ERROR_LOG}" \
    "${AWS_STS_JSON}" \
    "${AWS_STS_ERROR_LOG}" \
    "${AWS_CALL_JSON}" \
    "${AWS_CALL_ERROR_LOG}"
fi
