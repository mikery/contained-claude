#!/usr/bin/env bash
set -euo pipefail
common_dir="$(git rev-parse --path-format=absolute --git-common-dir)"
if [ "$(basename "$common_dir")" = ".git" ]; then
  dirname "$common_dir"
else
  dirname "$(dirname "$common_dir")"
fi
