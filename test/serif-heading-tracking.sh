#!/usr/bin/env bash
set -euo pipefail

typography_css="assets/css/overrides/typography.css"

if ! grep -q 'letter-spacing: -0.02em;' "$typography_css"; then
  echo "Expected serif headings to use -0.02em tracking." >&2
  exit 1
fi

if grep -q 'letter-spacing: -0.03em;' "$typography_css"; then
  echo "Expected old -0.03em serif heading tracking to be removed." >&2
  exit 1
fi
