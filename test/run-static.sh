#!/usr/bin/env bash
set -euo pipefail

browser_tests='/(case-study-section-nav-browser|dark-mode-blockquote|dark-mode-card-color|dark-mode-header-banner|dark-mode-post-subtitle|dark-mode-text-selection|dark-mode-theme-toggle-selected-style|header-title-tracking|light-mode-card-hover-shadow)\.sh$'

static_tests=()
while IFS= read -r test_script; do
  static_tests+=("$test_script")
done < <(
  find test -maxdepth 1 -name '*.sh' -type f \
    | sort \
    | grep -Ev "$browser_tests" \
    | grep -Ev '/run-(all|static|browser)\.sh$'
)

for test_script in "${static_tests[@]}"; do
  printf '==> %s\n' "$test_script"
  bash "$test_script"
done
