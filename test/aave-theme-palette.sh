#!/usr/bin/env bash
set -euo pipefail

tokens_css="assets/css/overrides/tokens.css"
theme_css="assets/css/overrides/theme.css"
prototype_css="assets/css/overrides/prototypes.css"
journey_css="assets/css/overrides/journey-map.css"
case_nav_css="assets/css/overrides/case-study-nav.css"

for expected in \
  "--bg-max: #fff;" \
  "--bg-1: #faf9f9;" \
  "--bg-2: #f0efef;" \
  "--border-1: #2e0f0f14;" \
  "--border-2: #0003;" \
  "--fg-1: #000;" \
  "--fg-2: #5a5858;" \
  "--fg-3: #727274;" \
  "--selected: #2e0f0f0a;" \
  "--header-nav-hover-bg: rgba(255, 255, 255, 0.14);" \
  "--header-nav-selected-bg: rgba(255, 255, 255, 0.26);" \
  "--shadow-low: #2e0f0f03;" \
  "--shadow-medium: #2e0f0f0d;" \
  "--shadow-high: #2e0f0f12;" \
  "--shadow-stroke-1: #2e0f0f14;"; do
  if ! grep -q -- "$expected" "$tokens_css"; then
    echo "Expected light Aave theme token '$expected'." >&2
    exit 1
  fi
done

for expected in \
  "html.theme-dark {" \
  "--bg-max: #0a0a0a;" \
  "--bg-1: #100f0f;" \
  "--bg-2: #1a1919;" \
  "--border-1: #ffffff14;" \
  "--border-2: #ffffff38;" \
  "--fg-1: #fff;" \
  "--fg-2: #bcbbbb;" \
  "--fg-3: #8f8e8e;" \
  "--selected: #ffffff0f;" \
  "--header-nav-hover-bg: rgba(255, 255, 255, 0.12);" \
  "--header-nav-selected-bg: rgba(255, 255, 255, 0.18);" \
  "--shadow-low: #00000026;" \
  "--shadow-medium: #0000004d;" \
  "--shadow-high: #00000059;" \
  "--shadow-stroke-1: #ffffff14;"; do
  if ! grep -q -- "$expected" "$tokens_css"; then
    echo "Expected dark Aave theme token '$expected'." >&2
    exit 1
  fi
done

for expected in \
  "@supports (color: color(display-p3 1 1 1))" \
  "@media (color-gamut: p3)" \
  "--primary: color(display-p3 0.5961 0.5882 1);" \
  "--bg-max: color(display-p3 1 1 1);" \
  "--bg-1: color(display-p3 0.9804 0.9765 0.9765);" \
  "--fg-1: color(display-p3 0 0 0);" \
  "--bg-max: color(display-p3 0.0392 0.0392 0.0392);" \
  "--bg-1: color(display-p3 0.0627 0.0588 0.0588);" \
  "--fg-1: color(display-p3 1 1 1);"; do
  if ! grep -q -- "$expected" "$tokens_css"; then
    echo "Expected P3-capable theme token '$expected'." >&2
    exit 1
  fi
done

for expected in \
  "background: var(--body-bg);" \
  "html.theme-dark body" \
  "color: var(--body-color);" \
  "background: var(--bg-1);" \
  "color: var(--fg-1);" \
  "color: var(--fg-2);" \
  "color: var(--fg-3);" \
  "border-color: var(--border-1);" \
  "background: var(--header-nav-hover-bg);" \
  "background: var(--header-nav-selected-bg);"; do
  if ! grep -q -- "$expected" "$theme_css"; then
    echo "Expected theme.css to consume token '$expected'." >&2
    exit 1
  fi
done

if grep -q -- '--bg-max:\\|--fg-1:\\|--primary:' "$theme_css"; then
  echo "Expected theme tokens to be defined in tokens.css, not theme.css." >&2
  exit 1
fi

for file in "$tokens_css" "$theme_css" "$prototype_css" "$journey_css" "$case_nav_css"; do
  for old_value in '#0B0B0B' '#ECE7E2' '#161616' '#242424' '236, 231, 226'; do
    if grep -q -- "$old_value" "$file"; then
      echo "Expected old pre-Aave theme value '$old_value' to be removed from $file." >&2
      exit 1
    fi
  done
done
