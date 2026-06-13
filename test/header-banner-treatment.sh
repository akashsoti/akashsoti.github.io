#!/usr/bin/env bash
set -euo pipefail

css="assets/css/overrides/header.css"

for expected in \
  "--header-wash:" \
  "--header-grain-light:" \
  "--header-grain-dark:" \
  ".header::after" \
  "inset: 0 0 -2.25rem;" \
  "linear-gradient(to bottom, transparent 0%, transparent 58%, var(--body-bg) 100%)" \
  "radial-gradient(circle at 24% 32%" \
  "background-size: auto, auto, 3px 3px, 4px 4px;" \
  "html.theme-dark .header"; do
  if ! grep -Fq -- "$expected" "$css"; then
    echo "Expected header banner treatment CSS to include '$expected'." >&2
    exit 1
  fi
done
