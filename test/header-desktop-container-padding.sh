#!/usr/bin/env bash
set -euo pipefail

css="assets/css/overrides/header.css"

if ! awk '
  BEGIN { status = 1 }
  /@media only screen and \(min-width: 800px\)/ { in_desktop = 1 }
  in_desktop && /^[[:space:]]*\.header \.container[[:space:]]*\{/ {
    in_rule = 1
    found_padding = 0
    next
  }
  in_rule && /padding:[[:space:]]*0;/ { found_padding = 1 }
  in_rule && /^[[:space:]]*\}/ {
    if (found_padding) {
      status = 0
    }
    exit
  }
  END { exit status }
' "$css"; then
  echo "Expected desktop header container to remove horizontal padding." >&2
  exit 1
fi
