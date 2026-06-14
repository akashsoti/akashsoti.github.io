#!/usr/bin/env bash
set -euo pipefail

head="_includes/head.html"
header_css="assets/css/overrides/header.css"

style_line="$(grep -n 'assets/css/style.css' "$head" | cut -d: -f1)"
header_line="$(grep -n 'assets/css/overrides/header.css' "$head" | cut -d: -f1)"

if [[ -z "$style_line" || -z "$header_line" || "$header_line" -le "$style_line" ]]; then
  echo "Expected header.css to load after the legacy compiled stylesheet." >&2
  exit 1
fi

if grep -q -- 'touring.jpg' "$header_css"; then
  echo "Expected header override CSS not to reference the old banner image." >&2
  exit 1
fi

if ! awk '/^\.header[[:space:]]*\{/ { in_rule = 1 } in_rule && /background-image: url\("\.\.\/\.\.\/img\/akash-banner\.png"\);/ { found = 1 } in_rule && /^\}/ { in_rule = 0 } END { exit found ? 0 : 1 }' "$header_css"; then
  echo "Expected light-mode header to use akash-banner.png." >&2
  exit 1
fi

if ! awk '/^html\.theme-dark \.header[[:space:]]*\{/ { in_rule = 1 } in_rule && /background-image: url\("\.\.\/\.\.\/img\/akash-banner\.png"\);/ { found = 1 } in_rule && /^\}/ { in_rule = 0 } END { exit found ? 0 : 1 }' "$header_css"; then
  echo "Expected dark-mode header to override the legacy banner image with akash-banner.png." >&2
  exit 1
fi
