#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/support/browser-cdp.sh"

browser_cdp_setup "case-study-section-nav-browser" "${CASE_STUDY_NAV_TEST_PORT:-4120}" "${CASE_STUDY_NAV_CHROME_PORT:-9240}" "/blog/feet-on-street-app/"

browser_cdp_node <<'NODE'
const { sitePort, send, waitReady, delay } = globalThis.browserCdp;

async function waitForNav() {
  for (let attempt = 0; attempt < 80; attempt++) {
    const result = await send("Runtime.evaluate", {
      expression: "document.querySelectorAll('.case-study-section-nav__link').length",
      returnByValue: true,
    });
    if (result.result.value >= 2) return;
    await delay(100);
  }
  throw new Error("Case-study nav links were not populated");
}

await send("Emulation.setDeviceMetricsOverride", {
  width: 1280,
  height: 900,
  deviceScaleFactor: 1,
  mobile: false,
});
await send("Page.navigate", { url: `http://127.0.0.1:${sitePort}/blog/feet-on-street-app/` });
await waitReady();
await waitForNav();

const desktopResult = await send("Runtime.evaluate", {
  expression: `(() => {
    const sidebar = document.querySelector(".case-study-sidebar");
    const shell = document.querySelector(".case-study-shell");
    const main = document.querySelector(".case-study-main");
    const content = document.querySelector(".case-study-content");
    const dot = document.querySelector(".case-study-section-nav__dot");
    const backIcon = document.querySelector(".case-study-sidebar__back .ph-arrow-left");
    const headerContainer = document.querySelector(".header .container");
    const journey = document.querySelector("figure.retailer-journey-map");
    const links = Array.from(document.querySelectorAll(".case-study-section-nav__link"));
    const headings = Array.from(document.querySelectorAll(".case-study-content > section > h3"));
    const sidebarStyle = sidebar ? getComputedStyle(sidebar) : null;
    const shellStyle = shell ? getComputedStyle(shell) : null;
    const dotStyle = dot ? getComputedStyle(dot) : null;
    const sidebarRect = sidebar && sidebar.getBoundingClientRect();
    const mainRect = main && main.getBoundingClientRect();
    const shellRect = shell && shell.getBoundingClientRect();
    const headerRect = headerContainer && headerContainer.getBoundingClientRect();
    const journeyRect = journey && journey.getBoundingClientRect();

    return {
      found: Boolean(sidebar && shell && main && content && dot),
      backIconFound: Boolean(backIcon),
      sidebarDisplay: sidebarStyle && sidebarStyle.display,
      sidebarPosition: sidebarStyle && sidebarStyle.position,
      sidebarHeight: sidebarStyle && sidebarStyle.height,
      shellGridColumns: shellStyle && shellStyle.gridTemplateColumns,
      shellGap: shellStyle && shellStyle.columnGap,
      shellWidth: shellRect && Math.round(shellRect.width),
      shellLeft: shellRect && Math.round(shellRect.left),
      sidebarWidth: sidebarRect && Math.round(sidebarRect.width),
      sidebarLeft: sidebarRect && Math.round(sidebarRect.left),
      mainWidth: mainRect && Math.round(mainRect.width),
      mainLeft: mainRect && Math.round(mainRect.left),
      headerContainerWidth: headerRect && Math.round(headerRect.width),
      headerContainerLeft: headerRect && Math.round(headerRect.left),
      shellAlignsWithHeader: shellRect && headerRect ? Math.round(shellRect.left) === Math.round(headerRect.left) && Math.round(shellRect.right) === Math.round(headerRect.right) : false,
      dotLeft: dotStyle && dotStyle.left,
      journeyWidth: journeyRect && Math.round(journeyRect.width),
      journeyWiderThanMain: journeyRect && mainRect ? journeyRect.width > mainRect.width + 1 : false,
      shellHasWideOverlap: shell.classList.contains("case-study-shell--wide-overlap"),
      sidebarInnerOpacity: getComputedStyle(document.querySelector(".case-study-sidebar__inner")).opacity,
      sidebarInnerVisibility: getComputedStyle(document.querySelector(".case-study-sidebar__inner")).visibility,
      navTexts: links.map((link) => link.textContent.trim().replace(/\\s+/g, " ")),
      navHrefs: links.map((link) => link.getAttribute("href")),
      headingIds: headings.map((heading) => heading.id),
      dotWidth: dotStyle && dotStyle.width,
      dotHeight: dotStyle && dotStyle.height,
      dotBackground: dotStyle && dotStyle.backgroundColor,
      dotTransform: dotStyle && dotStyle.transform,
      activeText: document.querySelector(".case-study-section-nav__link.is-active")?.textContent.trim().replace(/\\s+/g, " ") || null,
    };
  })()`,
  returnByValue: true,
});

