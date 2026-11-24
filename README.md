[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/digitickets/terraform-aws-cli/build.yml?style=for-the-badge&logo=github)](https://github.com/digitickets/terraform-aws-cli/actions/workflows/build.yml)
[![GitHub issues](https://img.shields.io/github/issues/digitickets/terraform-aws-cli.svg?style=for-the-badge&logo=github)](https://github.com/digitickets/terraform-aws-cli/issues)

# terraform-aws-cli

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
# Table of contents

- [Plan versus apply](#plan-versus-apply)
  - [Use different IAM identities for plan and apply](#use-different-iam-identities-for-plan-and-apply)
- [Additional requirements](#additional-requirements)
- [cli-read: read-only queries](#cli-read-read-only-queries)
  - [1. Get the desired capacity of an autoscaling group.](#1-get-the-desired-capacity-of-an-autoscaling-group)
  - [2. Assuming a role.](#2-assuming-a-role)
  - [3. Adding your own profile.](#3-adding-your-own-profile)
  - [4. Adding your external ID.](#4-adding-your-external-id)
  - [5. Updating retries parameters.](#5-updating-retries-parameters)
  - [6. Suppress error handling to allow you to handle errors in a more meaningful manner.](#6-suppress-error-handling-to-allow-you-to-handle-errors-in-a-more-meaningful-manner)
  - [Read-only operations only](#read-only-operations-only)
  - [Operations that return secrets are blocked](#operations-that-return-secrets-are-blocked)
  - [What is stored in state and shown in plan output](#what-is-stored-in-state-and-shown-in-plan-output)
- [cli-exec: apply-only commands](#cli-exec-apply-only-commands)
  - [Acting on each item of a list](#acting-on-each-item-of-a-list)
- [Upgrading from 7.x](#upgrading-from-7x)
- [Warning](#warning)
- [Terraform requirements, providers, resources, etc.](#terraform-requirements-providers-resources-etc)
  - [Requirements](#requirements)
  - [Providers](#providers)
  - [Modules](#modules)
  - [Resources](#resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
- [Docker](#docker)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

Run the AWS CLI, optionally under an assumed role, for resources and properties missing from the Terraform AWS
Provider.

This repository contains two modules, for two different kinds of use:

| Module | Use it for | Runs during | Implemented with |
| ------ | ---------- | ----------- | ---------------- |
| [`modules/cli-read`](modules/cli-read) (also the root module) | Read-only queries whose results you use in your configuration | `plan`, `apply` and `refresh`, every time | `data "external"` |
| [`modules/cli-exec`](modules/cli-exec) | Mutating commands | `apply` only, and only when its inputs change | `terraform_data` + `local-exec` |

# Plan versus apply

|  | cli-read | cli-exec |
| - | -------- | -------- |
| Runs during `terraform plan` | Yes | **No** |
| Runs during `terraform apply` | Yes (unless the plan already read it) | Yes, on create, and when replaced |
| Runs during `terraform refresh` | Yes | No |
| Reruns | On every plan, apply and refresh | Only when `commands`, `for_each_item_commands`, `assume_role`, `region`, `show_output`, `ignore_error_codes`, `triggers`, or this module's scripts change |
| Allowed operations | Read-only: `describe-*`, `list-*`, `get-*`, `batch-get-*` and reviewed `check-*` operations, minus a denylist of operations that return secrets | Any |
| Results available to Terraform | Yes: `result`, `result_raw`, `result_was_decoded` | No. Output is discarded unless `show_output = true`, and then only shown in the apply log |
| Stored in state | Inputs, and the full result | Inputs (in `triggers_replace`), never results |
| Credentials needed | Read-only | Whatever the commands need |

## Use different IAM identities for plan and apply

Because cli-exec only runs during apply, and cli-read only reads, the two pipelines can (and should) run as different
IAM identities:

- **Plan**: an identity, or a role in `assume_role_arn`, with **read-only** permissions. A plan is often run for
  unreviewed changes (for example, on every pull request). Even if someone changes a cli-read query, it cannot change
  anything, and the operations on the denylist cannot reveal secrets.
- **Apply**: an identity, or a role in cli-exec's `assume_role`, with the write permissions the commands need, that only
  the reviewed apply pipeline can use.

# Additional requirements

This module requires a few additional tools on the machine running Terraform.

1. Amazon Web Service Command Line Interface (`aws`) version 2
   : This is available in several forms [here](https://aws.amazon.com/cli/).
   As the awscli tool gets updated regularly, please keep it up to date. If you are not getting the functionality you
   require, please read the [AWS CLI V2 Changelog](https://raw.githubusercontent.com/aws/aws-cli/v2/CHANGELOG.rst).

2. JSON processor (`jq`) version 1.6 or later
   : This is available [here](https://jqlang.github.io/jq/).

3. `bash` version 3.2 or later (the version that ships with macOS is fine).

Reference the modules from the Terraform Registry (`digitickets/cli/aws` and `digitickets/cli/aws//modules/cli-exec`),
from git, or by a relative path. Both modules use a shared script in this repository's `scripts/lib` directory, so
copying a single module directory on its own, or referencing one by an absolute path, is not supported.

# cli-read: read-only queries

The root module is an alias of `modules/cli-read`, so existing configurations keep working. New configurations can use
either `digitickets/cli/aws` or `digitickets/cli/aws//modules/cli-read`.

## 1. Get the desired capacity of an autoscaling group.

If you are using a blue/green style deployment, you would want to create the same number of EC2 instances as you are
replacing.

```hcl
module "current_desired_capacity" {
  source            = "digitickets/cli/aws"
  role_session_name = "GettingDesiredCapacityFor${var.environment}"
  aws_cli_commands  = ["autoscaling", "describe-auto-scaling-groups"]
  aws_cli_query     = "AutoScalingGroups[?Tags[?Key==`Name`]|[?Value==`digitickets-${var.environment}-asg-app`]]|[0].DesiredCapacity"
}
```

You can now set the desired capacity of an aws_autoscaling_group:

```hcl-terraform
  desired_capacity = module.current_desired_capacity.result
```

Each element of `aws_cli_commands` is passed to the AWS CLI as exactly one argument, and nothing is interpreted by a
shell. Values containing spaces or quotes must **not** be wrapped in extra quotes:

```hcl
  aws_cli_commands = ["ec2", "describe-instances", "--filters", "Name=tag:Name,Values=web server"]
```

## 2. Assuming a role.

Extending the first example above, assuming a role is as simple as adding an `assume_role_arn` to the module:

```hcl
module "current_desired_capacity" {
  source            = "digitickets/cli/aws"
  assume_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ReadOnly"
  role_session_name = "GettingDesiredCapacityFor${var.environment}"
  aws_cli_commands  = ["autoscaling", "describe-auto-scaling-groups"]
  aws_cli_query     = "AutoScalingGroups[?Tags[?Key==`Name`]|[?Value==`digitickets-${var.environment}-asg-app`]]|[0].DesiredCapacity"
}
```

The temporary credentials are only held in memory by the script and the AWS CLI processes it starts. They are never
written to disk, state, outputs or logs.

## 3. Adding your own profile.

Extending the example above, you can supply your own profile by adding a `profile` to the module:

```hcl
module "current_desired_capacity" {
   source            = "digitickets/cli/aws"
   assume_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ReadOnly"
   role_session_name = "GettingDesiredCapacityFor${var.environment}"
   aws_cli_commands  = ["autoscaling", "describe-auto-scaling-groups"]
   aws_cli_query     = "AutoScalingGroups[?Tags[?Key==`Name`]|[?Value==`digitickets-${var.environment}-asg-app`]]|[0].DesiredCapacity"
   profile           = "your-own-profile"
}
```

When a role is assumed, the profile is only used to assume it. The query itself always runs as the assumed role: neither
`profile` nor an inherited `AWS_PROFILE` can override the assumed credentials. `--profile` is not allowed in
`aws_cli_commands`.

## 4. Adding your external ID.

Extending the example above, you can supply your own external ID by adding an `external_id` to the module:

```hcl
module "current_desired_capacity" {
  source            = "digitickets/cli/aws"
  assume_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ReadOnly"
  role_session_name = "GettingDesiredCapacityFor${var.environment}"
  aws_cli_commands  = ["autoscaling", "describe-auto-scaling-groups"]
  aws_cli_query     = "AutoScalingGroups[?Tags[?Key==`Name`]|[?Value==`digitickets-${var.environment}-asg-app`]]|[0].DesiredCapacity"
  profile           = "your-own-profile"
  external_id       = "your-external-id"
}
```

Further information regarding the use of external IDs can be found [here](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user_externalid.html).

## 5. Updating retries parameters.

```hcl
module "current_desired_capacity" {
  source            = "digitickets/cli/aws"
  assume_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ReadOnly"
  role_session_name = "GettingDesiredCapacityFor${var.environment}"
  aws_cli_commands  = ["autoscaling", "describe-auto-scaling-groups"]
  aws_cli_query     = "AutoScalingGroups[?Tags[?Key==`Name`]|[?Value==`digitickets-${var.environment}-asg-app`]]|[0].DesiredCapacity"
  profile           = "your-own-profile"
  external_id       = "your-external-id"
  retries = {
     max_attempts = 10
     mode         = "standard"
  }
}
```

Further information regarding retries can be found at [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-retries.html).

## 6. Suppress error handling to allow you to handle errors in a more meaningful manner.

One of the issue with Terraform is that it expects things to exist, and if not, create them. The issue is that you
cannot easily determine if something exists.

Calling this module with `var.suppress_error_handling` set to `true` will allow you to receive the error in
`output.result.error`. This can then be used in any manner you want without Terraform stopping when it would normally
stop due to a `data` request against a non-existent target.

## Read-only operations only

cli-read runs during every plan, so it must never change anything. `aws_cli_commands` must start with a service and an
operation beginning `describe-`, `list-`, `get-` or `batch-get-`, or one of the reviewed `check-` operations below.
Anything else is rejected with a message pointing to cli-exec. `--debug` and `--endpoint-url` are also rejected.

`check-` is not a reliably read-only verb: `license-manager check-in-license` returns a checked-out license, and
`lightsail check-subdomain-availability --reserve` reserves the subdomain. So only these reviewed `check-` operations are
allowed. A `check-` operation added to the AWS CLI later is rejected until it has been reviewed and added here.

| Operation | Notes |
| --------- | ----- |
| `accessanalyzer check-access-not-granted` | |
| `accessanalyzer check-no-new-access` | |
| `accessanalyzer check-no-public-access` | |
| `bedrock-agent-runtime check-ingested-document-acl` | |
| `elasticbeanstalk check-dns-availability` | |
| `glue check-schema-version-validity` | |
| `lightsail check-subdomain-availability` | Not with `--reserve`, which reserves the subdomain. |
| `qbusiness check-document-access` | The result includes the document's ACL and the user's groups and aliases. |
| `route53domains check-domain-availability` | |
| `route53domains check-domain-transferability` | Denylisted by default: its `--auth-code` argument is a secret. |
| `sns check-if-phone-number-is-opted-out` | The phone number (personal data) is stored in state as an argument. |
| `wafv2 check-capacity` | |

These rules cannot be overridden: `allow_denylisted_operations` only unblocks operations on the denylist.

## Operations that return secrets are blocked

Some read operations return secrets or credentials, which would be stored in Terraform state and shown in plan output.
These are blocked by default (see [`modules/cli-read/denylist.tf`](modules/cli-read/denylist.tf)), and the error names
the equivalent AWS provider block to use instead, where one exists. For example:

```text
`aws ssm get-parameter` is blocked in cli-read because it returns secret values, which would be stored in Terraform
state and shown in plan output. Use `ephemeral "aws_ssm_parameter"` (Terraform >= 1.10, keeps the value out of state)
or `data "aws_ssm_parameter"`. If you accept that risk, set
`allow_denylisted_operations = { "ssm get-parameter" = true }`.
```

If you need a blocked operation and accept that its result will be in your state and plan output, allow it explicitly:

```hcl
module "parameter_history" {
  source           = "digitickets/cli/aws//modules/cli-read"
  aws_cli_commands = ["ssm", "get-parameter-history", "--name", "/app/feature-flag"]

  allow_denylisted_operations = {
    "ssm get-parameter-history" = true
  }
}
```

Only `true` allows an operation, so the value can be driven from another variable. A key that is not on the denylist is
an error, so a typo cannot silently do nothing. You can block further operations with `additional_denied_operations`.

## What is stored in state and shown in plan output

- **State** holds every cli-read input (including `external_id` and every argument in `aws_cli_commands`) and the
  complete AWS CLI result, in the `external` data source and in the module's outputs. This includes personal or identity
  data, such as a phone number passed to `sns check-if-phone-number-is-opted-out`, or the ACLs, groups and aliases
  returned by `qbusiness check-document-access`.
- **Plan output** shows the outputs of your root module, and any AWS CLI error message.
- **On disk**, nothing is kept. The script works in a private (`umask 077`) temporary directory that is removed on every
  exit path. `debug_log_dir` is opt-in and records arguments, exit codes and error messages only.

So **do not use cli-read to read secrets**. Use the AWS provider's ephemeral resources instead, which keep values out of
state.

# cli-exec: apply-only commands

```hcl
module "log_retention" {
  source = "digitickets/cli/aws//modules/cli-exec"

  assume_role = {
    arn          = "arn:aws:iam::123456789012:role/Deployer"
    session_name = "SettingLogRetention" # optional
    external_id  = "your-external-id"    # optional
  }
  region = "eu-west-2"

  commands = [
    ["logs", "create-log-group", "--log-group-name", "/app/example"],
    ["logs", "put-retention-policy", "--log-group-name", "/app/example", "--retention-in-days", "30"],
  ]

  # Treat these AWS error codes as success, so that reruns are idempotent.
  ignore_error_codes = ["ResourceAlreadyExistsException"]

  # Change a value to rerun the commands on the next apply.
  triggers = {
    revision = "1"
  }
}
```

- Each element of `commands` is one AWS CLI invocation, without the leading `aws`, run in order. Each argument is passed
  literally; nothing is interpreted by a shell.
- With no `assume_role`, the ambient credentials of the process running Terraform are used.
- The commands run when the module is first applied, and again only when one of its inputs, `triggers`, or this
  module's scripts change. Upgrading this module to a version with a changed script therefore reruns the commands once,
  so make them idempotent (`ignore_error_codes` helps).
- The AWS CLI's output is discarded unless `show_output = true`. Errors are always shown, and any error not in
  `ignore_error_codes` fails the apply.
- Nothing runs on destroy.
- The inputs are stored in state (in `triggers_replace`) and shown in the plan, so do not put secrets in them. Command
  results are never stored.

## Acting on each item of a list

`for_each_item_commands` runs a read-only `list` command with `--query`, then runs `command` once per item, with every
`{{item}}` in its arguments replaced by the item. The replacement is literal and never interpreted by a shell. These run
after `commands`.

```hcl
  for_each_item_commands = [
    {
      list      = ["logs", "describe-log-groups", "--log-group-name-prefix", "/app/"]
      query     = "logGroups[?retentionInDays == null].logGroupName"
      command   = ["logs", "put-retention-policy", "--log-group-name", "{{item}}", "--retention-in-days", "30"]
      max_items = 50 # optional, default 100; if more are returned, nothing runs and the apply fails
    },
  ]
```

The query must produce a JSON array of strings or numbers. The items are found at apply time, so they are not shown in
the plan.

If the items are known at plan time, you can instead read them with cli-read and build `commands` from the result, which
shows every command in the plan.

# Upgrading from 7.x

Version 8 is a breaking release:

1. Values in `aws_cli_commands` are no longer interpreted by a shell. Remove any quotes you added around values
   containing spaces (`"'value'"` becomes `"value"`); they would now be passed to the AWS CLI literally.
2. cli-read only accepts read-only operations. Move mutating commands to `modules/cli-exec`. Commands that are not
   `<service> <operation>`, such as `["--version"]`, are rejected.
3. Operations that return secrets are blocked unless allowed with `allow_denylisted_operations`.
4. `--profile`, `--debug` and `--endpoint-url` are not allowed in `aws_cli_commands`. Use `profile` and `debug_log_dir`.
5. `alternative_path` is ignored (no results file is written any more), and `MODULE_TERRAFORM_AWS_CLI_RETAIN_LOGS` has
   no effect. Use `debug_log_dir`.
6. The scripts now require `bash`.

# Warning

cli-read uses Terraform's `external` data source. As per the warnings
[here](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external), Terraform expects
a data source to have _no observable side-effects_, and will re-run the program each time the state is refreshed. That
is why cli-read only allows read-only operations, and why mutating commands belong in cli-exec.

These modules are _NOT_ a replacement for the AWS Terraform Provider. Prefer a provider resource or data source wherever
one exists.

# Terraform requirements, providers, resources, etc.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.6 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_cli_read"></a> [cli\_read](#module\_cli\_read) | ./modules/cli-read | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required | Validation |
| ---- | ----------- | ---- | ------- | :------: | ---------- |
| <a name="input_additional_denied_operations"></a> [additional\_denied\_operations](#input\_additional\_denied\_operations) | Further operations to block, in addition to the built-in denylist. See `modules/cli-read`. | `map(string)` | `{}` | no | None |
| <a name="input_allow_denylisted_operations"></a> [allow\_denylisted\_operations](#input\_allow\_denylisted\_operations) | Explicitly allow denylisted operations (`"<service> <operation>" = true`). See `modules/cli-read`. | `map(bool)` | `{}` | no | None |
| <a name="input_alternative_path"></a> [alternative\_path](#input\_alternative\_path) | DEPRECATED and ignored. See `modules/cli-read`. | `string` | `""` | no | None |
| <a name="input_assume_role_arn"></a> [assume\_role\_arn](#input\_assume\_role\_arn) | The ARN of the role being assumed (optional). See `modules/cli-read`. | `string` | `""` | no | None |
| <a name="input_aws_cli_commands"></a> [aws\_cli\_commands](#input\_aws\_cli\_commands) | The AWS CLI service, operation, and options (without the leading `aws`). See `modules/cli-read`. | `list(string)` | n/a | yes | None |
| <a name="input_aws_cli_query"></a> [aws\_cli\_query](#input\_aws\_cli\_query) | The `--query` (JMESPath) value for the AWS CLI call. See `modules/cli-read`. | `string` | `""` | no | None |
| <a name="input_debug_log_dir"></a> [debug\_log\_dir](#input\_debug\_log\_dir) | Opt-in debug logging directory (never logs credentials or results). See `modules/cli-read`. | `string` | `""` | no | None |
| <a name="input_external_id"></a> [external\_id](#input\_external\_id) | External id for assuming the role (optional). See `modules/cli-read`. | `string` | `""` | no | None |
| <a name="input_profile"></a> [profile](#input\_profile) | The specific AWS profile to use (optional). See `modules/cli-read`. | `string` | `""` | no | None |
| <a name="input_region"></a> [region](#input\_region) | The specific AWS region to use (optional). See `modules/cli-read`. | `string` | `""` | no | None |
| <a name="input_retries"></a> [retries](#input\_retries) | Configuration for retries when making AWS CLI calls. See `modules/cli-read`. | <pre>object({<br/>    max_attempts = optional(number, 4)<br/>    mode         = optional(string, "adaptive")<br/>  })</pre> | `{}` | no | None |
| <a name="input_role_session_name"></a> [role\_session\_name](#input\_role\_session\_name) | The role session name that will be used when assuming a role (optional). See `modules/cli-read`. | `string` | `""` | no | None |
| <a name="input_suppress_error_handling"></a> [suppress\_error\_handling](#input\_suppress\_error\_handling) | Suppress errors, allowing the caller to access and handle the error appropriately. See `modules/cli-read`. | `bool` | `false` | no | None |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_result"></a> [result](#output\_result) | The output of the AWS CLI command, if it can be JSON decoded |
| <a name="output_result_raw"></a> [result\_raw](#output\_result\_raw) | The raw, non JSON decoded output of the AWS CLI command |
| <a name="output_result_was_decoded"></a> [result\_was\_decoded](#output\_result\_was\_decoded) | Can the output from the AWS CLI command can be JSON decoded |
<!-- END_TF_DOCS -->

# Docker

To help with getting this running in a pipeline that uses Docker, the image [digiticketsgroup/terraforming](https://hub.docker.com/repository/docker/digiticketsgroup/terraforming) has Terraform, AWSCLI, and jq all ready to go.

If you want to build or adapt your own image, then the Dockerfile below is how that image has been built.

```Dockerfile
# Based upon https://github.com/aws/aws-cli/blob/2.0.10/docker/Dockerfile
FROM amazonlinux:2 as installer
ARG TERRAFORM_VERSION
RUN yum update -y \
  && yum install -y unzip \
  && curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscli-exe-linux-x86_64.zip \
  && unzip awscli-exe-linux-x86_64.zip \
  # The --bin-dir is specified so that we can copy the
  # entire bin directory from the installer stage into
  # into /usr/local/bin of the final stage without
  # accidentally copying over any other executables that
  # may be present in /usr/local/bin of the installer stage.
  && ./aws/install --bin-dir /aws-cli-bin/ \
  && curl "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o terraform.zip \
  && unzip terraform.zip

FROM amazonlinux:2
COPY --from=installer /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=installer /aws-cli-bin/ /usr/local/bin/
COPY --from=installer terraform /usr/bin/
RUN yum update -y \
  && yum install -y less groff jq \
  && yum clean all

ENTRYPOINT ["/bin/sh"]
```
