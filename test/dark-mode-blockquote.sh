#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/dark-mode-blockquote-jekyll.log

site_port="${DARK_MODE_BLOCKQUOTE_SITE_PORT:-4114}"
chrome_port="${DARK_MODE_BLOCKQUOTE_CHROME_PORT:-9234}"
site_log="/tmp/dark-mode-blockquote-site.log"
chrome_log="/tmp/dark-mode-blockquote-chrome.log"
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
  if curl -fsS "http://127.0.0.1:$site_port/blog/feet-on-street-app/" >/dev/null 2>&1; then
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

BLOCKQUOTE_TEST_SITE_PORT="$site_port" BLOCKQUOTE_TEST_CHROME_PORT="$chrome_port" node <<'NODE'
const sitePort = process.env.BLOCKQUOTE_TEST_SITE_PORT;
const chromePort = process.env.BLOCKQUOTE_TEST_CHROME_PORT;
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

const expectedText = "rgb(236, 231, 226)";
const expectedRule = "rgba(236, 231, 226, 0.45)";

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
