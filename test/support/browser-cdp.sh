#!/usr/bin/env bash

browser_cdp_repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

browser_cdp_find_chrome() {
  if [[ -n "${BROWSER_TEST_CHROME_BIN:-}" ]]; then
    printf '%s\n' "$BROWSER_TEST_CHROME_BIN"
    return
  fi

  if [[ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]]; then
    printf '%s\n' "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    return
  fi

  if command -v google-chrome >/dev/null 2>&1; then
    command -v google-chrome
    return
  fi

  if command -v chromium >/dev/null 2>&1; then
    command -v chromium
    return
  fi

  if command -v chromium-browser >/dev/null 2>&1; then
    command -v chromium-browser
    return
  fi
}

browser_cdp_cleanup() {
  if [[ -n "${browser_cdp_site_pid:-}" ]]; then
    kill "$browser_cdp_site_pid" >/dev/null 2>&1 || true
    wait "$browser_cdp_site_pid" 2>/dev/null || true
  fi

  if [[ -n "${browser_cdp_chrome_pid:-}" ]]; then
    kill "$browser_cdp_chrome_pid" >/dev/null 2>&1 || true
    wait "$browser_cdp_chrome_pid" 2>/dev/null || true
  fi

  if [[ -n "${browser_cdp_chrome_tmp:-}" ]]; then
    rm -rf "$browser_cdp_chrome_tmp"
  fi
}

browser_cdp_wait_for_url() {
  local url="$1"
  local label="$2"

  for _ in $(seq 1 120); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.1
  done

  echo "Timed out waiting for $label at $url." >&2
  return 1
}

browser_cdp_setup() {
  browser_cdp_test_name="$1"
  site_port="$2"
  chrome_port="$3"
  local wait_path="${4:-/}"

  browser_cdp_build_log="/tmp/${browser_cdp_test_name}-jekyll.log"
  browser_cdp_site_log="/tmp/${browser_cdp_test_name}-site.log"
  browser_cdp_chrome_log="/tmp/${browser_cdp_test_name}-chrome.log"
  browser_cdp_chrome_tmp="$(mktemp -d)"

  trap browser_cdp_cleanup EXIT

  if [[ "${BROWSER_CDP_SKIP_BUILD:-0}" != "1" && "${TEST_SKIP_JEKYLL_BUILD:-0}" != "1" ]]; then
    bundle exec jekyll build >"$browser_cdp_build_log"
  fi

  ruby -run -e httpd _site -p "$site_port" >"$browser_cdp_site_log" 2>&1 &
  browser_cdp_site_pid=$!

  if ! browser_cdp_wait_for_url "http://127.0.0.1:${site_port}${wait_path}" "test site"; then
    sed -n '1,160p' "$browser_cdp_site_log" >&2 || true
    exit 1
  fi

  local chrome_bin
  chrome_bin="$(browser_cdp_find_chrome || true)"

  if [[ -z "$chrome_bin" || ! -x "$chrome_bin" ]]; then
    echo "Chrome executable not found. Set BROWSER_TEST_CHROME_BIN to run browser tests." >&2
    exit 1
  fi

  "$chrome_bin" \
    --headless=new \
    --disable-gpu \
    --disable-dev-shm-usage \
    --hide-scrollbars \
    --no-first-run \
    --remote-allow-origins='*' \
    --remote-debugging-port="$chrome_port" \
    --user-data-dir="$browser_cdp_chrome_tmp" \
    about:blank >"$browser_cdp_chrome_log" 2>&1 &
  browser_cdp_chrome_pid=$!

  if ! browser_cdp_wait_for_url "http://127.0.0.1:${chrome_port}/json/version" "Chrome debugging port"; then
    sed -n '1,160p' "$browser_cdp_chrome_log" >&2 || true
    exit 1
  fi
}

browser_cdp_node() {
  local script_file
  script_file="$(mktemp "${TMPDIR:-/tmp}/browser-cdp-script.XXXXXX.mjs")"
  cat >"$script_file"

  BROWSER_CDP_SCRIPT="$script_file" \
  BROWSER_CDP_SITE_PORT="$site_port" \
  BROWSER_CDP_CHROME_PORT="$chrome_port" \
  BROWSER_CDP_REPO_ROOT="$browser_cdp_repo_root" \
    node --input-type=module <<'NODE'
import { pathToFileURL } from "node:url";
import { createCdpClient, delay, waitReady } from "./test/support/cdp-client.mjs";

const client = await createCdpClient(process.env.BROWSER_CDP_CHROME_PORT);

globalThis.browserCdp = {
  chromePort: process.env.BROWSER_CDP_CHROME_PORT,
  closeBrowser: client.closeBrowser,
  delay,
  send: client.send,
  sitePort: process.env.BROWSER_CDP_SITE_PORT,
  waitReady: () => waitReady(client.send),
};

try {
  await import(pathToFileURL(process.env.BROWSER_CDP_SCRIPT).href);
} finally {
  await client.closeBrowser();
}
NODE

  rm -f "$script_file"
}
