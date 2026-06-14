#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/support/browser-cdp.sh"

browser_cdp_setup "dark-mode-text-selection" "${DARK_MODE_SELECTION_SITE_PORT:-4117}" "${DARK_MODE_SELECTION_CHROME_PORT:-9235}" "/blog/feet-on-street-app/"

browser_cdp_node <<'NODE'
const { sitePort, send, waitReady, delay } = globalThis.browserCdp;

await send("Emulation.setDeviceMetricsOverride", {
  width: 1280,
  height: 900,
  deviceScaleFactor: 1,
  mobile: false,
});
await send("Page.navigate", { url: `http://127.0.0.1:${sitePort}/blog/feet-on-street-app/` });
await waitReady();

const result = await send("Runtime.evaluate", {
  expression: `(() => {
    const sample = document.querySelector(".post p");
    if (!sample) return { found: false };
    const lightSelection = getComputedStyle(sample, "::selection");
    const lightBackground = lightSelection.backgroundColor;
    const lightColor = lightSelection.color;
    document.documentElement.classList.add("theme-dark");
    const darkSelection = getComputedStyle(sample, "::selection");
    return {
      found: true,
      lightBackground,
      lightColor,
      darkBackground: darkSelection.backgroundColor,
      darkColor: darkSelection.color,
      sampleText: sample.textContent.trim()
    };
  })()`,
  returnByValue: true,
});
await send("Browser.close").catch(() => {});

const actual = result.result.value;
if (!actual.found) {
  throw new Error("Expected sample post text to exist.");
}

const expectedLightBackground = "rgb(0, 0, 0)";
const expectedLightColor = "rgb(255, 255, 255)";
const expectedDarkBackground = "rgb(255, 255, 255)";
const expectedDarkColor = "rgb(0, 0, 0)";

for (const [name, expected] of Object.entries({
  lightBackground: expectedLightBackground,
  lightColor: expectedLightColor,
  darkBackground: expectedDarkBackground,
  darkColor: expectedDarkColor,
})) {
  if (actual[name] !== expected) {
    throw new Error(`Expected ${name} ${expected}, got ${actual[name]}.`);
  }
}

console.log(JSON.stringify(actual, null, 2));
NODE

if ! grep -q -- '--selection-bg: #fff;' assets/css/overrides/tokens.css; then
  echo "Expected dark-mode selection background token to be white." >&2
  exit 1
fi

if ! grep -q -- '--selection-color: #000;' assets/css/overrides/tokens.css; then
  echo "Expected dark-mode selection text token to be black." >&2
  exit 1
fi
