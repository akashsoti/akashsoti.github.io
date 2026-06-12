#!/usr/bin/env bash
set -euo pipefail

if ! grep -Eq '(^|/)vendor/bundle/?$' .gitignore; then
  echo "Expected .gitignore to ignore vendor/bundle." >&2
  exit 1
fi

if [ "$(git ls-files vendor/bundle | wc -l | tr -d ' ')" != "0" ]; then
  echo "Expected vendor/bundle to be untracked; it is a local dependency install." >&2
  exit 1
fi
