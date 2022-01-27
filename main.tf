data "external" "awscli_program" {
  program = [format("%s/scripts/awsWithAssumeRole.sh", path.module)]
  query = {
    assume_role_arn    = var.assume_role_arn
    role_session_name  = var.role_session_name
    aws_cli_commands   = join(" ", var.aws_cli_commands)
    aws_cli_query      = var.aws_cli_query
    output_file        = format("%s/temp/results.json", path.module)
    debug_log_filename = var.debug_log_filename
  }
}

data "local_file" "awscli_results_file" {
  depends_on = [data.external.awscli_program]
  filename   = data.external.awscli_program.query.output_file
}

output "result" {
  depends_on  = [data.local_file.awscli_results_file]
  description = "The output of the AWS CLI command"
  value       = jsondecode(data.local_file.awscli_results_file.content)
}
