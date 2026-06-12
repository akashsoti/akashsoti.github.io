#!/usr/bin/env bash
set -euo pipefail

run_suite() {
  local label="$1"
  local command="$2"

  printf '\n== %s ==\n' "$label"
  bash "$command"
}

run_suite "Static" "test/run-static.sh"
run_suite "Browser" "test/run-browser.sh"
