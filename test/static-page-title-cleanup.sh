#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/static-page-title-cleanup-jekyll.log

prototypes="_site/prototypes/index.html"
about="_site/about/index.html"
css="assets/css/overrides/prototypes.css"

for page in "$prototypes" "$about"; do
  if grep -q 'class="section-bottom-margin page-title-block"' "$page"; then
    echo "Expected static pages to remove the title intro block: $page" >&2
    exit 1
  fi

  if grep -q 'class="pageTitle"' "$page"; then
    echo "Expected static pages to remove the visible page title: $page" >&2
    exit 1
  fi

  if grep -q 'class="pageTitle-helper"' "$page"; then
    echo "Expected static pages to remove the visible page subtitle: $page" >&2
    exit 1
  fi
done

for text in \
  'High-fidelity prototypes made using Framer' \
  'I design things for people...ergo I am a developer.'; do
  if grep -q "$text" "$prototypes" || grep -q "$text" "$about"; then
    echo "Expected static page subtitle '$text' to be removed." >&2
    exit 1
  fi
done

if ! grep -q 'border-top: 1px solid var(--separator-color)' "$css"; then
  echo "Expected prototype row separator color to stay defined." >&2
  exit 1
fi

if ! grep -q '.prototype-list__item:first-child' "$css"; then
  echo "Expected prototype list to remove the outer top separator." >&2
  exit 1
fi

if ! grep -q 'border: 1px solid var(--separator-color)' "$css"; then
  echo "Expected prototype thumbnail cards to use a stroke matching the light separator." >&2
  exit 1
fi

if ! grep -q 'border-color: var(--separator-color)' "$css"; then
  echo "Expected prototype thumbnail cards to use the theme separator stroke." >&2
  exit 1
fi
