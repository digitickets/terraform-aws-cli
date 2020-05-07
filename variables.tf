variable "assume_role_arn" {
  description = "The ARN of the role being assumed (optional)"
  type        = string
}

variable "aws_cli_commands" {
  description = "The AWS CLI command and subcommands"
  type        = list(string)
}

variable "aws_cli_query" {
  description = "The --query value"
  type        = string
  default     = ""
}

variable "role_session_name" {
  description = "The role session name (optional)"
  type        = string
  default     = "terraform-aws-cli"
}
