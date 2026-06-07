#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/dark-mode-theme-toggle-selected-style-jekyll.log

site_port="${DARK_MODE_TOGGLE_TEST_PORT:-4112}"
chrome_port="${DARK_MODE_TOGGLE_CHROME_PORT:-9232}"
site_log="/tmp/dark-mode-theme-toggle-selected-style-site.log"
chrome_log="/tmp/dark-mode-theme-toggle-selected-style-chrome.log"
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

TOGGLE_TEST_SITE_PORT="$site_port" TOGGLE_TEST_CHROME_PORT="$chrome_port" node <<'NODE'
const sitePort = process.env.TOGGLE_TEST_SITE_PORT;
const chromePort = process.env.TOGGLE_TEST_CHROME_PORT;
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

const expectedSelectedBackground = "rgba(255, 255, 255, 0.16)";
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
