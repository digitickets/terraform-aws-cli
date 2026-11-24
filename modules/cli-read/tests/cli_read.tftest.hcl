# Run via tests/run.sh, which puts the fake `aws` (tests/stubs/aws) first on PATH and points FAKE_AWS_LOG at
# `.fake_aws.log` in this module's directory. The fake `aws` echoes the arguments it received as {"argv": [...]}, and
# appends every invocation to that log, so these assertions can prove what was (and was not) run.
#
# cli-read uses a data source, which is read during plan, so most runs only need `command = plan`.

run "reads_at_plan_time_and_decodes_the_result" {
  command = plan

  variables {
    aws_cli_commands = ["ec2", "describe-instances", "--marker=read"]
  }

  assert {
    condition     = output.result.argv == ["ec2", "describe-instances", "--marker=read", "--output", "json"]
    error_message = "The result must be the decoded AWS CLI output."
  }

  assert {
    condition     = output.result_was_decoded
    error_message = "The result must be reported as decoded."
  }
}

run "arguments_are_passed_literally_and_never_executed" {
  command = plan

  variables {
    aws_cli_commands = [
      "ec2", "describe-instances",
      "--filters", "Name=tag:Name,Values=it's a \"quoted\" value",
      "--marker=$(touch cli-read-pwned) `touch cli-read-pwned` ; touch cli-read-pwned | * ?",
      "line one\nline two",
    ]
    aws_cli_query = "Reservations[?Tags[?Value=='it''s']] | [0]"
  }

  assert {
    condition = output.result.argv == [
      "ec2", "describe-instances",
      "--filters", "Name=tag:Name,Values=it's a \"quoted\" value",
      "--marker=$(touch cli-read-pwned) `touch cli-read-pwned` ; touch cli-read-pwned | * ?",
      "line one\nline two",
      "--query", "Reservations[?Tags[?Value=='it''s']] | [0]",
      "--output", "json",
    ]
    error_message = "Every argument, and the query, must reach the AWS CLI unchanged."
  }

  assert {
    condition     = output.result_was_decoded && !fileexists("cli-read-pwned")
    error_message = "A shell command embedded in an argument was executed."
  }
}

run "assumed_role_credentials_override_the_profile" {
  command = plan

  variables {
    aws_cli_commands  = ["ec2", "describe-instances", "--marker=assumed"]
    assume_role_arn   = "arn:aws:iam::444455556666:role/reader"
    role_session_name = "TestSession"
    external_id       = "ext-id-1"
    profile           = "source-profile"
    region            = "eu-west-1"
  }

  assert {
    condition     = output.result.argv == ["ec2", "describe-instances", "--marker=assumed", "--region", "eu-west-1", "--output", "json"]
    error_message = "Once a role is assumed, --profile must not be passed to the AWS CLI."
  }

  assert {
    condition     = output.result_was_decoded && strcontains(file(".fake_aws.log"), "{\"argv\":[\"sts\",\"assume-role\",\"--role-arn\",\"arn:aws:iam::444455556666:role/reader\",\"--role-session-name\",\"TestSession\",\"--output\",\"json\",\"--external-id\",\"ext-id-1\",\"--profile\",\"source-profile\",\"--region\",\"eu-west-1\"]")
    error_message = "The role must be assumed using the profile, external id, session name and region."
  }

  assert {
    condition     = output.result_was_decoded && strcontains(file(".fake_aws.log"), "--marker=assumed\",\"--region\",\"eu-west-1\",\"--output\",\"json\"],\"access_key_id\":\"ASIAFAKE444455556666\",\"aws_profile\":\"\"}")
    error_message = "The call must run with the assumed credentials and no profile."
  }
}

run "profile_is_used_when_no_role_is_assumed" {
  command = plan

  variables {
    aws_cli_commands = ["ec2", "describe-instances"]
    profile          = "my-profile"
  }

  assert {
    condition     = output.result.argv == ["ec2", "describe-instances", "--profile", "my-profile", "--output", "json"]
    error_message = "Without a role, the profile must be passed to the AWS CLI."
  }
}

