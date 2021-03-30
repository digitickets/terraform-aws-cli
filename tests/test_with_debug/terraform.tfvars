// ryft-public-sample-data is a publicly accessible S3 bucket.
aws_cli_commands   = ["s3api", "list-objects", "--bucket", "ryft-public-sample-data", "--no-sign-request"]
aws_cli_query      = "max_by(Contents, &Size)"
debug_log_filename = "test-reports/test_with_debug.debug.log"
