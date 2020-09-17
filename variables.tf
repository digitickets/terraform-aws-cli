variable "assume_role_arn" {
  description = "The ARN of the role being assumed (optional)"
  type        = string
  default     = ""
  validation {
    condition     = can(regex("^(?:arn:aws(?:-cn|-us-gov|):(?:iam|sts)::[0-9]{12}:.+|)$", var.assume_role_arn))
    error_message = "The optional ARN must match the format documented in https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html."
  }
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
