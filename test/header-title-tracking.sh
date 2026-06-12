#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/support/browser-cdp.sh"

browser_cdp_setup "header-title-tracking" "${HEADER_TITLE_TEST_PORT:-4109}" "${HEADER_TITLE_CHROME_PORT:-9229}" "/"

browser_cdp_node <<'NODE'
const { sitePort, send, waitReady, delay } = globalThis.browserCdp;

await send("Emulation.setDeviceMetricsOverride", {
  width: 1280,
  height: 900,
  deviceScaleFactor: 1,
  mobile: false,
});
await send("Page.navigate", { url: `http://127.0.0.1:${sitePort}/` });
await waitReady();

const result = await send("Runtime.evaluate", {
  expression: `(() => {
    const title = document.querySelector(".header .logo a");
    if (!title) return { found: false };
    return {
      found: true,
      text: title.textContent.trim(),
      letterSpacing: getComputedStyle(title).letterSpacing
    };
  })()`,
  returnByValue: true,
});
await send("Browser.close").catch(() => {});

const actual = result.result.value;
if (!actual.found) {
  throw new Error("Expected header title link to exist.");
}

if (actual.text !== "Akash Soti") {
  throw new Error(`Expected header title text to be Akash Soti, got ${actual.text}.`);
}

if (actual.letterSpacing !== "-1px") {
  throw new Error(`Expected header title tracking -1px, got ${actual.letterSpacing}.`);
}

console.log(JSON.stringify(actual, null, 2));
NODE
