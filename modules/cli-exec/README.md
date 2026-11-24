<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
# Table of contents

- [cli-exec](#cli-exec)
  - [Requirements](#requirements)
  - [Providers](#providers)
  - [Modules](#modules)
  - [Resources](#resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# cli-exec

Mutating AWS CLI commands, run at apply time only (never during plan or refresh), through a `terraform_data` resource
with a `local-exec` provisioner. The commands rerun only when their inputs, `triggers`, or this module's scripts change.

See the [repository README](../../README.md#cli-exec-apply-only-commands) for usage, and for running plan and apply under
different IAM identities.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.6 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [terraform_data.aws_cli_exec](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required | Validation |
| ---- | ----------- | ---- | ------- | :------: | ---------- |
| <a name="input_assume_role"></a> [assume\_role](#input\_assume\_role) | The role to assume before running the commands (optional). When `null`, the ambient credentials of the process running<br/>  Terraform are used.<br/><br/>  The temporary credentials are held in the script's own process only: they are never written to disk, state, outputs,<br/>  or logs. | <pre>object({<br/>    arn          = string<br/>    external_id  = optional(string, "")<br/>    session_name = optional(string, "TerraformAwsCliExec")<br/>  })</pre> | `null` | no | The `var.assume_role.arn` must be an IAM role ARN, for example `arn:aws:iam::123456789012:role/Name`.<br>The `var.assume_role.external_id`, when supplied, must be 2 to 1224 characters matching `[\w+=,.@:/-]`.<br>The `var.assume_role.session_name` must be 2 to 64 characters matching `[\w=,.@-]`. |
| <a name="input_commands"></a> [commands](#input\_commands) | The AWS CLI commands to run at apply time, in order. Each element is one invocation, without the leading `aws`: a<br/>  service, an operation, and its options. For example:<pre>hcl<br/>  commands = [<br/>    ["ec2", "create-tags", "--resources", "i-0123456789abcdef0", "--tags", "Key=Name,Value=web server"],<br/>  ]</pre>Each element of an invocation is passed to the AWS CLI as exactly one argument. Nothing is interpreted by a shell, so<br/>  values must NOT be wrapped in extra quotes. `--profile` (use `var.assume_role` or the ambient credentials) and `--debug`<br/>  (it logs raw responses, including credentials) are not allowed. | `list(list(string))` | `[]` | no | No command in `var.commands` can be empty.<br>The `var.commands` must not contain `--profile` (it would override the assumed role) or `--debug` (it logs raw responses, including credentials). |
| <a name="input_for_each_item_commands"></a> [for\_each\_item\_commands](#input\_for\_each\_item\_commands) | Commands that act on each item returned by an earlier, read-only command. They run after `var.commands`, in order.<br/><br/>  For each entry, `list` (a read-only command: its operation must start with `describe-`, `list-`, `get-`, or<br/>  `batch-get-`) is run with `--query` set to `query`, which must produce a JSON array of strings or numbers (`null` counts as empty). `command` is<br/>  then run once per item, with every `{{item}}` in each of its arguments replaced by the item. The replacement is<br/>  literal and never interpreted by a shell. If the list returns more than `max_items` items, nothing is run and the<br/>  apply fails. For example:<pre>hcl<br/>  for_each_item_commands = [<br/>    {<br/>      list    = ["logs", "describe-log-groups", "--log-group-name-prefix", "/app/"]<br/>      query   = "logGroups[?retentionInDays == null].logGroupName"<br/>      command = ["logs", "put-retention-policy", "--log-group-name", "{{item}}", "--retention-in-days", "30"]<br/>    },<br/>  ]</pre>The items are resolved at apply time, so they are not shown in the plan. | <pre>list(object({<br/>    list      = list(string)<br/>    query     = string<br/>    command   = list(string)<br/>    max_items = optional(number, 100)<br/>  }))</pre> | `[]` | no | Each `list` in `var.for_each_item_commands` must be a service and a read-only operation (one starting with `describe-`, `list-`, `get-`, or `batch-get-`), followed by its options.<br>Each `query` in `var.for_each_item_commands` must be a JMESPath expression producing a list of strings or numbers.<br>Each `command` in `var.for_each_item_commands` must contain `{{item}}` in at least one argument.<br>Each `max_items` in `var.for_each_item_commands` must be a whole number between 1 and 1000.<br>The `var.for_each_item_commands` must not contain `--profile`, `--debug`, `--query` (use `query`), or `--output`. |
| <a name="input_ignore_error_codes"></a> [ignore\_error\_codes](#input\_ignore\_error\_codes) | AWS error codes (for example `ResourceAlreadyExistsException`) that are treated as success, so that commands can be<br/>  rerun idempotently. Any other error fails the apply. | `list(string)` | `[]` | no | Each entry of `var.ignore_error_codes` must be an AWS error code, for example `ResourceAlreadyExistsException`. |
| <a name="input_region"></a> [region](#input\_region) | The AWS region to use (optional). When empty, the AWS CLI's normal region resolution applies. | `string` | `""` | no | The optional region must start with two letters representing the geographical area, followed by one or more letters or digits representing the specific region within that area. |
| <a name="input_show_output"></a> [show\_output](#input\_show\_output) | Show the AWS CLI's standard output in the Terraform apply log. By default it is discarded. Errors are always shown. | `bool` | `false` | no | None |
| <a name="input_triggers"></a> [triggers](#input\_triggers) | Arbitrary values that, when changed, cause the commands to be run again on the next apply. The commands also rerun<br/>  whenever any other input, or this module's scripts, change. | `map(string)` | `{}` | no | None |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | The id of the `terraform_data` resource. It changes each time the commands are run. No command output is ever exposed. |
<!-- END_TF_DOCS -->
