#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/dark-mode-post-subtitle-jekyll.log

site_port="${DARK_MODE_TEST_PORT:-4107}"
chrome_port="${DARK_MODE_CHROME_PORT:-9227}"
site_log="/tmp/dark-mode-post-subtitle-site.log"
chrome_log="/tmp/dark-mode-post-subtitle-chrome.log"
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

SUBTITLE_TEST_SITE_PORT="$site_port" SUBTITLE_TEST_CHROME_PORT="$chrome_port" node <<'NODE'
const sitePort = process.env.SUBTITLE_TEST_SITE_PORT;
const chromePort = process.env.SUBTITLE_TEST_CHROME_PORT;
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
    const subtitle = document.querySelector(".postTitle-subTitle");
    const heading = document.querySelector(".postTitle");
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

const expectedBackground = "rgb(11, 11, 11)";
const expectedText = "rgb(236, 231, 226)";

if (actual.bodyBackground !== expectedBackground) {
  throw new Error(`Expected dark-mode body background ${expectedBackground}, got ${actual.bodyBackground}.`);
}

for (const [name, value] of Object.entries({
  bodyColor: actual.bodyColor,
  headingColor: actual.headingColor,
  paragraphColor: actual.paragraphColor,
  subtitleColor: actual.subtitleColor,
})) {
  if (value !== expectedText) {
    throw new Error(`Expected dark-mode ${name} ${expectedText}, got ${value}.`);
  }
}

console.log(JSON.stringify(actual, null, 2));
NODE
