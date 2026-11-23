variable "commands" {
  description = <<EOD
  The AWS CLI commands to run at apply time, in order. Each element is one invocation, without the leading `aws`: a
  service, an operation, and its options. For example:

  ```hcl
  commands = [
    ["ec2", "create-tags", "--resources", "i-0123456789abcdef0", "--tags", "Key=Name,Value=web server"],
  ]
  ```

  Each element of an invocation is passed to the AWS CLI as exactly one argument. Nothing is interpreted by a shell, so
  values must NOT be wrapped in extra quotes. `--profile` (use `var.assume_role` or the ambient credentials) and `--debug`
  (it logs raw responses, including credentials) are not allowed.
EOD
  type        = list(list(string))

  validation {
    condition     = length(var.commands) > 0 && alltrue([for command in var.commands : length(command) > 0])
    error_message = "The `var.commands` must contain at least one command, and no command can be empty."
  }

  validation {
    condition     = alltrue([for command in var.commands : alltrue([for arg in command : !can(regex("^--(profile|debug)(=|$)", arg))])])
    error_message = "The `var.commands` must not contain `--profile` (it would override the assumed role) or `--debug` (it logs raw responses, including credentials)."
  }
}

variable "assume_role" {
  description = <<EOD
  The role to assume before running the commands (optional). When `null`, the ambient credentials of the process running
  Terraform are used.

  The temporary credentials are held in the script's own process only: they are never written to disk, state, outputs,
  or logs.
EOD
  type = object({
    arn          = string
    external_id  = optional(string, "")
    session_name = optional(string, "TerraformAwsCliExec")
  })
  default = null

  validation {
    condition     = var.assume_role == null ? true : can(regex("^arn:aws(-cn|-us-gov)?:iam::[0-9]{12}:role/[\\w+=,.@/-]+$", var.assume_role.arn))
    error_message = "The `var.assume_role.arn` must be an IAM role ARN, for example `arn:aws:iam::123456789012:role/Name`."
  }

  validation {
    condition     = var.assume_role == null ? true : (var.assume_role.external_id == "" || can(regex("^[\\w+=,.@:/-]{2,1224}$", var.assume_role.external_id)))
    error_message = "The `var.assume_role.external_id`, when supplied, must be 2 to 1224 characters matching `[\\w+=,.@:/-]`."
  }

  validation {
    condition     = var.assume_role == null ? true : can(regex("^[\\w=,.@-]{2,64}$", var.assume_role.session_name))
    error_message = "The `var.assume_role.session_name` must be 2 to 64 characters matching `[\\w=,.@-]`."
  }
}

variable "region" {
  description = "The AWS region to use (optional). When empty, the AWS CLI's normal region resolution applies."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^([a-z]{2}-[a-z0-9-]+|)$", var.region))
    error_message = "The optional region must start with two letters representing the geographical area, followed by one or more letters or digits representing the specific region within that area."
  }
}

variable "triggers" {
  description = <<EOD
  Arbitrary values that, when changed, cause the commands to be run again on the next apply. The commands also rerun
  whenever any other input, or this module's scripts, change.
EOD
  type        = map(string)
  default     = {}
}

variable "show_output" {
  description = "Show the AWS CLI's standard output in the Terraform apply log. By default it is discarded. Errors are always shown."
  type        = bool
  default     = false
}

variable "ignore_error_codes" {
  description = <<EOD
  AWS error codes (for example `ResourceAlreadyExistsException`) that are treated as success, so that commands can be
  rerun idempotently. Any other error fails the apply.
EOD
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for code in var.ignore_error_codes : can(regex("^[A-Za-z0-9._-]+$", code))])
    error_message = "Each entry of `var.ignore_error_codes` must be an AWS error code, for example `ResourceAlreadyExistsException`."
  }
}
