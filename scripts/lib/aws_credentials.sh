# shellcheck shell=bash
# Shared credential acquisition for the cli-read and cli-exec scripts. This file is sourced, never executed.
#
# Guarantees:
#   - Credentials are only ever held in shell variables and the environment of this process (and therefore the `aws`
#     child processes it starts). They are never written to disk, printed, or logged.
#   - `aws sts` is never run with `--debug` (botocore logs raw response bodies, which would include the credentials).
#   - Must remain compatible with bash 3.2 (macOS).
#
# The credential specification is a JSON object built by Terraform, selected by its `mode`:
#   {"mode": "ambient"}
#       Use whatever credentials the calling environment already provides.
#   {"mode": "assume_role", "role_arn": "...", "session_name": "...", "external_id": "...", "profile": "...",
#    "region": "..."}
#       Assume the role (using `profile`, if supplied, as the source identity) and export the temporary credentials.
#
# New modes can be added as new `case` branches without changing the existing ones.

# aws_credentials_acquire <credentials-json> <private-work-directory>
aws_credentials_acquire() {
  local spec="$1"
  local work_dir="$2"
  local mode

  mode=$(printf '%s' "${spec}" | jq -r '.mode // "ambient"') || return 1
  case "${mode}" in
    ambient)
      return 0
      ;;
    assume_role)
      _aws_credentials_assume_role "${spec}" "${work_dir}"
      ;;
    *)
      printf 'Unsupported credentials mode: %s\n' "${mode}" >&2
      return 1
      ;;
  esac
}

_aws_credentials_field() {
  printf '%s' "$1" | jq -r --arg key "$2" '.[$key] // "" | tostring'
}

_aws_credentials_assume_role() {
  local spec="$1"
  local work_dir="$2"
  local role_arn session_name external_id profile region sts_json
  local -a sts_args

  role_arn=$(_aws_credentials_field "${spec}" role_arn)
  session_name=$(_aws_credentials_field "${spec}" session_name)
  external_id=$(_aws_credentials_field "${spec}" external_id)
  profile=$(_aws_credentials_field "${spec}" profile)
  region=$(_aws_credentials_field "${spec}" region)

  if [ -z "${role_arn}" ]; then
    printf 'Credentials mode assume_role requires a role_arn\n' >&2
    return 1
  fi

  sts_args=(sts assume-role --role-arn "${role_arn}" --role-session-name "${session_name:-AssumingRole}" --output json)
  if [ -n "${external_id}" ]; then
    sts_args+=(--external-id "${external_id}")
  fi
  if [ -n "${profile}" ]; then
    sts_args+=(--profile "${profile}")
  fi
  if [ -n "${region}" ]; then
    sts_args+=(--region "${region}")
  fi

  # Only stderr goes to the (private, temporary) work directory. Without --debug it holds the error message only.
  if ! sts_json=$(AWS_PAGER="" aws "${sts_args[@]}" 2>"${work_dir}/sts_error.log"); then
    printf 'The call to AWS to assume role %s failed: %s\n' "${role_arn}" "$(cat "${work_dir}/sts_error.log")" >&2
    return 1
  fi

  if ! AWS_ACCESS_KEY_ID=$(printf '%s' "${sts_json}" | jq -er '.Credentials.AccessKeyId') ||
    ! AWS_SECRET_ACCESS_KEY=$(printf '%s' "${sts_json}" | jq -er '.Credentials.SecretAccessKey') ||
    ! AWS_SESSION_TOKEN=$(printf '%s' "${sts_json}" | jq -er '.Credentials.SessionToken'); then
    unset sts_json
    printf 'The response from AWS when assuming role %s did not contain credentials\n' "${role_arn}" >&2
    return 1
  fi
  unset sts_json
  export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

  # Credentials in the environment take precedence over an inherited AWS_PROFILE, but an explicit `--profile` would
  # override them (see https://github.com/digitickets/terraform-aws-cli/issues/11). Callers must never pass `--profile`
  # once a role is assumed; the inherited profile variables are removed too, so no other identity can be selected.
  unset AWS_PROFILE AWS_DEFAULT_PROFILE
}
