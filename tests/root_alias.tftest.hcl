# The root module is a backwards-compatible alias of modules/cli-read. Run via tests/run.sh (fake `aws` on PATH).

run "root_module_passes_inputs_through_to_cli_read" {
  command = plan

  variables {
    aws_cli_commands = ["autoscaling", "describe-auto-scaling-groups"]
    aws_cli_query    = "AutoScalingGroups[0].DesiredCapacity"
    region           = "eu-west-1"
  }

  assert {
    condition     = output.result.argv == ["autoscaling", "describe-auto-scaling-groups", "--region", "eu-west-1", "--query", "AutoScalingGroups[0].DesiredCapacity", "--output", "json"]
    error_message = "The root module must pass its inputs through to modules/cli-read and return its result."
  }

  assert {
    condition     = output.result_was_decoded && jsondecode(output.result_raw).argv[0] == "autoscaling"
    error_message = "The root module must return result_raw and result_was_decoded from modules/cli-read."
  }
}
