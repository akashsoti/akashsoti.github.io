#!/usr/bin/env bash
set -euo pipefail

css="assets/css/overrides/case-study-nav.css"
js="assets/js/scripts.js"

if ! grep -Fq 'function initCaseStudyWideOverlapNav()' "$js"; then
  echo "Expected scripts.js to initialize wide-block side-nav overlap handling." >&2
  exit 1
fi

if ! grep -Fq 'figure.retailer-journey-map, figure.journey-map, figure.wide-image, [data-case-study-wide]' "$js"; then
  echo "Expected wide-block selector to include retailer journey maps, wide images, and data-case-study-wide opt-ins." >&2
  exit 1
fi

if ! grep -Fq 'wideRect.top <= navRect.bottom && wideRect.bottom >= navRect.top' "$js"; then
  echo "Expected overlap logic to compare wide block top/bottom with nav panel bottom/top." >&2
  exit 1
fi

if ! grep -Fq 'case-study-shell--wide-overlap' "$js"; then
  echo "Expected JS to toggle the case-study wide-overlap shell state." >&2
  exit 1
fi

if ! grep -Fq 'ResizeObserver' "$js"; then
  echo "Expected wide-overlap handling to observe size changes." >&2
  exit 1
fi

if ! grep -Fq '.case-study-shell--wide-overlap .case-study-sidebar__inner' "$css"; then
  echo "Expected CSS to visually hide the side nav during wide-block overlap." >&2
  exit 1
fi

if ! grep -Fq 'pointer-events: none' "$css"; then
  echo "Expected hidden side nav to avoid pointer interactions without layout reflow." >&2
  exit 1
fi

desktop_css="$(awk '/@media only screen and \\(min-width: 1248px\\)/,/^}/' "$css")"

if grep -q 'figure.wide-image' <<<"$desktop_css"; then
  echo "Expected desktop case-study CSS not to clamp wide images to the article column." >&2
  exit 1
fi

if grep -q 'figure.retailer-journey-map' <<<"$desktop_css"; then
  echo "Expected desktop case-study CSS not to clamp retailer journey maps to the article column." >&2
  exit 1
fi
