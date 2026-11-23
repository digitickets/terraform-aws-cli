# The root module is a backwards-compatible alias of `modules/cli-read`.
#
# All inputs are passed through unchanged and validated by the submodule. New consumers can reference the submodules
# directly:
#   - `digitickets/cli/aws//modules/cli-read` for read-only queries that run at plan and apply.
#   - `digitickets/cli/aws//modules/cli-exec` for mutating commands that run at apply only.
module "cli_read" {
  source = "./modules/cli-read"

  alternative_path        = var.alternative_path
  assume_role_arn         = var.assume_role_arn
  aws_cli_commands        = var.aws_cli_commands
  aws_cli_query           = var.aws_cli_query
  debug_log_dir           = var.debug_log_dir
  external_id             = var.external_id
  profile                 = var.profile
  region                  = var.region
  retries                 = var.retries
  role_session_name       = var.role_session_name
  suppress_error_handling = var.suppress_error_handling
}
