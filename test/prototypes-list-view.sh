#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/prototypes-list-view-jekyll.log

page="_site/prototypes/index.html"
css="assets/css/overrides/prototypes.css"
head="_site/prototypes/index.html"

if grep -q '<iframe' "$page"; then
  echo "Expected prototypes page to use thumbnail links instead of iframe embeds." >&2
  exit 1
fi

if grep -q 'class="row"' "$page" || grep -q 'class="col-6"' "$page"; then
  echo "Expected prototypes page to stop using the old two-column grid classes." >&2
  exit 1
fi

if ! grep -q 'class="prototype-list section-bottom-margin"' "$page"; then
  echo "Expected prototypes page to render the list container." >&2
  exit 1
fi

item_count=$(grep -o 'class="prototype-list__item"' "$page" | wc -l | tr -d ' ')
if [[ "$item_count" != "10" ]]; then
  echo "Expected 10 prototype list items, found $item_count." >&2
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
  if ! grep -q "https://www.youtube.com/watch?v=$id" "$page"; then
    echo "Expected prototype item to link to YouTube video $id." >&2
    exit 1
  fi

  if grep -q "https://img.youtube.com/vi/$id/hqdefault.jpg" "$page"; then
    echo "Expected prototype item to stop using the letterboxed hqdefault thumbnail for $id." >&2
    exit 1
  fi

  if ! grep -q "https://i.ytimg.com/vi/$id/maxresdefault.jpg" "$page"; then
    echo "Expected prototype item to render the 16:9 max-res YouTube thumbnail for $id." >&2
    exit 1
  fi
done

play_overlay_count=$(grep -o 'class="prototype-list__play"' "$page" | wc -l | tr -d ' ')
if [[ "$play_overlay_count" != "10" ]]; then
  echo "Expected every prototype thumbnail to render a centered play button, found $play_overlay_count." >&2
  exit 1
fi

if ! grep -q '<i class="ph-fill ph-play" aria-hidden="true"></i>' "$page"; then
  echo "Expected prototype play button to use the Phosphor filled play icon." >&2
  exit 1
fi

for text in \
  '<h2>Sticky header navigation</h2>' \
  'The header stays pinned while the iPhone X flow moves, giving the user a stable wayfinding anchor.' \
  '<h2>Ride progress timing and shimmer</h2>' \
  'The progress-bar animation was tuned for a 60-second wait window: first 35% in 6 seconds with easeInOut, next 35% in 12 seconds with easeOut, next 20% in 12 seconds with easeInOut, and the final 10% in 30 seconds with linear motion and shimmer.' \
  'ride cancellations reduced by 70%.' \
  '<h2>Upgrade confirmation feedback</h2>' \
  '<h2>Rate card reveal</h2>' \
  '<h2>Notification bell feedback</h2>' \
  '<h2>iOS music app transitions</h2>' \
  '<h2>Multi-screen navigation rhythm</h2>' \
  '<h2>Shimmer loading state</h2>' \
  '<h2>Peak pricing meter</h2>' \
  '<h2>Ride rating interaction</h2>'; do
  if ! grep -q "$text" "$page"; then
    echo "Expected prototype copy '$text' to render." >&2
    exit 1
  fi
done

if ! grep -q '/assets/css/overrides/prototypes.css' "$head"; then
  echo "Expected prototypes stylesheet to be linked from the page head." >&2
  exit 1
fi

if ! grep -q '.prototype-list__item' "$css"; then
  echo "Expected prototypes stylesheet to define list item layout." >&2
  exit 1
fi

if ! grep -q 'max-width: 960px' "$css"; then
  echo "Expected prototype list content width to match the Work page content area." >&2
  exit 1
fi

if ! grep -q '.prototype-list__content h2' "$css"; then
  echo "Expected prototypes stylesheet to define prototype title styling." >&2
  exit 1
fi

if ! grep -q 'font-size: var(--type-section-title-size)' "$css"; then
  echo "Expected prototype titles to match the shared section/card title size token." >&2
  exit 1
fi

if ! grep -q 'line-height: var(--type-section-title-line-height)' "$css"; then
  echo "Expected prototype titles to match the shared section/card title line-height token." >&2
  exit 1
fi

if ! grep -q 'grid-template-columns: minmax(0, 3fr) minmax(260px, 2fr)' "$css"; then
  echo "Expected desktop prototype rows to use 60% text and 40% thumbnail columns." >&2
  exit 1
fi

if ! grep -q 'align-items: start' "$css"; then
  echo "Expected prototype row text and thumbnail to align to the top." >&2
  exit 1
fi

if ! grep -q '.prototype-list__item:first-child' "$css"; then
  echo "Expected prototypes stylesheet to remove the outer top separator." >&2
  exit 1
fi

if ! grep -q 'border-top: 0' "$css"; then
  echo "Expected first prototype row to remove the top separator." >&2
  exit 1
fi

if grep -q 'border-bottom: 1px solid rgba(0, 0, 0, 0.12)' "$css"; then
  echo "Expected prototype list to remove the outer bottom separator." >&2
  exit 1
fi

if ! grep -q 'border-radius: 20px' "$css"; then
  echo "Expected prototype thumbnails to have 20px rounded corners." >&2
  exit 1
fi

if ! grep -q 'aspect-ratio: 16 / 9' "$css"; then
  echo "Expected prototype thumbnails to keep a stable 16:9 frame." >&2
  exit 1
fi

if ! grep -q 'object-fit: cover' "$css"; then
  echo "Expected prototype thumbnails to fill the card frame." >&2
  exit 1
fi

if ! grep -q 'transform: scale(1.015)' "$css"; then
  echo "Expected prototype thumbnail images to slightly overscan and avoid edge artifacts." >&2
  exit 1
fi

if ! grep -q '.prototype-list__play' "$css"; then
  echo "Expected prototype stylesheet to define the centered play button." >&2
  exit 1
fi

if ! grep -q 'background: rgba(0, 0, 0, 0.48)' "$css"; then
  echo "Expected prototype play button to use a dark translucent glass surface." >&2
  exit 1
fi

if ! grep -q 'background: rgba(0, 0, 0, 0.6)' "$css"; then
  echo "Expected prototype play button hover state to stay dark and subtle." >&2
  exit 1
fi

if ! grep -q 'grid-template-columns: 1fr' "$css"; then
  echo "Expected mobile prototype rows to stack into one column." >&2
  exit 1
fi
