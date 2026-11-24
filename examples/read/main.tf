# Read-only query, evaluated at plan and apply time. The plan identity only needs read permissions.
module "current_desired_capacity" {
  source = "../../modules/cli-read"

  assume_role_arn   = var.reader_role_arn
  role_session_name = "GettingDesiredCapacity"
  aws_cli_commands  = ["autoscaling", "describe-auto-scaling-groups", "--auto-scaling-group-names", var.auto_scaling_group_name]
  aws_cli_query     = "AutoScalingGroups[0].DesiredCapacity"
}
