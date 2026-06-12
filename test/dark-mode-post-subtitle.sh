#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/support/browser-cdp.sh"

browser_cdp_setup "dark-mode-post-subtitle" "${DARK_MODE_TEST_PORT:-4107}" "${DARK_MODE_CHROME_PORT:-9227}" "/blog/feet-on-street-app/"

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
    const subtitle = document.querySelector(".post-header > p:last-child");
    const heading = document.querySelector(".post-header > h1");
    const paragraph = document.querySelector(".post p");
    if (!subtitle) return { found: false };
    return {
      found: true,
      bodyBackground: getComputedStyle(document.body).backgroundColor,
      bodyColor: getComputedStyle(document.body).color,
      headingColor: heading ? getComputedStyle(heading).color : null,
      paragraphColor: paragraph ? getComputedStyle(paragraph).color : null,
      subtitleColor: getComputedStyle(subtitle).color,
      text: subtitle.textContent.trim()
    };
  })()`,
  returnByValue: true,
});
await send("Browser.close").catch(() => {});

const actual = result.result.value;
if (!actual.found) {
  throw new Error("Expected post subtitle to exist.");
}

const expectedBackground = "rgb(10, 10, 10)";
const expectedHeadingText = "rgb(255, 255, 255)";
const expectedBodyText = "rgb(188, 187, 187)";
const expectedMetaText = "rgb(143, 142, 142)";

if (actual.bodyBackground !== expectedBackground) {
  throw new Error(`Expected dark-mode body background ${expectedBackground}, got ${actual.bodyBackground}.`);
}

if (actual.bodyColor !== expectedHeadingText || actual.headingColor !== expectedHeadingText) {
  throw new Error(`Expected dark-mode body/heading text ${expectedHeadingText}, got body ${actual.bodyColor} and heading ${actual.headingColor}.`);
}

if (actual.paragraphColor !== expectedBodyText) {
  throw new Error(`Expected dark-mode paragraph text ${expectedBodyText}, got ${actual.paragraphColor}.`);
}

if (actual.subtitleColor !== expectedMetaText) {
  throw new Error(`Expected dark-mode subtitle text ${expectedMetaText}, got ${actual.subtitleColor}.`);
}

console.log(JSON.stringify(actual, null, 2));
NODE
