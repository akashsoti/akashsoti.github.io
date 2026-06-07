#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/dark-mode-card-color-jekyll.log

site_port="${DARK_MODE_CARD_TEST_PORT:-4108}"
chrome_port="${DARK_MODE_CARD_CHROME_PORT:-9228}"
site_log="/tmp/dark-mode-card-color-site.log"
chrome_log="/tmp/dark-mode-card-color-chrome.log"
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

CARD_TEST_SITE_PORT="$site_port" CARD_TEST_CHROME_PORT="$chrome_port" node <<'NODE'
const sitePort = process.env.CARD_TEST_SITE_PORT;
const chromePort = process.env.CARD_TEST_CHROME_PORT;
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

const expectedCardBackground = "rgb(22, 22, 22)";
if (actual.cardBackground !== expectedCardBackground) {
  throw new Error(`Expected dark-mode card background ${expectedCardBackground}, got ${actual.cardBackground}.`);
}

const expectedCardBoxShadow = "rgba(0, 0, 0, 0.6) 0px 2px 6px 0px";
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

const expectedCardHoverBoxShadow = "rgba(236, 231, 226, 0.1) 0px 0px 0px 1px, rgba(0, 0, 0, 0.32) 0px 4px 12px 0px, rgba(0, 0, 0, 0.22) 0px 2px 4px 0px";
if (actual.cardHoverBoxShadow !== expectedCardHoverBoxShadow) {
  throw new Error(`Expected dark-mode hover card shadow ${expectedCardHoverBoxShadow}, got ${actual.cardHoverBoxShadow}.`);
}

console.log(JSON.stringify(actual, null, 2));
NODE