const beforeClick = await send("Runtime.evaluate", {
  expression: `(() => {
    const dot = document.querySelector(".case-study-section-nav__dot");
    return {
      activeText: document.querySelector(".case-study-section-nav__link.is-active")?.textContent.trim().replace(/\\s+/g, " "),
      dotTransform: getComputedStyle(dot).transform
    };
  })()`,
  returnByValue: true,
});

await send("Runtime.evaluate", {
  expression: `document.querySelector('.case-study-section-nav__link[href="#research"]').click()`,
});
await new Promise((resolve) => setTimeout(resolve, 450));

const afterClick = await send("Runtime.evaluate", {
  expression: `(() => {
    const dot = document.querySelector(".case-study-section-nav__dot");
    return {
      activeText: document.querySelector(".case-study-section-nav__link.is-active")?.textContent.trim().replace(/\\s+/g, " "),
      dotTransform: getComputedStyle(dot).transform,
      scrollY: Math.round(window.scrollY)
    };
  })()`,
  returnByValue: true,
});

const wideOverlapResult = await send("Runtime.evaluate", {
  expression: `new Promise((resolve) => {
    const shell = document.querySelector(".case-study-shell");
    const journey = document.querySelector("figure.retailer-journey-map");
    const navPanel = document.querySelector(".case-study-sidebar__inner");

    function navState() {
      const navStyle = getComputedStyle(navPanel);
      const journeyRect = journey.getBoundingClientRect();
      const navRect = navPanel.getBoundingClientRect();

      return {
        shellHasWideOverlap: shell.classList.contains("case-study-shell--wide-overlap"),
        navOpacity: navStyle.opacity,
        navVisibility: navStyle.visibility,
        journeyTop: Math.round(journeyRect.top),
        journeyBottom: Math.round(journeyRect.bottom),
        navTop: Math.round(navRect.top),
        navBottom: Math.round(navRect.bottom)
      };
    }

    const before = navState();
    journey.scrollIntoView({ block: "start" });

    setTimeout(() => {
      const overlap = navState();
      const journeyRect = journey.getBoundingClientRect();
      const navRect = navPanel.getBoundingClientRect();
      window.scrollBy(0, Math.max(0, journeyRect.bottom - navRect.top + 24));

      setTimeout(() => {
        resolve({
          before,
          overlap,
          afterClear: navState()
        });
      }, 240);
    }, 240);
  })`,
  awaitPromise: true,
  returnByValue: true,
});

await send("Emulation.setDeviceMetricsOverride", {
  width: 390,
  height: 844,
  deviceScaleFactor: 1,
  mobile: true,
});
await send("Page.navigate", { url: `http://127.0.0.1:${sitePort}/blog/feet-on-street-app/` });
await waitReady();
await new Promise((resolve) => setTimeout(resolve, 300));

const mobileResult = await send("Runtime.evaluate", {
  expression: `(() => {
    const sidebar = document.querySelector(".case-study-sidebar");
    const main = document.querySelector(".case-study-main");
    return {
      sidebarDisplay: getComputedStyle(sidebar).display,
      mainWidth: Math.round(main.getBoundingClientRect().width),
      viewportWidth: window.innerWidth
    };
  })()`,
  returnByValue: true,
});

await send("Browser.close").catch(() => {});

const desktop = desktopResult.result.value;
const before = beforeClick.result.value;
const after = afterClick.result.value;
const wideOverlap = wideOverlapResult.result.value;
const mobile = mobileResult.result.value;

if (!desktop.found) {
  throw new Error("Expected the case-study side nav scaffold to render.");
}

if (desktop.sidebarDisplay === "none") {
  throw new Error("Expected the side nav to be visible on desktop.");
}

if (desktop.sidebarPosition !== "sticky") {
  throw new Error(`Expected desktop side nav to be sticky, got ${desktop.sidebarPosition}.`);
}

if (!desktop.backIconFound) {
  throw new Error("Expected the Back link to include a Phosphor arrow-left icon.");
}

if (desktop.shellGridColumns !== "200px 720px") {
  throw new Error(`Expected desktop shell columns to be 200px 720px, got ${desktop.shellGridColumns}.`);
}

if (desktop.shellGap !== "40px") {
  throw new Error(`Expected desktop shell gap to be 40px, got ${desktop.shellGap}.`);
}

if (
  desktop.shellWidth !== 960 ||
  desktop.shellLeft !== 160 ||
  desktop.sidebarWidth !== 200 ||
  desktop.sidebarLeft !== 160 ||
  desktop.mainWidth !== 720 ||
  desktop.mainLeft !== 400 ||
  !desktop.shellAlignsWithHeader
) {
  throw new Error(`Expected case-study shell to align with the original 960px content width, got ${JSON.stringify({ shellWidth: desktop.shellWidth, shellLeft: desktop.shellLeft, sidebarWidth: desktop.sidebarWidth, sidebarLeft: desktop.sidebarLeft, mainWidth: desktop.mainWidth, mainLeft: desktop.mainLeft, shellAlignsWithHeader: desktop.shellAlignsWithHeader })}.`);
}

