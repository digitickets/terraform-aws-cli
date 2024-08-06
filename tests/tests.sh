#!/usr/bin/env bash

function underline() {
  U="${1//?/${2:--}}"
  echo -e "\n$1\n${U:0:${#1}}\n"
}

set -e
rm -rf temp
rm -rf test-reports

underline 'Running tests' =

find ./tests -type f -name test.sh -maxdepth 2 | sort | xargs -L 1 bash
