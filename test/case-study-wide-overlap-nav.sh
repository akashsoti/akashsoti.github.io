#!/usr/bin/env bash
set -euo pipefail

css="assets/css/overrides/case-study-nav.css"
js="assets/js/scripts.js"

if grep -Fq 'function initCaseStudyWideOverlapNav()' "$js"; then
  echo "Expected wide-block side-nav overlap JS to be removed." >&2
  exit 1
fi

if grep -Fq 'wideRect.top <= navRect.bottom && wideRect.bottom >= navRect.top' "$js"; then
  echo "Expected no scroll-measured wide-block overlap logic." >&2
  exit 1
fi

if grep -Fq 'case-study-shell--wide-overlap' "$js" "$css"; then
  echo "Expected no wide-overlap shell state in JS or CSS." >&2
  exit 1
fi

if grep -Fq 'pointer-events: none' "$css"; then
  echo "Expected side nav not to be disabled during wide-block overlap." >&2
  exit 1
fi

if ! grep -Fq '.case-study-sidebar {' "$css" || ! grep -Fq 'z-index: 1;' "$css"; then
  echo "Expected the sticky sidebar to keep a lower stacking order than wide media." >&2
  exit 1
fi

if ! grep -Fq '.case-study-main {' "$css" || ! grep -Fq 'z-index: 2;' "$css"; then
  echo "Expected the case-study main column to stack above the side nav." >&2
  exit 1
fi

if ! grep -Fq 'z-index: 3;' "$css"; then
  echo "Expected wide media to stack above the side nav when they overlap." >&2
  exit 1
fi

if ! grep -Fq 'figure.retailer-journey-map' "$css" || ! grep -Fq '[data-case-study-wide]' "$css"; then
  echo "Expected wide media selectors to remain in case-study CSS." >&2
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
