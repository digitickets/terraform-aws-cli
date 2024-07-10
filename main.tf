locals {
  joined_aws_cli_command = join(" ", var.aws_cli_commands)
  external_program_query = {
    assume_role_arn   = var.assume_role_arn
    role_session_name = length(var.assume_role_arn) > 0 ? var.role_session_name : ""
    aws_cli_commands  = local.joined_aws_cli_command
    aws_cli_query     = var.aws_cli_query
    external_id       = var.external_id
    profile           = var.profile
    region            = var.region
  }
  standard_results_file    = format("%s/temp/%s/results.json", path.module, md5(join("-", values(local.external_program_query))))
  alternative_results_file = format("%s/results.json", var.alternative_path)
  results_file             = length(var.alternative_path) == 0 ? local.standard_results_file : local.alternative_results_file
}

data "external" "awscli_program" {
  program = [
    format("%s/scripts/aws_cli_runner.sh", path.module),
    local.results_file
  ]
  query = local.external_program_query
}

# Due to the way the Terraform External Provider has various limitations on processing the output of an external
# program, the script that is called creates a separate file and is then referenced via a local_file data block.
# Amongst the chief benefits is that all the data types returned from AWS are not converted to strings for Terraform to
# access.
data "local_file" "awscli_results_file" {
  depends_on = [data.external.awscli_program]
  filename   = local.results_file

  lifecycle {
    postcondition {
      condition     = try(jsondecode(self.content).error, false) == false
      error_message = try(jsondecode(self.content).error, "Unknown error")
    }
  }
}

output "result" {
  depends_on  = [data.local_file.awscli_results_file]
  description = "The output of the AWS CLI command"
  value       = try(jsondecode(data.local_file.awscli_results_file.content), "")
}