if (desktop.headerContainerWidth !== 960 || desktop.headerContainerLeft !== 160) {
  throw new Error(`Expected header container to keep the original content area, got ${JSON.stringify({ headerContainerWidth: desktop.headerContainerWidth, headerContainerLeft: desktop.headerContainerLeft })}.`);
}

const expectedNavTexts = [
  "The challenge",
  "My role",
  "Context",
  "Research",
  "Retailer journey map",
  "Key customer problems",
  "Retailer benefit",
  "Design direction",
  "Business impact",
];

if (JSON.stringify(desktop.navTexts) !== JSON.stringify(expectedNavTexts)) {
  throw new Error(`Expected nav texts ${JSON.stringify(expectedNavTexts)}, got ${JSON.stringify(desktop.navTexts)}.`);
}

for (const disallowed of ["Goals", "1. Easy management for BDOs", "2. Scalable retailer details page", "3. Easy invoice reconciliation", "4. OTP confirmation"]) {
  if (desktop.navTexts.includes(disallowed)) {
    throw new Error(`Expected nav to exclude subsection '${disallowed}'.`);
  }
}

for (const expectedId of ["the-challenge", "my-role", "context", "research", "retailer-journey-map", "business-impact"]) {
  if (!desktop.headingIds.includes(expectedId)) {
    throw new Error(`Expected generated heading id '${expectedId}', got ${JSON.stringify(desktop.headingIds)}.`);
  }
}

if (!desktop.navHrefs.includes("#the-challenge") || !desktop.navHrefs.includes("#business-impact")) {
  throw new Error(`Expected nav hrefs to target generated ids, got ${JSON.stringify(desktop.navHrefs)}.`);
}

if (desktop.dotWidth !== "6px" || desktop.dotHeight !== "6px") {
  throw new Error(`Expected the active section dot to be 6px, got ${desktop.dotWidth} by ${desktop.dotHeight}.`);
}

if (desktop.dotLeft !== "-14px") {
  throw new Error(`Expected the active section dot to sit 8px from the nav list edge, got left ${desktop.dotLeft}.`);
}

if (desktop.dotBackground !== "rgb(28, 28, 28)") {
  throw new Error(`Expected light-mode dot color #1c1c1c, got ${desktop.dotBackground}.`);
}

if (!desktop.journeyWiderThanMain) {
  throw new Error(`Expected journey map to be wider than the case-study content column, got journey ${desktop.journeyWidth}px and main ${desktop.mainWidth}px.`);
}

if (desktop.shellHasWideOverlap || desktop.sidebarInnerOpacity !== "1" || desktop.sidebarInnerVisibility !== "visible") {
  throw new Error(`Expected side nav to be visible before wide content overlaps it, got ${JSON.stringify({ shellHasWideOverlap: desktop.shellHasWideOverlap, sidebarInnerOpacity: desktop.sidebarInnerOpacity, sidebarInnerVisibility: desktop.sidebarInnerVisibility })}.`);
}

if (before.activeText !== "The challenge") {
  throw new Error(`Expected initial active section to be The challenge, got ${before.activeText}.`);
}

if (after.activeText !== "Research") {
  throw new Error(`Expected clicking Research to activate Research, got ${after.activeText}.`);
}

if (after.dotTransform === before.dotTransform) {
  throw new Error(`Expected dot transform to change after clicking Research, stayed ${after.dotTransform}.`);
}

if (after.scrollY <= 0) {
  throw new Error("Expected clicking a nav item to move the page.");
}

if (!wideOverlap.overlap.shellHasWideOverlap || Number(wideOverlap.overlap.navOpacity) > 0.05 || wideOverlap.overlap.navVisibility !== "hidden") {
  throw new Error(`Expected side nav to hide while the journey map overlaps it, got ${JSON.stringify(wideOverlap.overlap)}.`);
}

if (wideOverlap.afterClear.shellHasWideOverlap || wideOverlap.afterClear.navOpacity !== "1" || wideOverlap.afterClear.navVisibility !== "visible") {
  throw new Error(`Expected side nav to reappear after the journey map clears it, got ${JSON.stringify(wideOverlap.afterClear)}.`);
}

if (mobile.sidebarDisplay !== "none") {
  throw new Error(`Expected side nav to be hidden on mobile, got display ${mobile.sidebarDisplay}.`);
}

if (mobile.mainWidth > mobile.viewportWidth) {
  throw new Error(`Expected mobile case-study content to fit viewport, got main ${mobile.mainWidth}px and viewport ${mobile.viewportWidth}px.`);
}

console.log(JSON.stringify({ desktop, before, after, wideOverlap, mobile }, null, 2));
NODE
