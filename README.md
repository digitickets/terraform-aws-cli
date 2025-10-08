[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/digitickets/terraform-aws-cli/build.yml?style=for-the-badge&logo=github)](https://github.com/digitickets/terraform-aws-cli/actions/workflows/build.yml)
[![GitHub issues](https://img.shields.io/github/issues/digitickets/terraform-aws-cli.svg?style=for-the-badge&logo=github)](https://github.com/digitickets/terraform-aws-cli/issues)

# terraform-aws-cli

Run the AWS CLI, with the ability to run under an assumed role, to access resources and properties missing from the
Terraform AWS Provider.

# Additional requirements

This module requires a couple of additional tools to operate successfully.

1. Amazon Web Service Command Line Interface (`aws`)
   : This is available in several forms [here](https://aws.amazon.com/cli/).
   As the awscli tool gets updated regularly, any version 2 should be usable, but please try to keep as uptodate as the
   functionality included in later versions may be what you need when using this module. If you are not getting the
   functionality you require, please read the
   [AWS CLI V2 Changelog](https://raw.githubusercontent.com/aws/aws-cli/v2/CHANGELOG.rst) to see if you are just needing
   to upgrade.

2. JSON processor (`jq`)
   : This is available [here](https://stedolan.github.io/jq/).
   At least version `jq-1.5` is required but has been tested and actively used with `jq-1.6`.

# Examples

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

## 2. Assuming a role.

Extending the first example above, assuming a role is as simple as adding an `assume_role_arn` to the module:

```hcl
module "current_desired_capacity" {
  source            = "digitickets/cli/aws"
  assume_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/OrganizationAccountAccessRole"
  role_session_name = "GettingDesiredCapacityFor${var.environment}"
  aws_cli_commands  = ["autoscaling", "describe-auto-scaling-groups"]
  aws_cli_query     = "AutoScalingGroups[?Tags[?Key==`Name`]|[?Value==`digitickets-${var.environment}-asg-app`]]|[0].DesiredCapacity"
}
```

## 3. Adding your own profile.

Extending the example above, you can supply your own profile by adding a `profile` to the module:

```hcl
module "current_desired_capacity" {
   source            = "digitickets/cli/aws"
   assume_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/OrganizationAccountAccessRole"
   role_session_name = "GettingDesiredCapacityFor${var.environment}"
   aws_cli_commands  = ["autoscaling", "describe-auto-scaling-groups"]
   aws_cli_query     = "AutoScalingGroups[?Tags[?Key==`Name`]|[?Value==`digitickets-${var.environment}-asg-app`]]|[0].DesiredCapacity"
   profile           = "your-own-profile"
}
```

## 4. Adding your external ID.

Extending the example above, you can supply your own external ID by adding an `external_id` to the module:

```hcl
module "current_desired_capacity" {
  source            = "digitickets/cli/aws"
  assume_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/OrganizationAccountAccessRole"
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
  assume_role_arn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/OrganizationAccountAccessRole"
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

# Warning

This module uses Terraform's `external` provider to allow an `external` data source to be used to call the AWS CLI tool,
and retrieve information not yet available via the AWS Terraform Provider.

As per the warnings [here](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external),
the `external` data source, and as a consequence, this module, it is expected that this module is used with caution.

This module is _NOT_ a replacement for the AWS Terraform Provider.

As per the last paragraph of the warnings from the official documentation regarding the `external` data source...

  "Terraform expects a data source to have _no observable side-effects_,
   and will re-run the program each time the state is refreshed."

If you use this module to perform destructive changes to your AWS environment, then they will be triggered each time a
Terraform plan and apply are run.

# Terraform requirements, providers, resources, etc.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | 2.3.5 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.5.3 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [external_external.awscli_program](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [local_file.awscli_results_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required | Validation |
|------|-------------|------|---------|:--------:|------------|
| <a name="input_alternative_path"></a> [alternative\_path](#input\_alternative\_path) | Use an alternative path for all files produced internally | `string` | `""` | no | None |
| <a name="input_assume_role_arn"></a> [assume\_role\_arn](#input\_assume\_role\_arn) | The ARN of the role being assumed (optional).<br/><br/>  The optional ARN must match the format documented in https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html. | `string` | `""` | no | The optional ARN must match the format documented in https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html. |
| <a name="input_aws_cli_commands"></a> [aws\_cli\_commands](#input\_aws\_cli\_commands) | The AWS CLI command, subcommands, and options.<br/><br/>  For options that can accept a value, then the following examples are both fine to use:<br/>  1. `"--option", "value"`<br/>  2. `"--option=value"`<br/><br/>  In the event that the value contains a space, it must be wrapped with quotes.<br/>  1. `"--option", "'value with a space wrapped in single quotes'"`<br/>  2. `"--option='value with a space wrapped in single quotes'"` | `list(string)` | n/a | yes | The `var.aws_cli_commands` cannot be empty. |
| <a name="input_aws_cli_query"></a> [aws\_cli\_query](#input\_aws\_cli\_query) | The `--query` value for the AWS CLI call.<br/><br/>  The value for `var.aws_cli_query` is based upon JMESPath, and you can get good information from https://jmespath.org.<br/>  If not supplied, then the entire results from the AWS CLI call will be returned. | `string` | `""` | no | None |
| <a name="input_external_id"></a> [external\_id](#input\_external\_id) | External id for assuming the role (optional).<br/><br/>  The length of optional external\_id, when supplied, must be between 2 and 1224 characters.<br/>  The optional external\_id can only contain upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: `=,.@-`.<br/>  The optional external\_id match the regular expression `^[\w=,.@-]*$`. | `string` | `""` | no | The length of optional external\_id, when supplied, must be between 2 and 1224 characters.<br>The optional external\_id must match the regular expression '^[\w=,.@-]*$'. |
| <a name="input_profile"></a> [profile](#input\_profile) | The specific AWS profile to use (must be configured appropriately and is optional).<br/><br/>  The optional profile must start with a letter and can only contain letters, numbers, hyphens, and underscores. | `string` | `""` | no | The optional profile must start with a letter and can only contain letters, numbers, hyphens, and underscores. |
| <a name="input_region"></a> [region](#input\_region) | The specific AWS region to use.<br/><br/>  The region must start with two letters representing the geographical area, followed by one or more letters or digits representing the specific region within that area. | `string` | `""` | no | The optional region must start with two letters representing the geographical area, followed by one or more letters or digits representing the specific region within that area. |
| <a name="input_retries"></a> [retries](#input\_retries) | Configuration for retries when making AWS CLI calls.<br/><br/>  The `max_attempts` specifies a value of maximum retry attempts the AWS CLI retry handler uses, where the initial call<br/>  counts toward the value that you provide.<br/>  The `mode` can be one of the following:<br/>    - `legacy`: Uses the legacy retry mode.<br/>    - `standard`: Uses the standard retry mode.<br/>    - `adaptive`: Experimental retry mode that includes all the features of standard mode. In addition to the standard<br/>  mode features, adaptive mode also introduces client-side rate limiting through the use of a token bucket and<br/>  rate-limit variables that are dynamically updated with each retry attempt.<br/><br/>  More information about retry modes can be found in the AWS documentation:<br/>  https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-retries.html | <pre>object({<br/>    max_attempts = optional(number, 4)<br/>    mode         = optional(string, "adaptive")<br/>  })</pre> | `{}` | no | The retries mode must be one of 'legacy', 'standard', or 'adaptive'. |
| <a name="input_role_session_name"></a> [role\_session\_name](#input\_role\_session\_name) | The role session name that will be used when assuming a role (optional)<br/><br/>  The length of the optional role session name, when supplied, must be between 2 and 64 characters.<br/>  The optional role session name can only contain upper- and lower-case alphanumeric characters with no spaces. You can also include underscores or any of the following characters: `=,.@-`.<br/>  The optional role session name match the regular expression `^[\w=,.@-]*$`.<br/><br/>  If the assume\_role\_arn is supplied, but the role\_session\_name is left empty, an internal default of "AssumingRole" will be used. | `string` | `""` | no | The length of the optional role session name, when supplied, must be between 2 and 64 characters.<br>The role session name match the regular expression '^[\w=,.@-]*$'. |

## Outputs

| Name | Description |
|------|-------------|
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
