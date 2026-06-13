#!/usr/bin/env bash
set -euo pipefail

head="_includes/head.html"
tokens_css="assets/css/overrides/tokens.css"
scss_config="assets/scss/_config.scss"

if grep -q 'rsms.me' "$head"; then
  echo "Expected Inter to be self-hosted, not loaded from rsms.me." >&2
  exit 1
fi

for old_font in 'fonts.googleapis.com' 'fonts.gstatic.com' 'Google Sans Flex' 'EB Garamond'; do
  if grep -RIn "$old_font" "$head" assets/css/overrides assets/scss; then
    echo "Expected old font reference to be removed: $old_font" >&2
    exit 1
  fi
done

for font_file in assets/fonts/InterVariable.woff2 assets/fonts/InterVariable-Italic.woff2; do
  if [[ ! -s "$font_file" ]]; then
    echo "Expected self-hosted Inter font file at $font_file." >&2
    exit 1
  fi
done

for expected in \
  '@font-face {' \
  'font-family: Inter;' \
  'font-weight: 100 900;' \
  'src: url("../../fonts/InterVariable.woff2") format("woff2");' \
  'src: url("../../fonts/InterVariable-Italic.woff2") format("woff2");' \
  'font-family: "Inter Fallback";' \
  'ascent-override: 89.79%;' \
  'size-adjust: 107.89%;' \
  'font-family: Inter, "Inter Fallback", sans-serif;' \
  "font-feature-settings: 'liga' 1, 'calt' 1;" \
  '--font-family-base: Inter, "Inter Fallback", sans-serif;' \
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
