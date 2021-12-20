#!/usr/bin/env bash -e
rm -rf temp
rm -rf test-reports
find . -type f -name test.sh | sort | xargs -L 1 bash
