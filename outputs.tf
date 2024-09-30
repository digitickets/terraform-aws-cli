output "result" {
  depends_on  = [data.local_file.awscli_results_file]
  description = "The output of the AWS CLI command, if it can be JSON decoded"
  value       = try(jsondecode(data.local_file.awscli_results_file.content), "")
}

output "result_raw" {
  depends_on  = [data.local_file.awscli_results_file]
  description = "The raw, non JSON decoded output of the AWS CLI command"
  value       = data.local_file.awscli_results_file.content
}

output "result_was_decoded" {
  depends_on  = [data.local_file.awscli_results_file]
  description = "Can the output from the AWS CLI command can be JSON decoded"
  value       = can(jsondecode(data.local_file.awscli_results_file.content))
}
