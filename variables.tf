# Variables related to calling AWS CLI
variable "aws_cli_commands" {
  description = <<EOT
  The AWS CLI command, subcommands, and options.

  For options that can accept a value, then the following examples are both fine to use:
  1. `"--option", "value"`
  2. `"--option=value"`

  In the event that the value contains a space, it must be wrapped with quotes.
  1. `"--option", "'value with a space wrapped in single quotes'"`
  2. `"--option='value with a space wrapped in single quotes'"`
EOT
  type        = list(string)
}

variable "aws_cli_query" {
  description = <<EOD
  The `--query` value for the AWS CLI call.

  The value for `var.aws_cli_query` is based upon JMESPath, and you can get good information from https://jmespath.org.
  If not supplied, then the entire results from the AWS CLI call will be returned.
EOD
  type        = string
  default     = ""
}

variable "assume_role_arn" {
  description = <<EOT
  The ARN of the role being assumed (optional).

  The optional ARN must match the format documented in https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html.
EOT
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^(?:arn:aws(?:-cn|-us-gov|):(?:iam|sts)::[0-9]{12}:.+|)$", var.assume_role_arn))
    error_message = "The optional ARN must match the format documented in https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html."
  }
}

variable "external_id" {
  description = <<EOD
  External id for assuming the role (optional).

  The length of optional external_id, when supplied, must be between 2 and 1224 characters.
  The optional external_id can only contain upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: `=,.@-`.
  The optional external_id match the regular expression `^[\w=,.@-]*$`.
EOD
  type        = string
  default     = ""

  validation {
    condition     = length(var.external_id) == 0 || (length(var.external_id) >= 2 && length(var.external_id) <= 1224)
    error_message = "The length of optional external_id, when supplied, must be between 2 and 1224 characters."
  }

  validation {
    condition     = can(regex("^[\\w=,.@-]*$", var.external_id))
    error_message = "The optional external_id must match the regular expression '^[\\w=,.@-]*$'."
  }
}

variable "profile" {
  description = <<EOD
  The specific AWS profile to use (must be configured appropriately and is optional).

  The optional profile must start with a letter and can only contain letters, numbers, hyphens, and underscores.
EOD
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^([a-zA-Z][a-zA-Z0-9_-]*|)$", var.profile))
    error_message = "The optional profile must start with a letter and can only contain letters, numbers, hyphens, and underscores."
  }
}

variable "region" {
  description = <<EOD
  The specific AWS region to use.

  The region must start with two letters representing the geographical area, followed by one or more letters or digits representing the specific region within that area.
EOD
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^([a-z]{2}-[a-z0-9-]+|)$", var.region))
    error_message = "The optional region must start with two letters representing the geographical area, followed by one or more letters or digits representing the specific region within that area."
  }
}

variable "role_session_name" {
  description = <<EOD
  The role session name that will be used when assuming a role (optional)

  The length of the optional role session name, when supplied, must be between 2 and 64 characters.
  The optional role session name can only contain upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: `=,.@-`.
  The optional role session name match the regular expression `^[\w=,.@-]*$`.

  If the assume_role_arn is supplied, but the role_session_name is left empty, an internal default of "AssumingRole" will be used.
EOD
  type        = string
  default     = ""

  validation {
    condition     = length(var.role_session_name) == 0 || (length(var.role_session_name) >= 2 && length(var.role_session_name) <= 64)
    error_message = "The length of the optional role session name, when supplied, must be between 2 and 64 characters."
  }

  validation {
    condition     = can(regex("^[\\w=,.@-]*$", var.role_session_name))
    error_message = "The role session name match the regular expression '^[\\w=,.@-]*$'."
  }
}

# Variable for debugging
variable "alternative_path" {
  description = "Use an alternative path for all files produced internally"
  type        = string
  default     = ""
}

variable "retries" {
  description = <<EOD
  Configuration for retries when making AWS CLI calls.

  The `max_attempts` specifies a value of maximum retry attempts the AWS CLI retry handler uses, where the initial call
  counts toward the value that you provide.
  The `mode` can be one of the following:
    - `legacy`: Uses the legacy retry mode.
    - `standard`: Uses the standard retry mode.
    - `adaptive`: Experimental retry mode that includes all the features of standard mode. In addition to the standard
  mode features, adaptive mode also introduces client-side rate limiting through the use of a token bucket and
  rate-limit variables that are dynamically updated with each retry attempt.

  More information about retry modes can be found in the AWS documentation:
  https://docs.aws.amazon.com/cli/v1/userguide/cli-configure-retries.html
EOD
  type = object({
    max_attempts = optional(number, 4)
    mode         = optional(string, "adaptive")
  })
  default = {}

  validation {
    condition     = contains(["legacy", "standard", "adaptive"], var.retries.mode)
    error_message = "The retries mode must be one of 'legacy', 'standard', or 'adaptive'."
  }
}
