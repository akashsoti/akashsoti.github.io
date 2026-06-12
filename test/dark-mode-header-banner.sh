#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/support/browser-cdp.sh"

browser_cdp_setup "dark-mode-header-banner" "${DARK_MODE_HEADER_TEST_PORT:-4110}" "${DARK_MODE_HEADER_CHROME_PORT:-9230}" "/"

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

const desktopResult = await send("Runtime.evaluate", {
  expression: `(() => {
    const header = document.querySelector(".header");
    if (!header) return { found: false };
    document.documentElement.classList.remove("theme-dark");
    const lightBackgroundImage = getComputedStyle(header).backgroundImage;
    const desktopBackgroundPosition = getComputedStyle(header).backgroundPosition;
    const desktopBackgroundSize = getComputedStyle(header).backgroundSize;
    const desktopOverlayBackground = getComputedStyle(header, "::before").backgroundColor;
    document.documentElement.classList.add("theme-dark");
    const darkBackgroundImage = getComputedStyle(header).backgroundImage;
    const darkOverlayBackground = getComputedStyle(header, "::before").backgroundColor;
    return {
      found: true,
      lightBackgroundImage,
      darkBackgroundImage,
      desktopBackgroundPosition,
      desktopBackgroundSize,
      desktopOverlayBackground,
      darkOverlayBackground
    };
  })()`,
  returnByValue: true,
});

await send("Emulation.setDeviceMetricsOverride", {
  width: 390,
  height: 844,
  deviceScaleFactor: 1,
  mobile: true,
});
await send("Page.navigate", { url: `http://127.0.0.1:${sitePort}/` });
await waitReady();

const mobileResult = await send("Runtime.evaluate", {
  expression: `(() => {
    const header = document.querySelector(".header");
    if (!header) return { found: false };
    return {
      found: true,
      mobileBackgroundImage: getComputedStyle(header).backgroundImage,
      mobileBackgroundPosition: getComputedStyle(header).backgroundPosition,
      mobileBackgroundSize: getComputedStyle(header).backgroundSize,
      mobileOverlayBackground: getComputedStyle(header, "::before").backgroundColor
    };
  })()`,
  returnByValue: true,
});
await send("Browser.close").catch(() => {});

const actual = {
  ...desktopResult.result.value,
  ...mobileResult.result.value,
};
if (!actual.found) {
  throw new Error("Expected header banner to exist.");
}

if (!actual.lightBackgroundImage.includes("akash-banner.png")) {
  throw new Error(`Expected header banner to use akash-banner.png, got ${actual.lightBackgroundImage}.`);
}

if (actual.darkBackgroundImage.includes("linear-gradient")) {
  throw new Error(`Expected dark-mode banner to have no dark overlay, got ${actual.darkBackgroundImage}.`);
}

if (actual.darkBackgroundImage !== actual.lightBackgroundImage) {
  throw new Error(`Expected dark-mode banner image to match light mode. Light: ${actual.lightBackgroundImage}; dark: ${actual.darkBackgroundImage}.`);
}

if (actual.mobileBackgroundImage !== actual.lightBackgroundImage) {
  throw new Error(`Expected mobile banner image to match desktop image. Desktop: ${actual.lightBackgroundImage}; mobile: ${actual.mobileBackgroundImage}.`);
}

if (actual.desktopBackgroundPosition !== "50% 40%") {
  throw new Error(`Expected desktop face-safe banner crop to keep the shifted subject visible at 50% 40%, got ${actual.desktopBackgroundPosition}.`);
}

if (actual.mobileBackgroundPosition !== "50% 43%") {
  throw new Error(`Expected mobile face-safe banner crop to keep the shifted subject visible at 50% 43%, got ${actual.mobileBackgroundPosition}.`);
}

if (actual.desktopBackgroundSize !== "cover") {
  throw new Error(`Expected desktop banner to use normal cover sizing instead of enlargement, got ${actual.desktopBackgroundSize}.`);
}

if (actual.mobileBackgroundSize !== "cover") {
  throw new Error(`Expected mobile banner to use normal cover sizing instead of enlargement, got ${actual.mobileBackgroundSize}.`);
}

for (const [label, value] of [
  ["desktop", actual.desktopOverlayBackground],
  ["dark", actual.darkOverlayBackground],
  ["mobile", actual.mobileOverlayBackground],
]) {
  if (value !== "rgba(0, 0, 0, 0.56)") {
    throw new Error(`Expected ${label} banner overlay to use 56% black, got ${value}.`);
  }
}

console.log(JSON.stringify(actual, null, 2));
NODE
