[![Build Status](https://img.shields.io/travis/digitickets/terraform-aws-cli.svg?style=for-the-badge&logo=travis)](https://travis-ci.org/digitickets/terraform-aws-cli)
[![GitHub issues](https://img.shields.io/github/issues/digitickets/terraform-aws-cli.svg?style=for-the-badge&logo=github)](https://github.com/digitickets/terraform-aws-cli/issues)

# terraform-aws-cli

Run the AWS CLI, with the ability to run under an assumed role, to access resources and properties missing from the
Terraform AWS Provider.

# Requirements

This module requires a couple of additional resources to operate successfully.

1. Amazon Web Service Command Line Interface (awscli)  
   This is available in several forms [here](https://aws.amazon.com/cli/).

2. JSON processor (jq)  
   This is available [here](https://stedolan.github.io/jq/).

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
| terraform | ~> 0.13.0 |
| external | ~> 1.2.0 |
| local | ~> 1.4.0 |
| random | ~> 2.3.0 |

## Providers

| Name | Version |
|------|---------|
| external | ~> 1.2.0 |
| local | ~> 1.4.0 |
| random | ~> 2.3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| assume\_role\_arn | The ARN of the role being assumed (optional) | `string` | `""` | no |
| aws\_cli\_commands | The AWS CLI command and subcommands | `list(string)` | n/a | yes |
| aws\_cli\_query | The --query value | `string` | `""` | no |
| role\_session\_name | The role session name (optional) | `string` | `"terraform-aws-cli"` | no |

## Outputs

| Name | Description |
|------|-------------|
| result | The output of the AWS CLI command |

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

