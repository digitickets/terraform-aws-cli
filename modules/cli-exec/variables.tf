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
  default     = []

  validation {
    condition     = alltrue([for command in var.commands : length(command) > 0])
    error_message = "No command in `var.commands` can be empty."
  }

  validation {
    condition     = alltrue([for command in var.commands : alltrue([for arg in command : !can(regex("^--(profile|debug)(=|$)", arg))])])
    error_message = "The `var.commands` must not contain `--profile` (it would override the assumed role) or `--debug` (it logs raw responses, including credentials)."
  }
}

variable "for_each_item_commands" {
  description = <<EOD
  Commands that act on each item returned by an earlier, read-only command. They run after `var.commands`, in order.

  For each entry, `list` (a read-only command: its operation must start with `describe-`, `list-`, `get-`, or
  `batch-get-`) is run with `--query` set to `query`, which must produce a JSON array of strings or numbers (`null` counts as empty). `command` is
  then run once per item, with every `{{item}}` in each of its arguments replaced by the item. The replacement is
  literal and never interpreted by a shell. If the list returns more than `max_items` items, nothing is run and the
  apply fails. For example:

  ```hcl
  for_each_item_commands = [
    {
      list    = ["logs", "describe-log-groups", "--log-group-name-prefix", "/app/"]
      query   = "logGroups[?retentionInDays == null].logGroupName"
      command = ["logs", "put-retention-policy", "--log-group-name", "{{item}}", "--retention-in-days", "30"]
    },
  ]
  ```

  The items are resolved at apply time, so they are not shown in the plan.
EOD
  type = list(object({
    list      = list(string)
    query     = string
    command   = list(string)
    max_items = optional(number, 100)
  }))
  default = []

  validation {
    condition     = alltrue([for step in var.for_each_item_commands : can(regex("^(describe|list|get|batch-get)-[a-z0-9-]+$", try(step.list[1], "")))])
    error_message = "Each `list` in `var.for_each_item_commands` must be a service and a read-only operation (one starting with `describe-`, `list-`, `get-`, or `batch-get-`), followed by its options."
  }

  validation {
    condition     = alltrue([for step in var.for_each_item_commands : length(trimspace(step.query)) > 0])
    error_message = "Each `query` in `var.for_each_item_commands` must be a JMESPath expression producing a list of strings or numbers."
  }

  validation {
    condition     = alltrue([for step in var.for_each_item_commands : length(step.command) > 0 && anytrue([for arg in step.command : strcontains(arg, "{{item}}")])])
    error_message = "Each `command` in `var.for_each_item_commands` must contain `{{item}}` in at least one argument."
  }

  validation {
    condition     = alltrue([for step in var.for_each_item_commands : step.max_items >= 1 && step.max_items <= 1000 && floor(step.max_items) == step.max_items])
    error_message = "Each `max_items` in `var.for_each_item_commands` must be a whole number between 1 and 1000."
  }

  validation {
    condition     = alltrue([for step in var.for_each_item_commands : alltrue([for arg in concat(step.list, step.command) : !can(regex("^--(profile|debug|query|output)(=|$)", arg))])])
    error_message = "The `var.for_each_item_commands` must not contain `--profile`, `--debug`, `--query` (use `query`), or `--output`."
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
