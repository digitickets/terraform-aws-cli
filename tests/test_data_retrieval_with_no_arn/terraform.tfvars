aws_cli_commands = ["s3api", "list-objects", "--bucket=ryft-public-sample-data", "--no-sign-request"]
aws_cli_query    = "max_by(Contents, &Size)"
region           = "eu-west-1"

alternative_path = "test-reports/test_data_retrieval_with_no_arn/aws"
