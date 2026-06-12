#!/usr/bin/env bash
set -euo pipefail

css="assets/css/overrides/case-study-nav.css"
js="assets/js/scripts.js"

bundle exec jekyll build >/tmp/case-study-legacy-wide-media-jekyll.log

if ! grep -q 'class="hero-image"' _site/blog/ola-shuttle-case-study/index.html; then
  echo "Expected older case studies to still render legacy hero-image blocks." >&2
  exit 1
fi

if ! grep -q 'class="full-width"' _site/blog/ola-shuttle-case-study/index.html; then
  echo "Expected older case studies to still render legacy full-width blocks." >&2
  exit 1
fi

if ! grep -Fq 'p.hero-image, p.full-width' "$js"; then
  echo "Expected legacy full-width image blocks to participate in side-nav overlap handling." >&2
  exit 1
fi

if ! grep -Fq -- '--case-study-wide-shift: 120px' "$css"; then
  echo "Expected desktop wide media to shift left by half the side-nav column/gap." >&2
  exit 1
fi

if ! grep -Fq '.case-study-content > p.full-width' "$css"; then
  echo "Expected direct legacy full-width paragraphs to receive side-nav wide layout." >&2
  exit 1
fi

if ! grep -Fq '.case-study-content > section > p.hero-image' "$css"; then
  echo "Expected section legacy hero images to receive side-nav wide layout." >&2
  exit 1
fi

if ! grep -Fq 'translateX(calc(-50% - var(--case-study-wide-shift)))' "$css"; then
  echo "Expected wide media to be centered against the viewport, not the shifted article column." >&2
  exit 1
fi

if ! grep -Fq 'width: calc(100vw - 40px)' "$css"; then
  echo "Expected legacy hero images to stay aligned inside the 20px responsive gutters before the side nav appears." >&2
  exit 1
fi
