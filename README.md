[![Build Status](https://img.shields.io/travis/digitickets/terraform-aws-cli.svg?style=for-the-badge&logo=travis)](https://travis-ci.com/digitickets/terraform-aws-cli)
[![GitHub issues](https://img.shields.io/github/issues/digitickets/terraform-aws-cli.svg?style=for-the-badge&logo=github)](https://github.com/digitickets/terraform-aws-cli/issues)

# terraform-aws-cli

Run the AWS CLI, with the ability to run under an assumed role, to access resources and properties missing from the
Terraform AWS Provider.

# Requirements

This module requires a couple of additional resources to operate successfully.

1. Amazon Web Service Command Line Interface (awscli)
   : This is available in several forms [here](https://aws.amazon.com/cli/).

2. JSON processor (jq)
   : This is available [here](https://stedolan.github.io/jq/).

# Examples

## 1. Get the desired capacity of an autoscaling group.

If you are using a blue/green style deployment, you would want to create the same number of EC2 instances as you are
replacing.

```hcl-terraform
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

## 2. Assuming a role.

Extending the first example above, assuming a role is as simple as adding an `assume_role_arn` to the module:

```hcl-terraform
module "current_desired_capacity" {
  source            = "digitickets/cli/aws"
  assume_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/OrganizationAccountAccessRole"
  role_session_name = "GettingDesiredCapacityFor${var.environment}"
  aws_cli_commands  = ["autoscaling", "describe-auto-scaling-groups"]
  aws_cli_query     = "AutoScalingGroups[?Tags[?Key==`Name`]|[?Value==`digitickets-${var.environment}-asg-app`]]|[0].DesiredCapacity"
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.15 |
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | 2.2.3 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.2.3 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [external_external.awscli_program](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [local_file.awscli_results_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assume_role_arn"></a> [assume\_role\_arn](#input\_assume\_role\_arn) | The ARN of the role being assumed (optional) | `string` | `""` | no |
| <a name="input_aws_cli_commands"></a> [aws\_cli\_commands](#input\_aws\_cli\_commands) | The AWS CLI command and subcommands | `list(string)` | n/a | yes |
| <a name="input_aws_cli_query"></a> [aws\_cli\_query](#input\_aws\_cli\_query) | The --query value | `string` | `""` | no |
| <a name="input_debug_log_filename"></a> [debug\_log\_filename](#input\_debug\_log\_filename) | Generate a debug log if a `debug_log_filename` is supplied | `string` | `""` | no |
| <a name="input_role_session_name"></a> [role\_session\_name](#input\_role\_session\_name) | The role session name | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_result"></a> [result](#output\_result) | The output of the AWS CLI command |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

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
