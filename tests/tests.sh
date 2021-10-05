#!/usr/bin/env bash

set -e

mkdir -p test-reports

tests/bad_arn/test.sh
tests/role_session_name_invalid_characters/test.sh
tests/role_session_name_too_long/test.sh
tests/test_with_debug/test.sh
tests/test_without_debug/test.sh
