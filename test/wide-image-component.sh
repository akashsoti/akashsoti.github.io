#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/wide-image-jekyll.log

post="_site/blog/feet-on-street-app/index.html"

if grep -q 'class="wide-image"' "$post"; then
  echo "Expected the retailer journey map to stop rendering as a wide image." >&2
  exit 1
fi

if grep -q '/assets/img/fos-app/retailer-journey-map.png' "$post"; then
  echo "Expected the retailer journey map asset to be replaced by HTML." >&2
  exit 1
fi

if grep -q '/assets/img/fos-app/slide-17.png' "$post"; then
  echo "Expected the old slide-17 journey image to be removed from the post." >&2
  exit 1
fi

if ! grep -q 'class="retailer-journey-map' "$post"; then
  echo "Expected the retailer journey map table to render." >&2
  exit 1
fi

if ! grep -q 'Retailer journey map across planning, ordering, delivery, and reconciliation' "$post"; then
  echo "Expected the retailer journey map table to keep an accessible caption." >&2
  exit 1
fi

if grep -q '/assets/img/fos-app/slide-29.png' "$post"; then
  echo "Expected the removed business goals image block to be absent from the post." >&2
  exit 1
fi

if grep -q 'Business goals for the Feet on Street app' "$post"; then
  echo "Expected the removed business goals image alt text to be absent from the post." >&2
  exit 1
fi
