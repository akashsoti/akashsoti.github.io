#!/usr/bin/env bash
set -euo pipefail

head="_includes/head.html"
tokens_css="assets/css/overrides/tokens.css"
typography_css="assets/css/overrides/typography.css"
theme_css="assets/css/overrides/theme.css"
soehne_font="assets/fonts/test-soehne-buch.woff2"

if [[ ! -f "$tokens_css" ]]; then
  echo "Expected centralized design tokens at $tokens_css." >&2
  exit 1
fi

tokens_line="$(grep -n 'assets/css/overrides/tokens.css' "$head" | cut -d: -f1)"
base_line="$(grep -n 'assets/css/style.css' "$head" | cut -d: -f1)"
typography_line="$(grep -n 'assets/css/overrides/typography.css' "$head" | cut -d: -f1)"
theme_line="$(grep -n 'assets/css/overrides/theme.css' "$head" | cut -d: -f1)"

if [[ -z "$tokens_line" || -z "$base_line" || -z "$typography_line" || -z "$theme_line" ]]; then
  echo "Expected head to include tokens, base, typography, and theme stylesheets." >&2
  exit 1
fi

if (( tokens_line >= base_line || tokens_line >= typography_line || tokens_line >= theme_line )); then
  echo "Expected tokens.css to load before base, typography, and theme CSS." >&2
  exit 1
fi

if [[ -e "$soehne_font" ]]; then
  echo "Expected Test Soehne font file to be removed; the site should use Inter again." >&2
  exit 1
fi

if git grep -n -E 'Test Soehne|test-soehne|Soehne' -- assets/css _includes _layouts _posts >/tmp/soehne-grep.log 2>/dev/null; then
  cat /tmp/soehne-grep.log >&2
  echo "Expected Test Soehne references to be removed from site code." >&2
  exit 1
fi

for expected in \
  ':root {' \
  'html.theme-dark {' \
  '--font-family-base: Inter, "Inter Fallback", sans-serif;' \
  '--font-family-sans: var(--font-family-ui);' \
  '--font-family-heading: var(--font-family-base);' \
  '--type-body-size: 16px;' \
  '--primary: #9896ff;' \
  '@supports (color: color(display-p3 1 1 1))' \
  '@media (color-gamut: p3)' \
  '--body-bg: var(--bg-max);' \
  '--card-bg: var(--bg-1);'; do
  if ! grep -q -- "$expected" "$tokens_css"; then
    echo "Expected tokens.css to include '$expected'." >&2
    exit 1
  fi
done

if grep -q -- '--font-family-[a-z-]*:\\|--type-[a-z-]*:' "$typography_css"; then
  echo "Expected typography.css to consume typography tokens, not define them." >&2
  exit 1
fi

if grep -q -- '--primary:\\|--bg-[a-z0-9-]*:\\|--fg-[a-z0-9-]*:\\|--shadow-[a-z0-9-]*:\\|--selected:' "$theme_css"; then
  echo "Expected theme.css to consume theme tokens, not define them." >&2
  exit 1
fi

if ! awk '/html\.theme-dark body \{/ { in_rule = 1 } in_rule && /background: var\(--body-bg\);/ { found = 1 } in_rule && /\}/ { in_rule = 0 } END { exit found ? 0 : 1 }' "$theme_css"; then
  echo "Expected dark-mode body background to override the legacy compiled black background." >&2
  exit 1
fi

used_custom_properties="$(
  grep -Roh -- 'var(--[A-Za-z0-9_-]*' assets/css/overrides assets/scss \
    | sed 's/var(//' \
    | sort -u
)"

defined_custom_properties="$(
  grep -Roh -- '--[A-Za-z0-9_-]*:' assets/css/overrides assets/scss \
    | sed 's/:$//' \
    | sort -u
)"

for custom_property in $used_custom_properties; do
  case "$custom_property" in
    --case-study-dot-y|--case-study-nav-index)
      continue
      ;;
  esac

  if ! printf '%s\n' "$defined_custom_properties" | grep -qx -- "$custom_property"; then
    echo "Expected CSS custom property $custom_property to be defined before it is used." >&2
    exit 1
  fi
done
