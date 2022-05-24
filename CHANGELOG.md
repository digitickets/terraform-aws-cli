# Changelog

# v5.0.1 - 2022/05/24

- Explicitly specify output type as json for assume role call. Thank you [Niranjan Rajendran](https://github.com/digitickets/terraform-aws-cli/pull/2)

# v5.0.0 - 2022/01/27

- Fixed incompatibilities with Terraform 1.1.0.

# v4.1.0 - 2021/10/05

- Validate role_session_name so that the maximum length is 64 characters and that it must match a specific regex.

# v4.0.0 - 2021/05/18

- Set minimum terraform version to 0.15.0.

# No release required - 2021/03/30

- Updated tests to use an AWS request that does not require credentials, allowing the full terraform plan and apply
  process to be run and tested with the module.

# v3.1.1 - 2021/03/25

- Rereleasing as accidentally released v3.0.0 as v3.1.0.

# v3.1.0 - 2021/03/25

- Add an optional `debug_log_filename` variable. If supplied, a log file will be produced in the supplied location. This
  option enables the `--debug` option of the AWS CLI. Use this in safe environments as potentially sensitive content may
  be logged.
- Added [adaptive retry mode](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-retries.html#cli-usage-retries-modes-adaptive)
  to help alleviate throttling issues.

# v3.0.0 - 2020/12/03

- Set minimum terraform version to 0.14.0.
- Introduced `.terraform.lock.hcl` for versioning of dependencies.

# v2.0.1 - 2020/09/17

- Add `depends_on` to enforce the order in which the resources get instantiated / evaluated.

# v2.0.0 - 2020/09/17

- Set minimum terraform version to 0.13.0
- Added variable validation to optional `assume_role_arn` to match syntax described in
  [IAM Identifiers](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html).

# v1.3.0 - 2020/08/03

- Set minimum version of random provider to 2.3.0

# v1.2.2 - 2020/05/11

- Updated examples in [README.md](README.md).

# v1.2.1 - 2020/05/11

- Updated [README.md](README.md) to reflect `digiticketsgroup/terraforming` image that includes all the required
  resources for using this module.

# v1.2.0 - 2020/05/11

- Drop down to using `sh` rather than `bash` so this module can operate with Hashicorp Terraform Docker image.

# v1.1.0 - 2020/05/07

- Updated examples in README.md with registry path as displayed by registry.
- Updated `assume_role_arn` to reflect that it is optional.

# v1.0.0 - 2020/05/07
Initial release
