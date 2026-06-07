#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/writings-nav-external-icon-jekyll.log

page="_site/index.html"
css="assets/css/overrides/header.css"

if ! grep -q 'href="https://medium.com/@akashsoti" target="_blank" rel="noopener noreferrer"' "$page"; then
  echo "Expected Writings nav link to open Medium in a new tab." >&2
  exit 1
fi

if ! grep -q '<span class="top-nav__link-label">Writings</span>' "$page"; then
  echo "Expected Writings nav link label to render inside a label span." >&2
  exit 1
fi

if ! grep -q '<i class="ph ph-arrow-up-right top-nav__external-icon" aria-hidden="true"></i>' "$page"; then
  echo "Expected Writings nav link to render the Phosphor arrow-up-right icon." >&2
  exit 1
fi

if ! grep -q '<span class="sr-only">opens in a new tab</span>' "$page"; then
  echo "Expected Writings nav link to include accessible new-tab text." >&2
  exit 1
fi

if ! grep -q '.top-nav__external-icon' "$css"; then
  echo "Expected header stylesheet to define the external nav icon." >&2
  exit 1
fi

if ! grep -q 'margin-left: 0.35rem' "$css"; then
  echo "Expected external nav icon to sit after the label with compact spacing." >&2
  exit 1
fi
