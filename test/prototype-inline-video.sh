#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/prototype-inline-video-jekyll.log

page="_site/prototypes/index.html"
script="assets/js/scripts.js"
css="assets/css/overrides/prototypes.css"

if grep -q '<iframe' "$page"; then
  echo "Expected prototypes page to render thumbnails first and create iframes only after click." >&2
  exit 1
fi

video_id_count=$({ grep -o 'data-video-id="' "$page" || true; } | wc -l | tr -d ' ')
if [[ "$video_id_count" != "10" ]]; then
  echo "Expected every prototype thumbnail to expose a data-video-id, found $video_id_count." >&2
  exit 1
fi

video_title_count=$({ grep -o 'data-video-title="' "$page" || true; } | wc -l | tr -d ' ')
if [[ "$video_title_count" != "10" ]]; then
  echo "Expected every prototype thumbnail to expose a data-video-title, found $video_title_count." >&2
  exit 1
fi

for id in \
  YGfbdyfPOF0 \
  1UfzlKRpKdo \
  4QPG3aR4_Vo \
  W9co4DMRNiM \
  Ll-6nb8hn2A \
  j6ErGI-S_Jw \
  9gqtEASDaTQ \
  S1-24yZ8EXQ \
  rYmOfY0X630 \
  WybrxIW-j7M; do
  if ! grep -q "data-video-id=\"$id\"" "$page"; then
    echo "Expected prototype thumbnail to expose data-video-id for $id." >&2
    exit 1
  fi

  if ! grep -q "https://www.youtube.com/watch?v=$id" "$page"; then
    echo "Expected prototype thumbnail to keep a YouTube fallback link for $id." >&2
    exit 1
  fi
done

for expected in \
  'prototype-list__thumbnail\[data-video-id\]' \
  'event.preventDefault()' \
  'https://www.youtube-nocookie.com/embed/' \
  'autoplay=1' \
  'prototype-list__embed' \
  'allowFullscreen'; do
  if ! grep -q "$expected" "$script"; then
    echo "Expected scripts.js to include inline prototype video behavior: $expected." >&2
    exit 1
  fi
done

if ! grep -q '.prototype-list__embed' "$css"; then
  echo "Expected prototypes stylesheet to style inline video embeds." >&2
  exit 1
fi

if ! grep -q 'border: 0' "$css"; then
  echo "Expected inline video embeds to remove iframe borders." >&2
  exit 1
fi
