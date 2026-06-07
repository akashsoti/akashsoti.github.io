#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/dark-mode-text-selection-jekyll.log

site_port="${DARK_MODE_SELECTION_SITE_PORT:-4117}"
chrome_port="${DARK_MODE_SELECTION_CHROME_PORT:-9235}"
site_log="/tmp/dark-mode-text-selection-site.log"
chrome_log="/tmp/dark-mode-text-selection-chrome.log"
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

SELECTION_TEST_SITE_PORT="$site_port" SELECTION_TEST_CHROME_PORT="$chrome_port" node <<'NODE'
const sitePort = process.env.SELECTION_TEST_SITE_PORT;
const chromePort = process.env.SELECTION_TEST_CHROME_PORT;
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
    const sample = document.querySelector(".post p");
    if (!sample) return { found: false };
    const lightSelection = getComputedStyle(sample, "::selection");
    const lightBackground = lightSelection.backgroundColor;
    const lightColor = lightSelection.color;
    document.documentElement.classList.add("theme-dark");
    const darkSelection = getComputedStyle(sample, "::selection");
    return {
      found: true,
      lightBackground,
      lightColor,
      darkBackground: darkSelection.backgroundColor,
      darkColor: darkSelection.color,
      sampleText: sample.textContent.trim()
    };
  })()`,
  returnByValue: true,
});
await send("Browser.close").catch(() => {});

const actual = result.result.value;
if (!actual.found) {
  throw new Error("Expected sample post text to exist.");
}

const expectedLightBackground = "rgba(0, 0, 0, 0.9)";
const expectedLightColor = "rgb(255, 255, 255)";
const expectedDarkBackground = "rgb(236, 231, 226)";
const expectedDarkColor = "rgb(11, 11, 11)";

for (const [name, expected] of Object.entries({
  lightBackground: expectedLightBackground,
  lightColor: expectedLightColor,
  darkBackground: expectedDarkBackground,
  darkColor: expectedDarkColor,
})) {
  if (actual[name] !== expected) {
    throw new Error(`Expected ${name} ${expected}, got ${actual[name]}.`);
  }
}

console.log(JSON.stringify(actual, null, 2));
NODE

if ! grep -q 'html.theme-dark ::-moz-selection' assets/css/overrides/theme.css; then
  echo "Expected Firefox dark-mode selection override." >&2
  exit 1
fi
