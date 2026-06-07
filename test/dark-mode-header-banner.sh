#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/dark-mode-header-banner-jekyll.log

site_port="${DARK_MODE_HEADER_TEST_PORT:-4110}"
chrome_port="${DARK_MODE_HEADER_CHROME_PORT:-9230}"
site_log="/tmp/dark-mode-header-banner-site.log"
chrome_log="/tmp/dark-mode-header-banner-chrome.log"
chrome_tmp="$(mktemp -d)"

cleanup() {
  if [[ -n "${site_pid:-}" ]]; then
    kill "$site_pid" >/dev/null 2>&1 || true
    wait "$site_pid" 2>/dev/null || true
  fi
  if [[ -n "${chrome_pid:-}" ]]; then
    kill "$chrome_pid" >/dev/null 2>&1 || true
    wait "$chrome_pid" 2>/dev/null || true
  fi
  rm -rf "$chrome_tmp"
}
trap cleanup EXIT

ruby -run -e httpd _site -p "$site_port" >"$site_log" 2>&1 &
site_pid=$!

for _ in $(seq 1 80); do
  if curl -fsS "http://127.0.0.1:$site_port/" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless=new \
  --disable-gpu \
  --hide-scrollbars \
  --remote-debugging-port="$chrome_port" \
  --user-data-dir="$chrome_tmp" \
  about:blank >"$chrome_log" 2>&1 &
chrome_pid=$!

for _ in $(seq 1 80); do
  if curl -fsS "http://127.0.0.1:$chrome_port/json/version" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

HEADER_BANNER_TEST_SITE_PORT="$site_port" HEADER_BANNER_TEST_CHROME_PORT="$chrome_port" node <<'NODE'
const sitePort = process.env.HEADER_BANNER_TEST_SITE_PORT;
const chromePort = process.env.HEADER_BANNER_TEST_CHROME_PORT;
const targets = await fetch(`http://127.0.0.1:${chromePort}/json`).then((response) => response.json());
const page = targets.find((target) => target.type === "page");

if (!page) {
  throw new Error("No Chrome page target found");
}

const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
  ws.addEventListener("open", resolve, { once: true });
  ws.addEventListener("error", reject, { once: true });
});

let id = 1;
function send(method, params = {}) {
  const messageId = id++;
  return new Promise((resolve, reject) => {
    const onMessage = (event) => {
      const payload = JSON.parse(event.data);
      if (payload.id !== messageId) return;
      ws.removeEventListener("message", onMessage);
      if (payload.error) reject(new Error(JSON.stringify(payload.error)));
      else resolve(payload.result);
    };
    ws.addEventListener("message", onMessage);
    ws.send(JSON.stringify({ id: messageId, method, params }));
  });
}

async function waitReady() {
  for (let attempt = 0; attempt < 80; attempt++) {
    const result = await send("Runtime.evaluate", {
      expression: "document.readyState",
      returnByValue: true,
    });
    if (result.result.value === "complete") return;
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error("Page did not finish loading");
}

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
