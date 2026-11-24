<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
# Table of contents

- [exec](#exec)
  - [Requirements](#requirements)
  - [Providers](#providers)
  - [Modules](#modules)
  - [Resources](#resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# exec

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
| <a name="module_log_retention"></a> [log\_retention](#module\_log\_retention) | ../../modules/cli-exec | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required | Validation |
| ---- | ----------- | ---- | ------- | :------: | ---------- |
| <a name="input_deployer_role_arn"></a> [deployer\_role\_arn](#input\_deployer\_role\_arn) | A role with the permissions the commands need. Only the apply pipeline should be able to assume it. | `string` | `"arn:aws:iam::123456789012:role/Deployer"` | no | None |
| <a name="input_log_group_name"></a> [log\_group\_name](#input\_log\_group\_name) | The log group to create. | `string` | `"/app/example"` | no | None |
| <a name="input_retention_in_days"></a> [retention\_in\_days](#input\_retention\_in\_days) | How long to keep log events. | `number` | `30` | no | None |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | Changes each time the commands are run. |
<!-- END_TF_DOCS -->
