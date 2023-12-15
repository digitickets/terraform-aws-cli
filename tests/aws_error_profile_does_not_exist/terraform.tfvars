aws_cli_commands = ["s3api", "list-objects", "--bucket=ryft-public-sample-data", "--no-sign-request"]
aws_cli_query    = "max_by(Contents, &Size)"
profile          = "non-existent-profile"

alternative_path = "test-reports/aws_error_profile_does_not_exist/aws"
