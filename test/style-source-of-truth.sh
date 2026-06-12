#!/usr/bin/env bash
set -euo pipefail

legacy_css="assets/css/style.css"
scss_entry="assets/scss/style.scss"
overrides_readme="assets/css/overrides/README.md"

if [[ ! -f "$legacy_css" ]]; then
  echo "Expected legacy compiled base CSS at $legacy_css." >&2
  exit 1
fi

if [[ -f "assets/css/style.scss" ]]; then
  echo "Expected no Jekyll-generated wrapper at assets/css/style.scss; Sass generation is not the active source of truth." >&2
  exit 1
fi

if [[ ! -f "$scss_entry" ]]; then
  echo "Expected legacy base SCSS entry at $scss_entry." >&2
  exit 1
fi

if [[ ! -f "$overrides_readme" ]]; then
  echo "Expected CSS architecture notes at $overrides_readme." >&2
  exit 1
fi

for expected in \
  "\`tokens.css\` is the only place to define design tokens" \
  "\`theme.css\` and \`typography.css\` consume tokens" \
  "\`style.css\` is the legacy compiled base layer"; do
  if ! grep -q -- "$expected" "$overrides_readme"; then
    echo "Expected CSS architecture note missing: $expected" >&2
    exit 1
  fi
done

if grep -RIn -- '--type-[a-z-]*:\\|--font-family-[a-z-]*:\\|--primary:\\|--bg-[a-z0-9-]*:\\|--fg-[a-z0-9-]*:' assets/scss "$legacy_css"; then
  echo "Expected design tokens to stay out of legacy base SCSS/CSS." >&2
  exit 1
fi

for old_font in 'fonts.googleapis.com' 'fonts.gstatic.com' 'Google Sans Flex' 'EB Garamond'; do
  if grep -RIn "$old_font" "$legacy_css" "$scss_entry" assets/scss; then
    echo "Expected old font reference to be absent from generated/base styles: $old_font" >&2
    exit 1
  fi
done
