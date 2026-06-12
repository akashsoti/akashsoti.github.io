#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/retailer-journey-map-table-jekyll.log

post="_site/blog/feet-on-street-app/index.html"

if grep -q '/assets/img/fos-app/retailer-journey-map.png' "$post"; then
  echo "Expected the retailer journey map image to be replaced by HTML." >&2
  exit 1
fi

if ! grep -q 'class="retailer-journey-map' "$post"; then
  echo "Expected the retailer journey map table component to render." >&2
  exit 1
fi

if ! grep -q '<th scope="col">Planning</th>' "$post"; then
  echo "Expected Planning phase column in retailer journey map table." >&2
  exit 1
fi

if ! grep -q '<th scope="row">Customer pain points</th>' "$post"; then
  echo "Expected Customer pain points row in retailer journey map table." >&2
  exit 1
fi

if ! grep -q 'Build intelligence into the system so that PSR knows what to pitch' "$post"; then
  echo "Expected opportunity content to be rendered as text." >&2
  exit 1
fi

if ! grep -q '/assets/css/overrides/journey-map.css' "$post"; then
  echo "Expected the journey map table stylesheet to be linked." >&2
  exit 1
fi

if ! grep -Fq -- '--case-study-wide-shift: 120px' assets/css/overrides/case-study-nav.css; then
  echo "Expected the journey map table to keep its wide viewport behavior when section nav is visible." >&2
  exit 1
fi

if ! grep -q 'width: min(80vw, 1280px)' assets/css/overrides/journey-map.css; then
  echo "Expected the journey map table to use the restored wide viewport width." >&2
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
