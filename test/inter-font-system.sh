#!/usr/bin/env bash
set -euo pipefail

head="_includes/head.html"
tokens_css="assets/css/overrides/tokens.css"
scss_config="assets/scss/_config.scss"

if ! grep -q '<link rel="preconnect" href="https://rsms.me/">' "$head"; then
  echo "Expected head to preconnect to rsms.me for Inter." >&2
  exit 1
fi

if ! grep -q '<link rel="stylesheet" href="https://rsms.me/inter/inter.css">' "$head"; then
  echo "Expected head to load Inter from rsms.me." >&2
  exit 1
fi

for old_font in 'fonts.googleapis.com' 'fonts.gstatic.com' 'Google Sans Flex' 'EB Garamond'; do
  if grep -RIn "$old_font" "$head" assets/css/overrides assets/scss; then
    echo "Expected old font reference to be removed: $old_font" >&2
    exit 1
  fi
done

for expected in \
  'font-family: Inter, sans-serif;' \
  "font-feature-settings: 'liga' 1, 'calt' 1;" \
  '@supports (font-variation-settings: normal)' \
  'font-family: InterVariable, Inter, sans-serif;' \
  '--font-family-base: Inter, sans-serif;' \
  '--font-family-ui: var(--font-family-base);' \
  '--font-family-sans: var(--font-family-ui);' \
  '--font-family-heading: var(--font-family-base);'; do
  if ! grep -q -- "$expected" "$tokens_css"; then
    echo "Expected tokens.css to include '$expected'." >&2
    exit 1
  fi
done

if ! grep -q '$sans-serif: var(--font-family-ui);' "$scss_config"; then
  echo "Expected SCSS sans-serif variable to defer to typography.css." >&2
  exit 1
fi

if ! grep -q '$serif: var(--font-family-heading);' "$scss_config"; then
  echo "Expected SCSS heading variable to defer to typography.css." >&2
  exit 1
fi
