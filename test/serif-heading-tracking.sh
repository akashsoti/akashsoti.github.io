#!/usr/bin/env bash
set -euo pipefail

tokens_css="assets/css/overrides/tokens.css"
typography_css="assets/css/overrides/typography.css"

if grep -q -- '--type-heading-tracking' "$tokens_css"; then
  echo "Expected Inter heading tracking token to be removed." >&2
  exit 1
fi

if grep -q 'letter-spacing:' "$typography_css"; then
  echo "Expected headings to use natural Inter letter spacing." >&2
  exit 1
fi

if grep -q -- '--type-serif-tracking' "$typography_css"; then
  echo "Expected old serif-specific heading tracking token to be removed." >&2
  exit 1
fi

if grep -Eq -- '-0\.03em|-0\.02em' "$typography_css"; then
  echo "Expected old negative serif heading tracking to be removed." >&2
  exit 1
fi
