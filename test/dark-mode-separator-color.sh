#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/dark-mode-separator-color-jekyll.log

tokens_css="assets/css/overrides/tokens.css"
theme_css="assets/css/overrides/theme.css"
prototype_css="assets/css/overrides/prototypes.css"
journey_css="assets/css/overrides/journey-map.css"

if ! grep -q -- '--border-1: #ffffff14;' "$tokens_css" || ! grep -q 'border-color: var(--border-1)' "$theme_css"; then
  echo "Expected dark theme post/footer separators to use Aave border token." >&2
  exit 1
fi

if ! grep -q 'table,' "$theme_css" || ! grep -q 'border-color: var(--border-1)' "$theme_css"; then
  echo "Expected dark theme table separators to use Aave border token." >&2
  exit 1
fi

if ! grep -q 'border-top: 1px solid var(--separator-color)' "$prototype_css" || ! grep -q 'border-color: var(--separator-color)' "$prototype_css"; then
  echo "Expected dark theme prototype separators to use theme separator token." >&2
  exit 1
fi

if ! grep -q 'html.theme-dark .retailer-journey-map__scroller' "$journey_css" || ! grep -q 'border-color: var(--separator-color)' "$journey_css"; then
  echo "Expected dark theme journey-map separators to use theme separator token." >&2
  exit 1
fi

for old_separator in \
  'html.theme-dark .postNav,html.theme-dark .footer .container { border-color: rgba(255, 255, 255' \
  'html.theme-dark .prototype-list__item,html.theme-dark .prototype-list__item:last-child { border-color: rgba(255, 255, 255' \
  'html.theme-dark .retailer-journey-map__table th,html.theme-dark .retailer-journey-map__table td { border-color: rgba(236, 231, 226'; do
  if tr '\n' ' ' < "$theme_css" | grep -q "$old_separator" || \
     tr '\n' ' ' < "$prototype_css" | grep -q "$old_separator" || \
     tr '\n' ' ' < "$journey_css" | grep -q "$old_separator"; then
    echo "Expected dark separators to stop reusing white-tinted separator colors." >&2
    exit 1
  fi
done
