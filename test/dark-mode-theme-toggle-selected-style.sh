#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/support/browser-cdp.sh"

browser_cdp_setup "dark-mode-theme-toggle-selected-style" "${DARK_MODE_TOGGLE_TEST_PORT:-4112}" "${DARK_MODE_TOGGLE_CHROME_PORT:-9232}" "/"

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
    const toggle = document.querySelector(".theme-toggle--desktop");
    const selectedNavItem = document.querySelector(".top-nav__link.is-current");
    if (!toggle || !selectedNavItem) return { found: false };

    const toggleStyle = getComputedStyle(toggle);
    const selectedStyle = getComputedStyle(selectedNavItem);
    const rect = toggle.getBoundingClientRect();
    return {
      found: true,
      navSelectedBackground: selectedStyle.backgroundColor,
      navSelectedColor: selectedStyle.color,
      toggleBackground: toggleStyle.backgroundColor,
      toggleColor: toggleStyle.color,
      toggleCenter: {
        x: rect.left + rect.width / 2,
        y: rect.top + rect.height / 2
      }
    };
  })()`,
  awaitPromise: true,
  returnByValue: true,
});

if (!defaultResult.result.value.found) {
  throw new Error("Expected both the desktop theme toggle and selected nav item to exist.");
}

await send("Input.dispatchMouseEvent", {
  type: "mouseMoved",
  x: defaultResult.result.value.toggleCenter.x,
  y: defaultResult.result.value.toggleCenter.y,
});

const hoverResult = await send("Runtime.evaluate", {
  expression: `(async () => {
    await new Promise((resolve) => setTimeout(resolve, 300));
    const toggle = document.querySelector(".theme-toggle--desktop");
    const toggleStyle = getComputedStyle(toggle);
    return {
      toggleHoverBackground: toggleStyle.backgroundColor,
      toggleHoverColor: toggleStyle.color
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

const expectedSelectedBackground = "rgba(255, 255, 255, 0.18)";
if (actual.navSelectedBackground !== expectedSelectedBackground) {
  throw new Error(`Expected selected nav background ${expectedSelectedBackground}, got ${actual.navSelectedBackground}.`);
}

if (actual.toggleBackground !== actual.navSelectedBackground) {
  throw new Error(`Expected dark-mode toggle background to match selected nav item. Toggle: ${actual.toggleBackground}; nav: ${actual.navSelectedBackground}.`);
}

if (actual.toggleColor !== actual.navSelectedColor) {
  throw new Error(`Expected dark-mode toggle color to match selected nav item. Toggle: ${actual.toggleColor}; nav: ${actual.navSelectedColor}.`);
}

if (actual.toggleHoverBackground !== actual.navSelectedBackground) {
  throw new Error(`Expected dark-mode toggle hover background to stay selected-nav color. Hover: ${actual.toggleHoverBackground}; nav: ${actual.navSelectedBackground}.`);
}

if (actual.toggleHoverColor !== actual.navSelectedColor) {
  throw new Error(`Expected dark-mode toggle hover color to stay selected-nav color. Hover: ${actual.toggleHoverColor}; nav: ${actual.navSelectedColor}.`);
}

console.log(JSON.stringify(actual, null, 2));
NODE
