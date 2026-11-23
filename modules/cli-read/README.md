<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
# Table of contents

- [cli-read](#cli-read)
  - [Requirements](#requirements)
  - [Providers](#providers)
  - [Modules](#modules)
  - [Resources](#resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# cli-read

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.6 |
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_external"></a> [external](#provider\_external) | 2.4.2 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [external_external.awscli_program](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required | Validation |
| ---- | ----------- | ---- | ------- | :------: | ---------- |
| <a name="input_alternative_path"></a> [alternative\_path](#input\_alternative\_path) | Use an alternative path for all files produced internally | `string` | `""` | no | None |
| <a name="input_assume_role_arn"></a> [assume\_role\_arn](#input\_assume\_role\_arn) | The ARN of the role being assumed (optional).<br/><br/>  The optional ARN must match the format documented in https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html. | `string` | `""` | no | The optional ARN must match the format documented in https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html. |
| <a name="input_aws_cli_commands"></a> [aws\_cli\_commands](#input\_aws\_cli\_commands) | The AWS CLI service, operation, and options, without the leading `aws`.<br/><br/>  Each element is passed to the AWS CLI as exactly one argument. Nothing is interpreted by a shell, so values containing<br/>  spaces, quotes, or other special characters must NOT be wrapped in extra quotes. For options that accept a value,<br/>  both of these forms work:<br/>  1. `"--option", "value with spaces"`<br/>  2. `"--option=value with spaces"` | `list(string)` | n/a | yes | The `var.aws_cli_commands` cannot be empty.<br>The `var.aws_cli_commands` must not contain `--profile`, as it would override any assumed role. Use `var.profile` instead. |
| <a name="input_aws_cli_query"></a> [aws\_cli\_query](#input\_aws\_cli\_query) | The `--query` value for the AWS CLI call.<br/><br/>  The value for `var.aws_cli_query` is based upon JMESPath, and you can get good information from https://jmespath.org.<br/>  If not supplied, then the entire results from the AWS CLI call will be returned. | `string` | `""` | no | None |
| <a name="input_external_id"></a> [external\_id](#input\_external\_id) | External id for assuming the role (optional).<br/><br/>  The length of optional external\_id, when supplied, must be between 2 and 1224 characters.<br/>  The optional external\_id can only contain upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: `=,.@-`.<br/>  The optional external\_id match the regular expression `^[\w=,.@-]*$`. | `string` | `""` | no | The length of optional external\_id, when supplied, must be between 2 and 1224 characters.<br>The optional external\_id must match the regular expression '^[\w=,.@-]*$'. |
| <a name="input_profile"></a> [profile](#input\_profile) | The specific AWS profile to use (must be configured appropriately and is optional).<br/><br/>  The optional profile must start with a letter and can only contain letters, numbers, hyphens, and underscores. | `string` | `""` | no | The optional profile must start with a letter and can only contain letters, numbers, hyphens, and underscores. |
| <a name="input_region"></a> [region](#input\_region) | The specific AWS region to use.<br/><br/>  The region must start with two letters representing the geographical area, followed by one or more letters or digits representing the specific region within that area. | `string` | `""` | no | The optional region must start with two letters representing the geographical area, followed by one or more letters or digits representing the specific region within that area. |
| <a name="input_retries"></a> [retries](#input\_retries) | Configuration for retries when making AWS CLI calls.<br/><br/>  The `max_attempts` specifies a value of maximum retry attempts the AWS CLI retry handler uses, where the initial call<br/>  counts toward the value that you provide.<br/>  The `mode` can be one of the following:<br/>    - `legacy`: Uses the legacy retry mode.<br/>    - `standard`: Uses the standard retry mode.<br/>    - `adaptive`: Experimental retry mode that includes all the features of standard mode. In addition to the standard<br/>  mode features, adaptive mode also introduces client-side rate limiting through the use of a token bucket and<br/>  rate-limit variables that are dynamically updated with each retry attempt.<br/><br/>  More information about retry modes can be found in the AWS documentation:<br/>  https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-retries.html | <pre>object({<br/>    max_attempts = optional(number, 4)<br/>    mode         = optional(string, "adaptive")<br/>  })</pre> | `{}` | no | The retries mode must be one of 'legacy', 'standard', or 'adaptive'. |
| <a name="input_role_session_name"></a> [role\_session\_name](#input\_role\_session\_name) | The role session name that will be used when assuming a role (optional)<br/><br/>  The length of the optional role session name, when supplied, must be between 2 and 64 characters.<br/>  The optional role session name can only contain upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: `=,.@-`.<br/>  The optional role session name match the regular expression `^[\w=,.@-]*$`.<br/><br/>  If the assume\_role\_arn is supplied, but the role\_session\_name is left empty, an internal default of "AssumingRole" will be used. | `string` | `""` | no | The length of the optional role session name, when supplied, must be between 2 and 64 characters.<br>The role session name match the regular expression '^[\w=,.@-]*$'. |
| <a name="input_suppress_error_handling"></a> [suppress\_error\_handling](#input\_suppress\_error\_handling) | Suppress errors, allowing the caller to access and handle the error appropriately | `bool` | `false` | no | None |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_result"></a> [result](#output\_result) | The output of the AWS CLI command, if it can be JSON decoded |
| <a name="output_result_raw"></a> [result\_raw](#output\_result\_raw) | The raw, non JSON decoded output of the AWS CLI command |
| <a name="output_result_was_decoded"></a> [result\_was\_decoded](#output\_result\_was\_decoded) | Can the output from the AWS CLI command can be JSON decoded |
<!-- END_TF_DOCS -->
