<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
# Table of contents

- [CHANGELOG](#changelog)
  - [UNRELEASED](#unreleased)
  - [7.2.2 - 2026-09-10](#722---2026-09-10)
  - [7.2.1 - 2026-03-09](#721---2026-03-09)
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
This is a breaking release and should be tagged `8.0.0`. See "Upgrading from 7.x" in the README.

- Split into two modules, with the root module kept as a backwards-compatible alias of `modules/cli-read`:
  - `modules/cli-read`: read-only queries, run at plan and apply time (the existing behaviour, hardened).
  - `modules/cli-exec`: NEW. Mutating commands, run at apply time only, via `terraform_data` and `local-exec`, with
    `commands`, `assume_role`, `region`, `triggers`, `show_output`, `ignore_error_codes` and
    `for_each_item_commands` (run a command once per item returned by a read-only list command).
- SECURITY: Removed `eval`. Inputs are passed to the scripts as JSON and every argument is passed to the AWS CLI
  literally, closing shell injection through `aws_cli_commands`, `aws_cli_query` and `assume_role_arn`.
- SECURITY: Assumed-role credentials are never written to disk. Previously `aws_sts.json`, and the `--debug` log of the
  `sts assume-role` call, both contained the temporary credentials, and were left behind whenever a call failed.
- SECURITY: Once a role is assumed, neither `profile`, `AWS_PROFILE` nor `--profile` can override its credentials.
- SECURITY: cli-read only allows read-only operations (`describe-*`, `list-*`, `get-*`, `batch-get-*`, and an
  allowlist of reviewed `check-*` operations such as `wafv2 check-capacity`) and blocks, by default, operations that
  return secrets or credentials. `license-manager check-in-license` (mutating), and
  `lightsail check-subdomain-availability` with `--reserve`, are always rejected;
  `route53domains check-domain-transferability` is denylisted because its `--auth-code` would be stored in state.
  Each denylist error names the equivalent AWS provider block. Added `allow_denylisted_operations` and
  `additional_denied_operations`.
- SECURITY: Temporary files are private (`umask 077`, `mktemp -d`) and removed on every exit path. Debug logging is
  opt-in through the new `debug_log_dir` input and never records credentials or results.
- The AWS CLI result is returned in-band, so the `hashicorp/local` provider and the results file are no longer used.
- Replaced the test suite with offline tests (`tests/run.sh`) using a fake `aws`: `terraform test` for each module,
  script-level tests, shellcheck, `terraform fmt` and `terraform validate`. CI runs them on Terraform 1.6 to 1.17.
- BREAKING: Values in `aws_cli_commands` must no longer be wrapped in extra quotes.
- BREAKING: Mutating operations, commands without a `<service> <operation>` (e.g. `--version`), denylisted operations,
  and `--profile`, `--debug` and `--endpoint-url` in `aws_cli_commands` are rejected.
- BREAKING: `alternative_path` is deprecated and ignored; `MODULE_TERRAFORM_AWS_CLI_RETAIN_LOGS` has no effect.
- BREAKING: The scripts require `bash` (3.2 or later).
- Updated to lastest GitHub Actions
- From inf-base: Updated Terraform, TFLint, Pre-commit versions.
- From inf-base: Updated gitignore.
- Restore minimum supported version of Terraform to v1.6.
- From inf-base: 2026-11-05 - Terraform, TFLint, and Pre-Commit updates
- From inf-base: 2026-11-05 - Terraform, TFLint, and Pre-Commit updates

## 7.2.2 - 2026-09-10
- From inf-base: Update Terraform, TFLint, and Pre-commit.
- Added Terraform v1.16 to the test versions

## 7.2.1 - 2026-03-09
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
