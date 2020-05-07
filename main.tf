resource "random_string" "awscli_output_temp_file_name" {
  length  = 16
  special = false
}

resource "local_file" "awscli_results_file" {
  filename             = "${path.module}/temp/${random_string.awscli_output_temp_file_name.result}.json"
  directory_permission = "0777"
}

data "external" "awscli_program" {
  program = ["${path.module}/scripts/awsWithAssumeRole.sh"]
  query = {
    assume_role_arn   = var.assume_role_arn
    role_session_name = var.role_session_name
    aws_cli_commands  = join(" ", var.aws_cli_commands)
    aws_cli_query     = var.aws_cli_query
    output_file       = local_file.awscli_results_file.filename
  }
}

data "local_file" "awscli_results_file" {
  filename = data.external.awscli_program.query.output_file
}
