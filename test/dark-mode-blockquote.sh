#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/support/browser-cdp.sh"

browser_cdp_setup "dark-mode-blockquote" "${DARK_MODE_BLOCKQUOTE_SITE_PORT:-4114}" "${DARK_MODE_BLOCKQUOTE_CHROME_PORT:-9234}" "/blog/feet-on-street-app/"

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
    document.documentElement.classList.add("theme-dark");
    const blockquote = document.querySelector(".post blockquote");
    const strong = blockquote ? blockquote.querySelector("strong") : null;
    if (!blockquote) return { found: false };
    return {
      found: true,
      quoteColor: getComputedStyle(blockquote).color,
      strongColor: strong ? getComputedStyle(strong).color : null,
      beforeBackground: getComputedStyle(blockquote, "::before").backgroundColor,
      afterBackground: getComputedStyle(blockquote, "::after").backgroundColor,
      text: blockquote.textContent.replace(/\\s+/g, " ").trim()
    };
  })()`,
  returnByValue: true,
});
await send("Browser.close").catch(() => {});

const actual = result.result.value;
if (!actual.found) {
  throw new Error("Expected business-impact blockquote to exist.");
}

const expectedText = "rgb(255, 255, 255)";
const expectedRule = "rgba(255, 255, 255, 0.22)";

if (actual.quoteColor !== expectedText) {
  throw new Error(`Expected dark-mode blockquote text ${expectedText}, got ${actual.quoteColor}.`);
}

if (actual.strongColor !== expectedText) {
  throw new Error(`Expected dark-mode blockquote strong text ${expectedText}, got ${actual.strongColor}.`);
}

for (const [name, value] of Object.entries({
  beforeBackground: actual.beforeBackground,
  afterBackground: actual.afterBackground,
})) {
  if (value !== expectedRule) {
    throw new Error(`Expected dark-mode blockquote ${name} ${expectedRule}, got ${value}.`);
  }
}

console.log(JSON.stringify(actual, null, 2));
NODE
