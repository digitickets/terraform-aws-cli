# Run via tests/run.sh, which puts the fake `aws` (tests/stubs/aws) first on PATH and points FAKE_AWS_LOG at
# `.fake_aws.log` in this module's directory. Every fake `aws` invocation is appended to that log, one JSON line each, so
# these assertions can prove exactly when commands were (and were not) run. Each run uses a unique marker argument.
#
# Terraform requires every assertion to refer to an object in the configuration, so the log assertions start with
# `var.region == "eu-west-2"`, which is always true.

variables {
  region = "eu-west-2"
}

run "plan_does_not_run_any_command" {
  command = plan

  variables {
    commands = [["ec2", "create-tags", "--marker=plan-only"]]
  }

  assert {
    condition     = var.region == "eu-west-2" && !strcontains(fileexists(".fake_aws.log") ? file(".fake_aws.log") : "", "--marker=plan-only")
    error_message = "The AWS CLI was invoked during plan."
  }
}

run "apply_runs_the_commands_once_in_order" {
  variables {
    commands = [
      ["ec2", "create-tags", "--marker=apply-first"],
      ["ec2", "create-tags", "--marker=apply-second"],
    ]
    triggers = { version = "1" }
  }

  assert {
    condition     = var.region == "eu-west-2" && length(regexall("--marker=apply-first", file(".fake_aws.log"))) == 1 && length(regexall("--marker=apply-second", file(".fake_aws.log"))) == 1
    error_message = "Each command must run exactly once on the first apply."
  }

  assert {
    condition     = var.region == "eu-west-2" && strcontains(file(".fake_aws.log"), "--marker=apply-first\"],\"access_key_id\":\"\"")
    error_message = "Without assume_role, the ambient credentials must be used."
  }

  assert {
    condition     = var.region == "eu-west-2" && length(split("--marker=apply-first", file(".fake_aws.log"))[1]) > length(split("--marker=apply-second", file(".fake_aws.log"))[1])
    error_message = "Commands must run in the order given."
  }
}

run "reapply_with_unchanged_inputs_does_not_rerun" {
  variables {
    commands = [
      ["ec2", "create-tags", "--marker=apply-first"],
      ["ec2", "create-tags", "--marker=apply-second"],
    ]
    triggers = { version = "1" }
  }

  assert {
    condition     = var.region == "eu-west-2" && length(regexall("--marker=apply-first", file(".fake_aws.log"))) == 1
    error_message = "The commands must not rerun when nothing has changed."
  }
}

run "reapply_with_changed_triggers_reruns" {
  variables {
    commands = [
      ["ec2", "create-tags", "--marker=apply-first"],
      ["ec2", "create-tags", "--marker=apply-second"],
    ]
    triggers = { version = "2" }
  }

  assert {
    condition     = var.region == "eu-west-2" && length(regexall("--marker=apply-first", file(".fake_aws.log"))) == 2 && length(regexall("--marker=apply-second", file(".fake_aws.log"))) == 2
    error_message = "The commands must rerun when the triggers change."
  }
}

run "reapply_with_changed_commands_reruns" {
  variables {
    commands = [["ec2", "create-tags", "--marker=apply-changed"]]
    triggers = { version = "2" }
  }

  assert {
    condition     = var.region == "eu-west-2" && length(regexall("--marker=apply-changed", file(".fake_aws.log"))) == 1
    error_message = "The commands must rerun when the commands change."
  }
}

run "ignored_error_codes_are_treated_as_success" {
  variables {
    commands           = [["logs", "create-log-group", "--marker=ignored", "--fake-error=ResourceAlreadyExistsException"]]
    ignore_error_codes = ["ResourceAlreadyExistsException"]
  }

  assert {
    condition     = var.region == "eu-west-2" && length(regexall("--marker=ignored", file(".fake_aws.log"))) == 1
    error_message = "The command must have run, and its ignored error must not fail the apply."
  }
}

run "assume_role_credentials_are_used" {
  variables {
    commands    = [["ec2", "create-tags", "--marker=assumed"]]
    assume_role = { arn = "arn:aws:iam::111122223333:role/deployer", external_id = "ext-id-1" }
  }

  assert {
    condition     = var.region == "eu-west-2" && strcontains(file(".fake_aws.log"), "--external-id\",\"ext-id-1\",\"--region\",\"eu-west-2\"]")
    error_message = "The role must be assumed with the external id and region."
  }

  assert {
    condition     = var.region == "eu-west-2" && strcontains(file(".fake_aws.log"), "--marker=assumed\"],\"access_key_id\":\"ASIAFAKE111122223333\",\"aws_profile\":\"\"}")
    error_message = "The command must run with the assumed credentials, and no profile."
  }
}

run "for_each_item_runs_the_command_per_item" {
  variables {
    commands = []
    for_each_item_commands = [{
      list    = ["logs", "describe-log-groups", "--fake-output=[\"one\", \"two words\"]"]
      query   = "logGroups[].logGroupName"
      command = ["logs", "put-retention-policy", "--log-group-name", "per-item:{{item}}"]
    }]
  }

  assert {
    condition     = var.region == "eu-west-2" && strcontains(file(".fake_aws.log"), "\"per-item:one\"") && strcontains(file(".fake_aws.log"), "\"per-item:two words\"")
    error_message = "The command must run once for each listed item, with the item substituted literally."
  }

  assert {
    condition     = var.region == "eu-west-2" && strcontains(file(".fake_aws.log"), "\"--query\",\"logGroups[].logGroupName\",\"--output\",\"json\"]")
    error_message = "The list command must run with the query."
  }
}

run "nothing_to_run_is_rejected" {
  command = plan

  variables {
    commands = []
  }

  expect_failures = [terraform_data.aws_cli_exec]
}

run "profile_in_commands_is_rejected" {
  command = plan

  variables {
    commands = [["ec2", "create-tags", "--profile=other"]]
  }

  expect_failures = [var.commands]
}

run "debug_in_commands_is_rejected" {
  command = plan

  variables {
    commands = [["ec2", "create-tags", "--debug"]]
  }

  expect_failures = [var.commands]
}

run "mutating_list_command_is_rejected" {
  command = plan

  variables {
    for_each_item_commands = [{
      list    = ["logs", "delete-log-group"]
      query   = "x"
      command = ["logs", "x", "{{item}}"]
    }]
  }

  expect_failures = [var.for_each_item_commands]
}

run "per_item_command_without_placeholder_is_rejected" {
  command = plan

  variables {
    for_each_item_commands = [{
      list    = ["logs", "describe-log-groups"]
      query   = "x"
      command = ["logs", "delete-log-group"]
    }]
  }

  expect_failures = [var.for_each_item_commands]
}

run "invalid_role_arn_is_rejected" {
  command = plan

  variables {
    commands    = [["ec2", "create-tags"]]
    assume_role = { arn = "arn:aws:iam::123456789012:role/x;touch /tmp/pwned" }
  }

  expect_failures = [var.assume_role]
}
