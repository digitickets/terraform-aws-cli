# tf_mod_aws_cli

Run the AWS CLI, with the ability to run under an assumed role, to access resources and properties missing from the
Terraform AWS Provider.

# Examples

## 1. Get the desired capacity of an autoscaling group.

If you are using a blue/green style deployment, you would want to create the same number of EC2 instances as you are
replacing.

```hcl-terraform
module "current_desired_capacity" {
  source            = "github.com/digitickets/terraform-aws-cli"
  aws_cli_arguments = "autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?Tags[?Key==`Name`]|[?Value==`${var.environment}-asg-app`]]|[0].DesiredCapacity'"
}
```

You can now set the desired capacity of an aws_autoscaling_group:

```hcl-terraform
  desired_capacity = module.current_desired_capacity.result
```

## 2. Assuming a role.

Extending the first example above, assuming a role is as simple as adding an `assume_role_arn` to the module:

```hcl-terraform
module "current_desired_capacity" {
  source            = "github.com/digitickets/terraform-aws-cli"
  assume_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/OrganizationAccountAccessRole"
  aws_cli_arguments = "autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[?Tags[?Key==`Name`]|[?Value==`digitickets-${var.environment}-asg-app`]]|[0].DesiredCapacity'"
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.12.24 |
| external | ~> 1.2.0 |
| local | ~> 1.4.0 |
| random | ~> 2.2.1 |

## Providers

| Name | Version |
|------|---------|
| external | ~> 1.2.0 |
| local | ~> 1.4.0 |
| random | ~> 2.2.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| assume\_role\_arn | The ARN of the role being assumed (optional) | `string` | n/a | yes |
| aws\_cli\_commands | The AWS CLI command and subcommands | `list(string)` | n/a | yes |
| aws\_cli\_query | The --query value | `string` | `""` | no |
| role\_session\_name | The role session name (optional) | `string` | `"terraform-aws-cli"` | no |

## Outputs

| Name | Description |
|------|-------------|
| result | The output of the AWS CLI command |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