run "aws_errors_fail_the_plan" {
  command = plan

  variables {
    aws_cli_commands = ["ec2", "describe-instances", "--fake-error=UnauthorizedOperation"]
  }

  expect_failures = [data.external.awscli_program]
}

run "aws_errors_can_be_suppressed" {
  command = plan

  variables {
    aws_cli_commands        = ["ec2", "describe-instances", "--fake-error=UnauthorizedOperation"]
    suppress_error_handling = true
  }

  assert {
    condition     = output.result.error == "aws: [ERROR]: An error occurred (UnauthorizedOperation) when calling the StubOperation operation: stub failure"
    error_message = "With error handling suppressed, the error must be returned in result.error."
  }
}

run "mutating_operations_are_rejected" {
  command = plan

  variables {
    aws_cli_commands = ["s3api", "delete-bucket", "--bucket", "example", "--marker=mutating"]
  }

  expect_failures = [var.aws_cli_commands]
}

run "commands_without_an_operation_are_rejected" {
  command = plan

  variables {
    aws_cli_commands = ["--version"]
  }

  expect_failures = [var.aws_cli_commands]
}

run "denylisted_operations_are_rejected" {
  command = plan

  variables {
    aws_cli_commands = ["secretsmanager", "get-secret-value", "--secret-id", "example", "--marker=denied"]
  }

  expect_failures = [data.external.awscli_program]
}

run "additional_denied_operations_are_rejected" {
  command = plan

  variables {
    aws_cli_commands             = ["dynamodb", "get-item", "--marker=additional-denied"]
    additional_denied_operations = { "dynamodb get-item" = "Items may contain secrets." }
  }

  expect_failures = [data.external.awscli_program]
}

run "rejected_commands_never_reach_the_aws_cli" {
  command = plan

  variables {
    aws_cli_commands = ["ec2", "describe-regions"]
  }

  assert {
    condition     = output.result_was_decoded && !strcontains(file(".fake_aws.log"), "--marker=mutating") && !strcontains(file(".fake_aws.log"), "--marker=denied") && !strcontains(file(".fake_aws.log"), "--marker=additional-denied")
    error_message = "A rejected command was passed to the AWS CLI."
  }
}

run "denylisted_operations_can_be_explicitly_allowed" {
  command = plan

  variables {
    aws_cli_commands            = ["ssm", "get-parameter-history", "--name", "example"]
    allow_denylisted_operations = { "ssm get-parameter-history" = true }
  }

  assert {
    condition     = output.result.argv[1] == "get-parameter-history"
    error_message = "An explicitly allowed operation must run."
  }
}

run "allowing_with_false_keeps_the_operation_blocked" {
  command = plan

  variables {
    aws_cli_commands            = ["ssm", "get-parameter-history", "--name", "example"]
    allow_denylisted_operations = { "ssm get-parameter-history" = false }
  }

  expect_failures = [data.external.awscli_program]
}

run "allowing_an_operation_not_on_the_denylist_is_rejected" {
  command = plan

  variables {
    aws_cli_commands            = ["ssm", "describe-parameters"]
    allow_denylisted_operations = { "ssm get-paramter-history" = true }
  }

  expect_failures = [data.external.awscli_program]
}

run "profile_debug_and_endpoint_url_are_rejected_in_commands" {
  command = plan

  variables {
    aws_cli_commands = ["ec2", "describe-instances", "--profile=other", "--debug", "--endpoint-url", "https://example.com"]
  }

  expect_failures = [var.aws_cli_commands]
}

run "alternative_path_is_deprecated" {
  command = plan

  variables {
    aws_cli_commands = ["ec2", "describe-instances"]
    alternative_path = "somewhere"
  }

  expect_failures = [check.alternative_path_is_deprecated]
}

# `check-` operations: only reviewed ones are allowed, and the rule cannot be overridden.

run "reviewed_check_operations_are_allowed" {
  command = plan

  variables {
    aws_cli_commands = ["wafv2", "check-capacity", "--scope", "REGIONAL", "--rules", "file://rules.json"]
  }

  assert {
    condition     = output.result.argv[1] == "check-capacity"
    error_message = "A reviewed check- operation must run."
  }
}

