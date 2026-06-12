#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/support/browser-cdp.sh"

browser_cdp_setup "light-mode-card-hover-shadow" "${LIGHT_MODE_CARD_TEST_PORT:-4111}" "${LIGHT_MODE_CARD_CHROME_PORT:-9231}" "/"

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

const defaultResult = await send("Runtime.evaluate", {
  expression: `(async () => {
    document.documentElement.classList.remove("theme-dark");
    await new Promise((resolve) => setTimeout(resolve, 300));
    const card = document.querySelector(".posts");
    if (!card) return { found: false };
    return {
      found: true,
      cardBoxShadow: getComputedStyle(card).boxShadow
    };
  })()`,
  awaitPromise: true,
  returnByValue: true,
});

const rectResult = await send("Runtime.evaluate", {
  expression: `(() => {
    const card = document.querySelector(".posts");
    if (!card) return null;
    const rect = card.getBoundingClientRect();
    return {
      x: rect.left + rect.width / 2,
      y: rect.top + rect.height / 2
    };
  })()`,
  returnByValue: true,
});

if (!rectResult.result.value) {
  throw new Error("Expected a project card rectangle to exist.");
}

await send("Input.dispatchMouseEvent", {
  type: "mouseMoved",
  x: rectResult.result.value.x,
  y: rectResult.result.value.y,
});

const hoverResult = await send("Runtime.evaluate", {
  expression: `(async () => {
    await new Promise((resolve) => setTimeout(resolve, 300));
    const card = document.querySelector(".posts");
    if (!card) return { found: false };
    return {
      found: true,
      cardHoverBoxShadow: getComputedStyle(card).boxShadow
    };
  })()`,
  awaitPromise: true,
  returnByValue: true,
});
await send("Browser.close").catch(() => {});

const actual = {
  ...defaultResult.result.value,
  ...hoverResult.result.value,
};
if (!actual.found) {
  throw new Error("Expected a project card to exist.");
}

const expectedCardBoxShadow = "rgba(46, 15, 15, 0.01) 0px 1px 3px 0px, rgba(46, 15, 15, 0.05) 0px 1px 2px 0px";
if (actual.cardBoxShadow !== expectedCardBoxShadow) {
  throw new Error(`Expected light-mode default card shadow ${expectedCardBoxShadow}, got ${actual.cardBoxShadow}.`);
}

const expectedCardHoverBoxShadow = "rgba(46, 15, 15, 0.08) 0px 0px 0px 1px, rgba(46, 15, 15, 0.07) 0px 4px 12px 0px, rgba(46, 15, 15, 0.05) 0px 2px 4px 0px";
if (actual.cardHoverBoxShadow !== expectedCardHoverBoxShadow) {
  throw new Error(`Expected subtle light-mode hover card shadow ${expectedCardHoverBoxShadow}, got ${actual.cardHoverBoxShadow}.`);
}

console.log(JSON.stringify(actual, null, 2));
NODE
