variable "assume_role_arn" {
  description = "The ARN of the role being assumed (optional)"
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^(?:arn:aws(?:-cn|-us-gov|):(?:iam|sts)::[0-9]{12}:.+|)$", var.assume_role_arn))
    error_message = "The optional ARN must match the format documented in https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html."
  }
}

variable "external_id" {
  description = ">xternal id for assuming the role (optional)"
  type        = string
  default     = ""
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
  description = "The role session name"
  type        = string
  default     = ""

  validation {
    condition     = length(var.role_session_name) <= 64
    error_message = "The role session name must be less than or equal to 64 characters."
  }

  validation {
    condition     = can(regex("^[\\w+=,.@-]*$", var.role_session_name))
    error_message = "The role session name match the regular expression '^[\\w+=,.@-]*$'."
  }
}

variable "debug_log_filename" {
  description = "Generate a debug log if a `debug_log_filename` is supplied"
  type        = string
  default     = ""
}

