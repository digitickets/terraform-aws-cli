<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
# Table of contents

- [CHANGELOG](#changelog)
  - [UNRELEASED](#unreleased)
  - [7.2.0 - 2026-03-09](#720---2026-03-09)
  - [7.1.4 - 2026-02-20](#714---2026-02-20)
  - [7.1.3 - 2026-02-20](#713---2026-02-20)
  - [7.1.2 - 2026-01-16](#712---2026-01-16)
  - [7.1.1 - 2025-10-08](#711---2025-10-08)
  - [7.1.0 - 2025-07-03](#710---2025-07-03)
  - [7.0.1 - 2025-04-28](#701---2025-04-28)
  - [7.0.0 - 2024-08-06](#700---2024-08-06)
- [Previous versions](#previous-versions)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# CHANGELOG

## UNRELEASED
- Handle error suppression setting in tests

## 7.2.0 - 2026-03-09
- Update to latest provider versions for testing and split versions in Changelog
- Added `var.suppress_error_handling` to allow errors to be bubble up to the caller.

## 7.1.4 - 2026-02-20
- Force push master in BitBucket pipeline

## 7.1.3 - 2026-02-20
- Normalised `CHANGELOG.md` headings to be `## tag - YYYY-MM-DD`.
- Prevent duplicated tags via pipeline.
- Automated merging of the latest major branch release to the master branch.
- Reinstate minimum Terraform version to be `~> 1.6`.
- Updated to the latest version for testing of Terraform `1.14` to `1.14.4`.
- Updated the versions used to testing for `1.13` and `1.14`.
- Updated Terraform and TFLint versions.
- Added TOC to README
- Moved doctoc to after terraform-docs

## 7.1.2 - 2026-01-16
- Improve Terraform Validation processing.
- Enforced module version pinning.
- Remove redundant shebang from `terraform-validation-support.sh` script.
- Fix creation of provider alias JSON file
- Improve script error handling
- Added v1.14.1 for testing.
- Standardised versions of Terraform and Terraform Providers
- Upgrade tflint to 0.60.0
- Dropping the `v` from the versions.

## 7.1.1 - 2025-10-08
- Added validation to `var.aws_cli_command` to stop an empty command being asked for. Slight improvement as this means
  the empty command is evaluated before it is passed to the AWS CLI.
- Updated to v1.11.4 for testing.
- Added v1.13.3 for testing.
- Remove `.terraform.lock.hcl` files from Terraform modules as it is not required.
- Ignore `.terraform.lock.hcl`.
- Ignore MacOS `.DS_Store` files.
- Upgraded Terraform, Providers, TFLint, and Pre-Commit versions.

## 7.1.0 - 2025-07-03
- Added v1.12.2 for testing
- Improved support for retrying, both in terms of the retry mode and the number of retries via the new `var.retries`
  variable. Thank you [Roma Ryzhyi](https://github.com/digitickets/terraform-aws-cli/pull/28).

## 7.0.1 - 2025-04-28
- Add v1.11.3, and reduced the number of builds to just the latest in the minor versions of Terraform from 1.6.0 onwards.
- Minor reorganization to match [Terraform Standard Module Structure](https://www.terraform.io/docs/modules/index.html#standard-module-structure).
- Small enhancement for TFLint when aliased providers are used.
- Added warning to README.md regarding destructive use. Thank you, [Yves Vogl](https://github.com/digitickets/terraform-aws-cli/issues/25).

## 7.0.0 - 2024-08-06
- Fix a typo in the description for the `var.external_id`.
- Fix handling of invalid JSON returned from the AWS CLI. Thank you, [홍수민 and horststumpf](https://github.com/digitickets/terraform-aws-cli/pull/19).
- Introduced 2 new outputs:
  - `output.result_raw = string` - This will contain the raw output from the AWS CLI call.
  - `output.result_was_decoded = bool` - This will indicate if the output from the AWS CLI call was successfully JSON decoded.

  These were introduced as some of the results from the AWS CLI are not JSON decodable.
  For example `aws ec2 create-tags` returns nothing.

# Previous versions
- [v6.x](https://github.com/digitickets/terraform-aws-cli/blob/v6.x/CHANGELOG.md)
- [v5.x](https://github.com/digitickets/terraform-aws-cli/blob/v5.x/CHANGELOG.md)
- [v4.x](https://github.com/digitickets/terraform-aws-cli/blob/v4.x/CHANGELOG.md)
- [v3.x](https://github.com/digitickets/terraform-aws-cli/blob/v3.x/CHANGELOG.md)
- [v2.x](https://github.com/digitickets/terraform-aws-cli/blob/v2.x/CHANGELOG.md)
- [v1.x](https://github.com/digitickets/terraform-aws-cli/blob/v1.x/CHANGELOG.md)
