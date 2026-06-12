#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/support/browser-cdp.sh"

browser_cdp_setup "dark-mode-card-color" "${DARK_MODE_CARD_TEST_PORT:-4108}" "${DARK_MODE_CARD_CHROME_PORT:-9228}" "/"

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
    document.documentElement.classList.add("theme-dark");
    await new Promise((resolve) => setTimeout(resolve, 300));
    const card = document.querySelector(".posts");
    if (!card) return { found: false };
    return {
      found: true,
      cardBackground: getComputedStyle(card).backgroundColor,
      cardBoxShadow: getComputedStyle(card).boxShadow,
      cardTransition: getComputedStyle(card).transition
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
      cardHoverBoxShadow: getComputedStyle(card).boxShadow,
      cardHoverTransform: getComputedStyle(card).transform
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

const expectedCardBackground = "rgb(16, 15, 15)";
if (actual.cardBackground !== expectedCardBackground) {
  throw new Error(`Expected dark-mode card background ${expectedCardBackground}, got ${actual.cardBackground}.`);
}

const expectedCardBoxShadow = "rgba(0, 0, 0, 0.15) 0px 1px 3px 0px, rgba(0, 0, 0, 0.3) 0px 1px 2px 0px";
if (actual.cardBoxShadow !== expectedCardBoxShadow) {
  throw new Error(`Expected dark-mode default card drop shadow ${expectedCardBoxShadow}, got ${actual.cardBoxShadow}.`);
}

const expectedCardTransition = "0.2s cubic-bezier(0.25, 0.8, 0.25, 1)";
if (actual.cardTransition !== expectedCardTransition) {
  throw new Error(`Expected dark-mode card transition to match light-mode timing ${expectedCardTransition}, got ${actual.cardTransition}.`);
}

const expectedCardHoverTransform = "none";
if (actual.cardHoverTransform !== expectedCardHoverTransform) {
  throw new Error(`Expected dark-mode hover card to avoid a transform lift like light mode, got ${actual.cardHoverTransform}.`);
}

const expectedCardHoverBoxShadow = "rgba(255, 255, 255, 0.08) 0px 0px 0px 1px, rgba(0, 0, 0, 0.35) 0px 4px 12px 0px, rgba(0, 0, 0, 0.3) 0px 2px 4px 0px";
if (actual.cardHoverBoxShadow !== expectedCardHoverBoxShadow) {
  throw new Error(`Expected dark-mode hover card shadow ${expectedCardHoverBoxShadow}, got ${actual.cardHoverBoxShadow}.`);
}

console.log(JSON.stringify(actual, null, 2));
NODE
