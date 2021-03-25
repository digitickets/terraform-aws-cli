#!/usr/bin/env bash

set -e

mkdir -p test-reports

tests/bad_arn/test.sh
tests/test_with_debug/test.sh
tests/test_without_debug/test.sh
