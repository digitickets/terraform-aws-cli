output "result" {
  description = "The output of the AWS CLI command, if it can be JSON decoded"
  value       = module.cli_read.result
}

output "result_raw" {
  description = "The raw, non JSON decoded output of the AWS CLI command"
  value       = module.cli_read.result_raw
}

output "result_was_decoded" {
  description = "Can the output from the AWS CLI command can be JSON decoded"
  value       = module.cli_read.result_was_decoded
}
