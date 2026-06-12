#!/usr/bin/env bash
set -euo pipefail

browser_tests=(
  test/case-study-section-nav-browser.sh
  test/dark-mode-blockquote.sh
  test/dark-mode-card-color.sh
  test/dark-mode-header-banner.sh
  test/dark-mode-post-subtitle.sh
  test/dark-mode-text-selection.sh
  test/dark-mode-theme-toggle-selected-style.sh
  test/header-title-tracking.sh
  test/light-mode-card-hover-shadow.sh
)

bundle exec jekyll build >/tmp/browser-suite-jekyll.log

export BROWSER_CDP_SKIP_BUILD=1

for test_script in "${browser_tests[@]}"; do
  printf '==> %s\n' "$test_script"
  bash "$test_script"
done
