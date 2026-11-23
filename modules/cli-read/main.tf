locals {
  # Every value is passed to the script as one JSON document. Nothing is ever interpolated into a shell command line.
  script_input = {
    credentials = length(var.assume_role_arn) == 0 ? { mode = "ambient" } : {
      mode         = "assume_role"
      role_arn     = var.assume_role_arn
      session_name = var.role_session_name
      external_id  = var.external_id
      profile      = var.profile
      region       = var.region
    }
    aws_cli_commands     = var.aws_cli_commands
    aws_cli_query        = var.aws_cli_query
    external_id          = var.external_id
    profile              = var.profile
    region               = var.region
    retries_max_attempts = tostring(var.retries.max_attempts)
    retries_mode         = var.retries.mode
  }
}

# The `external` provider only accepts a flat map of strings as a result, so the script returns the raw AWS CLI output
# as a single string, which is JSON decoded here. This preserves all the data types returned from AWS without writing
# a results file to disk.
data "external" "awscli_program" {
  program = ["bash", format("%s/scripts/aws_cli_runner.sh", path.module)]
  query = {
    input = jsonencode(local.script_input)
  }

  lifecycle {
    postcondition {
      condition     = var.suppress_error_handling ? true : (try(jsondecode(self.result.content).error, false) == false)
      error_message = try(jsondecode(self.result.content).error, "Unknown error")
    }
  }
}

locals {
  content = data.external.awscli_program.result.content
}

check "alternative_path_is_deprecated" {
  assert {
    condition     = var.alternative_path == ""
    error_message = "`var.alternative_path` is deprecated and ignored. No results file is written to disk any more."
  }
}
