#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/design-direction-jekyll.log

post="_site/blog/feet-on-street-app/index.html"

if ! grep -q '<h3>Design direction</h3>' "$post"; then
  echo "Expected the section to be titled Design direction." >&2
  exit 1
fi

if grep -q '<h3>Product direction</h3>' "$post"; then
  echo "Expected Product direction heading to be removed." >&2
  exit 1
fi

for text in \
  'From a design point of view' \
  'task-first experience' \
  'which retailers to visit' \
  'Keeping these goals in mind, the design direction focused on three principles'; do
  if ! grep -q "$text" "$post"; then
    echo "Expected design direction copy '$text' to render." >&2
    exit 1
  fi
done

if grep -q 'The product vision was' "$post"; then
  echo "Expected product-vision phrasing to be replaced with design point-of-view phrasing." >&2
  exit 1
fi
