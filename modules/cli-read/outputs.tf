output "result" {
  description = "The output of the AWS CLI command, if it can be JSON decoded"
  value       = try(jsondecode(local.content), "")
}

output "result_raw" {
  description = "The raw, non JSON decoded output of the AWS CLI command"
  value       = local.content
}

output "result_was_decoded" {
  description = "Can the output from the AWS CLI command can be JSON decoded"
  value       = can(jsondecode(local.content))
}
