#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/work-card-responsive-layout-jekyll.log

home="_site/index.html"
css="assets/css/overrides/work-cards.css"

if ! grep -q '/assets/css/overrides/work-cards.css' "$home"; then
  echo "Expected the Work card responsive stylesheet to be linked on the home page." >&2
  exit 1
fi

if [[ ! -f "$css" ]]; then
  echo "Expected the Work card responsive stylesheet to exist." >&2
  exit 1
fi

for expected in \
  '#home .row {' \
  'display: grid' \
  'grid-template-columns: 1fr' \
  '#home .row > [class^="col"]' \
  'width: 100%' \
  'float: none' \
  '#home .posts {' \
  'height: 100%' \
  '#home .posts .description' \
  '-webkit-line-clamp: 2' \
  '@media only screen and (min-width: 720px)' \
  'grid-template-columns: repeat(2, minmax(0, 1fr))'; do
  if ! grep -Fq -- "$expected" "$css"; then
    echo "Expected Work card responsive CSS to include '$expected'." >&2
    exit 1
  fi
done
