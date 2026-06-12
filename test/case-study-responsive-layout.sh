#!/usr/bin/env bash
set -euo pipefail

case_study_css="assets/css/overrides/case-study-nav.css"
header_css="assets/css/overrides/header.css"

if ! grep -q '@media only screen and (min-width: 800px) and (max-width: 1247px)' "$case_study_css"; then
  echo "Expected case-study CSS to define the tablet desktop breakpoint before the side nav appears." >&2
  exit 1
fi

for expected in \
  '.container--post' \
  'max-width: none' \
  'padding: 0 20px' \
  '.case-study-sidebar' \
  'display: none' \
  'max-width: none'; do
  if ! grep -q "$expected" "$case_study_css"; then
    echo "Expected responsive case-study CSS to include '$expected'." >&2
    exit 1
  fi
done

if ! grep -q '@media only screen and (min-width: 800px) and (max-width: 1247px)' "$header_css"; then
  echo "Expected header CSS to define the tablet desktop breakpoint before the side nav appears." >&2
  exit 1
fi

for expected in \
  'max-width: none' \
  'padding: 0 20px'; do
  if ! grep -q "$expected" "$header_css"; then
    echo "Expected responsive header CSS to include '$expected'." >&2
    exit 1
  fi
done
