# Mutating commands, run at apply time only, and only again when their inputs or triggers change.
module "log_retention" {
  source = "../../modules/cli-exec"

  assume_role = {
    arn          = var.deployer_role_arn
    session_name = "SettingLogRetention"
  }
  region = "eu-west-2"

  commands = [
    ["logs", "create-log-group", "--log-group-name", var.log_group_name],
    ["logs", "put-retention-policy", "--log-group-name", var.log_group_name, "--retention-in-days", tostring(var.retention_in_days)],
  ]

  # Rerunning `create-log-group` for a group that already exists is not an error.
  ignore_error_codes = ["ResourceAlreadyExistsException"]

  # Act on each item returned by a read-only list command.
  for_each_item_commands = [
    {
      list    = ["logs", "describe-log-groups", "--log-group-name-prefix", "/app/"]
      query   = "logGroups[?retentionInDays == null].logGroupName"
      command = ["logs", "put-retention-policy", "--log-group-name", "{{item}}", "--retention-in-days", tostring(var.retention_in_days)]
    },
  ]

  triggers = {
    # Rerun on demand by changing this value.
    revision = "1"
  }
}
