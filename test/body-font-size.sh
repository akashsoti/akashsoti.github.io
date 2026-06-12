#!/usr/bin/env bash
set -euo pipefail

source_scss="assets/scss/breakpoints/_mobileup.scss"
generated_css="_site/assets/css/style.css"

if ! grep -q 'font-size: 16px; // 16px base font size' "$source_scss"; then
  echo "Expected body source SCSS to use a true 16px base font size." >&2
  exit 1
fi

bundle exec jekyll build >/tmp/body-font-size-jekyll.log

if ! grep -q 'font-size:16px' "$generated_css"; then
  echo "Expected compiled body CSS to use a true 16px base font size." >&2
  exit 1
fi

if grep -q 'font-size:120%' "$generated_css"; then
  echo "Expected compiled body CSS not to use the old 120% body font size." >&2
  exit 1
fi
