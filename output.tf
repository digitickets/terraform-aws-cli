output "result" {
  description = "The output of the AWS CLI command"
  value       = jsondecode(data.local_file.awscli_results_file.content)
}
