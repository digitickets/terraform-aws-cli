<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
# Table of contents

- [CHANGELOG](#changelog)
  - [8.0.0 - 2026-11-24](#800---2026-11-24)
    - [Security improvements](#security-improvements)
    - [BREAKING CHANGES](#breaking-changes)
- [Previous versions](#previous-versions)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# CHANGELOG

## 8.0.0 - 2026-11-24
- Split into two modules, with the root module kept as a backwards-compatible alias of `modules/cli-read`:
  - `modules/cli-read`: read-only queries, run at plan and apply time (the existing behaviour, hardened).
  - `modules/cli-exec`: NEW. Mutating commands, run at apply time only, via `terraform_data` and `local-exec`, with
    `commands`, `assume_role`, `region`, `triggers`, `show_output`, `ignore_error_codes` and
    `for_each_item_commands` (run a command once per item returned by a read-only list command).
- The AWS CLI result is returned in-band, so the `hashicorp/local` provider and the results file are no longer used.
- Replaced the test suite with offline tests (`tests/run.sh`) using a fake `aws`: `terraform test` for each module,
  script-level tests, shellcheck, `terraform fmt` and `terraform validate`. CI runs them on Terraform 1.6 to 1.17.
- Updated to lastest GitHub Actions
- Restore minimum supported version of Terraform to v1.6.
- From inf-base: Update Terraform, TFLint, and Pre-commit.

### Security improvements
- Removed `eval`. Inputs are passed to the scripts as JSON and every argument is passed to the AWS CLI literally,
  closing shell injection through `aws_cli_commands`, `aws_cli_query` and `assume_role_arn`.
- Assumed-role credentials are never written to disk. Previously `aws_sts.json`, and the `--debug` log of the
  `sts assume-role` call, both contained the temporary credentials, and were left behind whenever a call failed.
- Once a role is assumed, neither `profile`, `AWS_PROFILE` nor `--profile` can override its credentials.
- cli-read only allows read-only operations (`describe-*`, `list-*`, `get-*`, `batch-get-*`, and an allowlist of
  reviewed `check-*` operations such as `wafv2 check-capacity`) and blocks, by default, operations that return secrets
  or credentials.
  - `license-manager check-in-license` (mutating), and `lightsail check-subdomain-availability` with `--reserve`, are
    always rejected;
  - `route53domains check-domain-transferability` is denylisted because its `--auth-code` would be stored in state.
- Each denylist error names the equivalent AWS provider block. Added `allow_denylisted_operations` and
  `additional_denied_operations`.
- Temporary files are private (`umask 077`, `mktemp -d`) and removed on every exit path. Debug logging is opt-in through
  the new `debug_log_dir` input and never records credentials or results.

### BREAKING CHANGES
- Values in `aws_cli_commands` must no longer be wrapped in extra quotes.
- Mutating operations, commands without a `<service> <operation>` (e.g. `--version`), denylisted operations, and
  `--profile`, `--debug` and `--endpoint-url` in `aws_cli_commands` are rejected.
- `alternative_path` is deprecated and ignored; `MODULE_TERRAFORM_AWS_CLI_RETAIN_LOGS` has no effect.
- The scripts require `bash` (3.2 or later).

---

# Previous versions
- [v7.x](https://github.com/digitickets/terraform-aws-cli/blob/v7.x/CHANGELOG.md)
- [v6.x](https://github.com/digitickets/terraform-aws-cli/blob/v6.x/CHANGELOG.md)
- [v5.x](https://github.com/digitickets/terraform-aws-cli/blob/v5.x/CHANGELOG.md)
- [v4.x](https://github.com/digitickets/terraform-aws-cli/blob/v4.x/CHANGELOG.md)
- [v3.x](https://github.com/digitickets/terraform-aws-cli/blob/v3.x/CHANGELOG.md)
- [v2.x](https://github.com/digitickets/terraform-aws-cli/blob/v2.x/CHANGELOG.md)
- [v1.x](https://github.com/digitickets/terraform-aws-cli/blob/v1.x/CHANGELOG.md)
