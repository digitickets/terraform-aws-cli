locals {
  script_path      = format("%s/scripts/aws_cli_exec.sh", path.module)
  credentials_path = format("%s/../../scripts/lib/aws_credentials.sh", path.module)

  # Every value is passed to the script as one JSON document in the provisioner's environment. Nothing is ever
  # interpolated into the shell command line.
  script_input = {
    commands = var.commands
    credentials = var.assume_role == null ? { mode = "ambient" } : {
      mode         = "assume_role"
      role_arn     = var.assume_role.arn
      session_name = var.assume_role.session_name
      external_id  = var.assume_role.external_id
      profile      = ""
      region       = var.region
    }
    region             = var.region
    show_output        = var.show_output
    ignore_error_codes = var.ignore_error_codes
  }
}

# Runs only when this resource is created or replaced, which happens during `terraform apply`, never during `plan` or
# `refresh`. It is replaced (and the commands rerun) only when an input, `var.triggers`, or the scripts change.
resource "terraform_data" "aws_cli_exec" {
  triggers_replace = {
    inputs             = jsonencode(local.script_input)
    triggers           = var.triggers
    script_sha256      = filesha256(local.script_path)
    credentials_sha256 = filesha256(local.credentials_path)
  }

  provisioner "local-exec" {
    command = "bash \"$TF_AWS_CLI_EXEC_SCRIPT\""
    environment = {
      TF_AWS_CLI_EXEC_SCRIPT = local.script_path
      TF_AWS_CLI_EXEC_INPUT  = jsonencode(local.script_input)
    }
  }
}
