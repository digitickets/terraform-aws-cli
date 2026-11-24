<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
# Table of contents

- [read](#read)
  - [Requirements](#requirements)
  - [Providers](#providers)
  - [Modules](#modules)
  - [Resources](#resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# read

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
| <a name="module_current_desired_capacity"></a> [current\_desired\_capacity](#module\_current\_desired\_capacity) | ../../modules/cli-read | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required | Validation |
| ---- | ----------- | ---- | ------- | :------: | ---------- |
| <a name="input_auto_scaling_group_name"></a> [auto\_scaling\_group\_name](#input\_auto\_scaling\_group\_name) | The auto scaling group to inspect. | `string` | `"example-asg"` | no | None |
| <a name="input_reader_role_arn"></a> [reader\_role\_arn](#input\_reader\_role\_arn) | A role with read-only permissions to assume for the query. | `string` | `"arn:aws:iam::123456789012:role/ReadOnly"` | no | None |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_desired_capacity"></a> [desired\_capacity](#output\_desired\_capacity) | The current desired capacity of the auto scaling group. |
<!-- END_TF_DOCS -->
