export function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function waitReady(send) {
  for (let attempt = 0; attempt < 80; attempt++) {
    const result = await send("Runtime.evaluate", {
      expression: "document.readyState",
      returnByValue: true,
    });

    if (result.result.value === "complete") {
      return;
    }

    await delay(100);
  }

  throw new Error("Page did not finish loading");
}

export async function createCdpClient(chromePort) {
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

        if (payload.id !== messageId) {
          return;
        }

        ws.removeEventListener("message", onMessage);

        if (payload.error) {
          reject(new Error(JSON.stringify(payload.error)));
        } else {
          resolve(payload.result);
        }
      };

      ws.addEventListener("message", onMessage);
      ws.send(JSON.stringify({ id: messageId, method, params }));
    });
  }

  async function closeBrowser() {
    await send("Browser.close").catch(() => {});
    ws.close();
  }

  return {
    closeBrowser,
    send,
  };
}
