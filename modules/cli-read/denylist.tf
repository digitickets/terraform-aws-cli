# Read-style operations that are blocked by default because their results would be stored in Terraform state and shown
# in plan output. Each entry explains why, and names the equivalent AWS provider block where one exists.
#
# A consumer can unblock an entry, accepting the risk explicitly, with:
#   allow_denylisted_operations = { "<service> <operation>" = true }
locals {
  secret_in_state         = "it returns secret values, which would be stored in Terraform state and shown in plan output."
  credentials_in_state    = "it returns credentials, which would be stored in Terraform state and shown in plan output."
  no_provider_equivalent  = "There is no equivalent AWS provider data source."
  use_provider_assumption = "There is no equivalent data source; configure the identity on the provider instead, with `provider \"aws\" { assume_role { ... } }` or a profile."

  default_denied_operations = {
    "secretsmanager get-secret-value"               = "${local.secret_in_state} Use `ephemeral \"aws_secretsmanager_secret_version\"` (Terraform >= 1.10, keeps the value out of state) or `data \"aws_secretsmanager_secret_version\"`."
    "secretsmanager batch-get-secret-value"         = "${local.secret_in_state} Use `ephemeral \"aws_secretsmanager_secret_version\"` (Terraform >= 1.10, keeps the value out of state) or `data \"aws_secretsmanager_secret_version\"`, once per secret."
    "ssm get-parameter"                             = "${local.secret_in_state} Use `ephemeral \"aws_ssm_parameter\"` (Terraform >= 1.10, keeps the value out of state) or `data \"aws_ssm_parameter\"`."
    "ssm get-parameters"                            = "${local.secret_in_state} Use `ephemeral \"aws_ssm_parameter\"` (Terraform >= 1.10, keeps the value out of state) or `data \"aws_ssm_parameter\"`, once per parameter."
    "ssm get-parameters-by-path"                    = "${local.secret_in_state} Use `data \"aws_ssm_parameters_by_path\"`."
    "ssm get-parameter-history"                     = "it returns current and previous parameter values, which would be stored in Terraform state and shown in plan output. ${local.no_provider_equivalent}"
    "ecr get-login-password"                        = "${local.credentials_in_state} Use `ephemeral \"aws_ecr_authorization_token\"` (Terraform >= 1.10, keeps the value out of state) or `data \"aws_ecr_authorization_token\"`."
    "ecr get-authorization-token"                   = "${local.credentials_in_state} Use `ephemeral \"aws_ecr_authorization_token\"` (Terraform >= 1.10, keeps the value out of state) or `data \"aws_ecr_authorization_token\"`."
    "codeartifact get-authorization-token"          = "${local.credentials_in_state} Use `data \"aws_codeartifact_authorization_token\"`."
    "ec2 get-password-data"                         = "${local.secret_in_state} Use `get_password_data = true` on `resource \"aws_instance\"` or `data \"aws_instance\"` (the `password_data` attribute)."
    "lambda get-function"                           = "it returns the function's environment variables and a pre-signed code download URL, which would be stored in Terraform state and shown in plan output. Use `data \"aws_lambda_function\"`."
    "lambda get-function-configuration"             = "it returns the function's environment variables, which would be stored in Terraform state and shown in plan output. Use `data \"aws_lambda_function\"`."
    "redshift get-cluster-credentials"              = "${local.credentials_in_state} Use `data \"aws_redshift_cluster_credentials\"`."
    "redshift-serverless get-credentials"           = "${local.credentials_in_state} Use `data \"aws_redshiftserverless_credentials\"`."
    "s3api get-object"                              = "it writes the object to a local file and the object may contain secrets. Use `data \"aws_s3_object\"` (the `body` or `body_base64` attribute)."
    "apigateway get-api-key"                        = "${local.secret_in_state} Use `data \"aws_api_gateway_api_key\"`."
    "apigateway get-api-keys"                       = "${local.secret_in_state} Use `data \"aws_api_gateway_api_keys\"` (with `include_values`)."
    "sts get-session-token"                         = "${local.credentials_in_state} ${local.use_provider_assumption}"
    "sts get-federation-token"                      = "${local.credentials_in_state} ${local.use_provider_assumption}"
    "sso get-role-credentials"                      = "${local.credentials_in_state} ${local.use_provider_assumption}"
    "cognito-identity get-credentials-for-identity" = "${local.credentials_in_state} ${local.no_provider_equivalent}"
    "cognito-identity get-open-id-token"            = "it returns an identity token, which would be stored in Terraform state and shown in plan output. ${local.no_provider_equivalent}"
    "iam get-credential-report"                     = "it returns the credential status of every IAM user (password and access key ages, MFA state), which would be stored in Terraform state and shown in plan output. ${local.no_provider_equivalent}"
  }

  denied_operations = merge(local.default_denied_operations, var.additional_denied_operations)

  # "<service> <operation>", as used for the denylist keys.
  operation = format("%s %s", try(var.aws_cli_commands[0], ""), try(var.aws_cli_commands[1], ""))

  operation_is_denied = contains(keys(local.denied_operations), local.operation) && !lookup(var.allow_denylisted_operations, local.operation, false)

  unknown_allowed_operations = [for operation in keys(var.allow_denylisted_operations) : operation if !contains(keys(local.denied_operations), operation)]
}
