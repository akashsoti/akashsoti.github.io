#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/shuttle-journey-map-table-jekyll.log

post="_site/blog/ola-shuttle-case-study/index.html"

if grep -q '/assets/img/userjourney.jpg' "$post"; then
  echo "Expected the Shuttle user journey image to be replaced by HTML." >&2
  exit 1
fi

if ! grep -q 'class="journey-map shuttle-journey-map"' "$post"; then
  echo "Expected the Shuttle journey map table component to render." >&2
  exit 1
fi

if ! grep -q 'Shuttle user journey and challenges across planning, pickup, boarding, drop-off, and return travel' "$post"; then
  echo "Expected the Shuttle journey map table to keep an accessible caption." >&2
  exit 1
fi

for expected in \
  '<th scope="col">Planning the trip</th>' \
  '<th scope="col">Pickup stop discovery</th>' \
  '<th scope="col">Boarding and in-trip</th>' \
  '<th scope="col">Drop off to destination</th>' \
  '<th scope="col">Travelling back home</th>' \
  'Gather knowledge about routes running.' \
  'Can I track my bus live on a map somewhere' \
  'Is there an easier way to rebook a bus on the route I travelled earlier today'; do
  if ! grep -q "$expected" "$post"; then
    echo "Expected Shuttle journey map table content '$expected'." >&2
    exit 1
  fi
done

if grep -q '<h3>[[:space:]]*Prototype[[:space:]]*</h3>' "$post"; then
  echo "Expected the Shuttle Prototype section to be removed." >&2
  exit 1
fi

if grep -q 'marvelapp.com/1853h31' "$post"; then
  echo "Expected the Shuttle prototype iframe to be removed." >&2
  exit 1
fi

if ! grep -q '.post figure.journey-map' assets/css/overrides/journey-map.css; then
  echo "Expected the journey map stylesheet to support the generic journey-map component." >&2
  exit 1
fi

if ! grep -Fq 'figure.journey-map' assets/js/scripts.js; then
  echo "Expected generic journey maps to participate in side-nav overlap handling." >&2
  exit 1
fi
