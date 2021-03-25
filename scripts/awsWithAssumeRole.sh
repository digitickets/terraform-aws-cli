#!/usr/bin/env sh

# Validate required commands
if ! [ -x "$(command -v aws)" ]; then
  echo 'Error: aws is not installed.' >&2
  exit 1
fi
if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed.' >&2
  exit 1
fi

# Get the query
TERRAFORM_QUERY=$(jq -Mc .)

# Extract the query attributes
AWS_CLI_COMMANDS=$(echo "${TERRAFORM_QUERY}" | jq -r '.aws_cli_commands')
AWS_CLI_QUERY=$(echo "${TERRAFORM_QUERY}" | jq -r '.aws_cli_query')
OUTPUT_FILE=$(echo "${TERRAFORM_QUERY}" | jq -r '.output_file')
ASSUME_ROLE_ARN=$(echo "${TERRAFORM_QUERY}" | jq -r '.assume_role_arn')
ROLE_SESSION_NAME=$(echo "${TERRAFORM_QUERY}" | jq -r '.role_session_name')
DEBUG_LOG_FILENAME=$(echo "${TERRAFORM_QUERY}" | jq -r '.debug_log_filename')

# Do we need to assume a role?
if [ -n "${ASSUME_ROLE_ARN}" ]; then
  TEMP_ROLE=$(aws sts assume-role --role-arn "${ASSUME_ROLE_ARN}" --role-session-name "${ROLE_SESSION_NAME:-AssumingRole}")
  export AWS_ACCESS_KEY_ID=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.AccessKeyId')
  export AWS_SECRET_ACCESS_KEY=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.SecretAccessKey')
  export AWS_SESSION_TOKEN=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.SessionToken')
fi

# Do we have a query?
if [ -n "${AWS_CLI_QUERY}" ]; then
  AWS_CLI_QUERY_PARAM="--query '${AWS_CLI_QUERY}'"
fi

# Do we want to be debug?
export AWS_DEBUG_OPTION=""
if [ -n "${DEBUG_LOG_FILENAME}" ]; then
  AWS_DEBUG_OPTION="--debug 2>${DEBUG_LOG_FILENAME}"
  mkdir -p "$(dirname ${DEBUG_LOG_FILENAME})"
fi

# Disable any assigned pager
export AWS_PAGER=""

# Configure adaptive retry mode
export AWS_RETRY_MODE=adaptive

# Run the AWS_CLI command, exiting with a non zero exit code if required.
if ! eval "aws ${AWS_CLI_COMMANDS} ${AWS_CLI_QUERY_PARAM:-} --output json ${AWS_DEBUG_OPTION}" >"${OUTPUT_FILE}" ; then
  echo "Error: aws failed."
  exit 1
fi

# All is good.
echo '{"output_file":"'"${OUTPUT_FILE}"'"}'
