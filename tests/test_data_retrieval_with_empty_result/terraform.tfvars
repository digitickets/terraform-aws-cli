// An empty result from AWS
aws_cli_commands = [
  "guardduty",
  "update-detector",
  "--finding-publishing-frequency",
  "ONE_HOUR",
  "--detector-id=01234567890123456789012345678901"
]
role_session_name = "empty_result"

alternative_path = "test-reports/test_data_retrieval_with_empty_result/aws"
