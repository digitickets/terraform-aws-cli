// ryft-public-sample-data is a publicly accessible S3 bucket.
aws_cli_commands   = ["s3api", "list-objects", "--bucket", "ryft-public-sample-data", "--no-sign-request"]
aws_cli_query      = "max_by(Contents, &Size)"
debug_log_filename = "test-reports/bad_region_with_debug/debug.log"
role_session_name  = "bad_region_with_debug"
region             = "US East (Ohio) us-east-2"
