#!/usr/bin/env bash
set -euo pipefail

shell_helper="test/support/browser-cdp.sh"
node_helper="test/support/cdp-client.mjs"

if [[ ! -f "$shell_helper" ]]; then
  echo "Expected shared browser shell helper at $shell_helper." >&2
  exit 1
fi

if [[ ! -f "$node_helper" ]]; then
  echo "Expected shared CDP client helper at $node_helper." >&2
  exit 1
fi

for expected in \
  "browser_cdp_setup()" \
  "browser_cdp_node()" \
  "BROWSER_TEST_CHROME_BIN"; do
  if ! grep -q -- "$expected" "$shell_helper"; then
    echo "Expected browser shell helper to include '$expected'." >&2
    exit 1
  fi
done

for expected in \
  "export async function createCdpClient" \
  "export async function waitReady" \
  "new WebSocket"; do
  if ! grep -q -- "$expected" "$node_helper"; then
    echo "Expected CDP client helper to include '$expected'." >&2
    exit 1
  fi
done

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

for browser_test in "${browser_tests[@]}"; do
  if ! grep -q 'source ".*support/browser-cdp.sh"' "$browser_test"; then
    echo "Expected $browser_test to source the shared browser helper." >&2
    exit 1
  fi

  if ! grep -q 'browser_cdp_setup' "$browser_test"; then
    echo "Expected $browser_test to use browser_cdp_setup." >&2
    exit 1
  fi

  if ! grep -q 'browser_cdp_node' "$browser_test"; then
    echo "Expected $browser_test to use browser_cdp_node." >&2
    exit 1
  fi
done

if grep -RIn -- 'Google Chrome.app\|remote-debugging-port\|ruby -run -e httpd\|new WebSocket\|function send(method' "${browser_tests[@]}"; then
  echo "Expected browser tests to avoid duplicated Chrome/CDP harness code." >&2
  exit 1
fi
