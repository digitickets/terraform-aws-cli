# These variables mirror `modules/cli-read`, where they are documented and validated in full.

variable "aws_cli_commands" {
  description = "The AWS CLI service, operation, and options (without the leading `aws`). See `modules/cli-read`."
  type        = list(string)
}

variable "aws_cli_query" {
  description = "The `--query` (JMESPath) value for the AWS CLI call. See `modules/cli-read`."
  type        = string
  default     = ""
}

variable "assume_role_arn" {
  description = "The ARN of the role being assumed (optional). See `modules/cli-read`."
  type        = string
  default     = ""
}

variable "external_id" {
  description = "External id for assuming the role (optional). See `modules/cli-read`."
  type        = string
  default     = ""
}

variable "profile" {
  description = "The specific AWS profile to use (optional). See `modules/cli-read`."
  type        = string
  default     = ""
}

variable "region" {
  description = "The specific AWS region to use (optional). See `modules/cli-read`."
  type        = string
  default     = ""
}

variable "role_session_name" {
  description = "The role session name that will be used when assuming a role (optional). See `modules/cli-read`."
  type        = string
  default     = ""
}

variable "alternative_path" {
  description = "Use an alternative path for all files produced internally. See `modules/cli-read`."
  type        = string
  default     = ""
}

variable "retries" {
  description = "Configuration for retries when making AWS CLI calls. See `modules/cli-read`."
  type = object({
    max_attempts = optional(number, 4)
    mode         = optional(string, "adaptive")
  })
  default = {}
}

variable "suppress_error_handling" {
  description = "Suppress errors, allowing the caller to access and handle the error appropriately. See `modules/cli-read`."
  type        = bool
  default     = false
}