run "lightsail_subdomain_check_is_allowed_without_reserve" {
  command = plan

  variables {
    aws_cli_commands = ["lightsail", "check-subdomain-availability", "--subdomain-name", "blog", "--no-reserve"]
  }

  assert {
    condition     = output.result.argv[1] == "check-subdomain-availability"
    error_message = "lightsail check-subdomain-availability must run when it does not reserve the subdomain."
  }
}

run "lightsail_subdomain_check_with_reserve_is_rejected" {
  command = plan

  variables {
    aws_cli_commands = ["lightsail", "check-subdomain-availability", "--subdomain-name", "blog", "--reserve", "--marker=reserve"]
  }

  expect_failures = [var.aws_cli_commands]
}

run "mutating_check_in_license_is_rejected_even_when_allowed" {
  command = plan

  variables {
    aws_cli_commands            = ["license-manager", "check-in-license", "--license-consumption-token", "token", "--marker=check-in"]
    allow_denylisted_operations = { "license-manager check-in-license" = true }
  }

  expect_failures = [var.aws_cli_commands]
}

run "unreviewed_check_operations_are_rejected" {
  command = plan

  variables {
    aws_cli_commands = ["example", "check-something-new", "--marker=unreviewed-check"]
  }

  expect_failures = [var.aws_cli_commands]
}

run "operations_merely_starting_with_check_are_rejected" {
  command = plan

  variables {
    aws_cli_commands = ["license-manager", "checkout-license", "--product-sku", "sku", "--marker=checkout"]
  }

  expect_failures = [var.aws_cli_commands]
}

run "domain_transferability_check_is_denylisted" {
  command = plan

  variables {
    aws_cli_commands = ["route53domains", "check-domain-transferability", "--domain-name", "example.com", "--auth-code", "not-a-real-code", "--marker=transfer"]
  }

  expect_failures = [data.external.awscli_program]
}

run "rejected_check_operations_never_reach_the_aws_cli" {
  command = plan

  variables {
    aws_cli_commands = ["ec2", "describe-regions"]
  }

  assert {
    condition     = output.result_was_decoded && length(regexall("--marker=(reserve|check-in|unreviewed-check|checkout|transfer)", file(".fake_aws.log"))) == 0
    error_message = "A rejected check- command was passed to the AWS CLI."
  }
}

# Validation rules carried over from the original test suite.

run "invalid_role_arn_is_rejected" {
  command = plan

  variables {
    aws_cli_commands = ["ec2", "describe-instances"]
    assume_role_arn  = "arn:aws:iam::12345678901:role/too-short-account"
  }

  expect_failures = [var.assume_role_arn]
}

run "external_id_too_short_is_rejected" {
  command = plan

  variables {
    aws_cli_commands = ["ec2", "describe-instances"]
    external_id      = "a"
  }

  expect_failures = [var.external_id]
}

run "external_id_invalid_characters_are_rejected" {
  command = plan

  variables {
    aws_cli_commands = ["ec2", "describe-instances"]
    external_id      = "has spaces"
  }

  expect_failures = [var.external_id]
}

run "profile_not_starting_with_a_letter_is_rejected" {
  command = plan

  variables {
    aws_cli_commands = ["ec2", "describe-instances"]
    profile          = "1profile"
  }

  expect_failures = [var.profile]
}

run "invalid_region_is_rejected" {
  command = plan

  variables {
    aws_cli_commands = ["ec2", "describe-instances"]
    region           = "EU-West-1"
  }

  expect_failures = [var.region]
}

run "role_session_name_too_long_is_rejected" {
  command = plan

  variables {
    aws_cli_commands  = ["ec2", "describe-instances"]
    role_session_name = "a123456789012345678901234567890123456789012345678901234567890123456789"
  }

  expect_failures = [var.role_session_name]
}

run "invalid_retries_mode_is_rejected" {
  command = plan

  variables {
    aws_cli_commands = ["ec2", "describe-instances"]
    retries          = { mode = "sometimes" }
  }

  expect_failures = [var.retries]
}

run "empty_command_is_rejected" {
  command = plan

  variables {
    aws_cli_commands = [""]
  }

  expect_failures = [var.aws_cli_commands]
}
