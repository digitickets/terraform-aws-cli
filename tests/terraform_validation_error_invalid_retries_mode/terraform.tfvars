aws_cli_commands = ["version"]
retries = {
  max_attempts = 3
  mode         = "invalid_mode"
}

alternative_path = "test-reports/terraform_validation_error_invalid_retries_mode/aws"
