#!/usr/bin/env bash
set -euo pipefail

header="_includes/header.html"
header_css="assets/css/overrides/header.css"
scripts_js="assets/js/scripts.js"

for expected in \
  'class="theme-toggle__icon-wrap"' \
  'ph ph-moon theme-toggle__icon' \
  'theme-toggle__text'; do
  if ! grep -q -- "$expected" "$header"; then
    echo "Expected theme toggle markup to include '$expected'." >&2
    exit 1
  fi
done

for expected in \
  'width: 40px;' \
  'height: 40px;' \
  'border-radius: 999px;' \
  '.theme-toggle:active' \
  'transform: scale(0.92);' \
  '.theme-toggle__icon-wrap' \
  '@keyframes theme-toggle-icon-enter' \
  '@media (prefers-reduced-motion: reduce)'; do
  if ! grep -q -- "$expected" "$header_css"; then
    echo "Expected Aave-like theme toggle CSS to include '$expected'." >&2
    exit 1
  fi
done

for expected in \
  'var themeAudioContext = null;' \
  'window.AudioContext || window.webkitAudioContext' \
  'function playThemeToggleSound()' \
  'function animateThemeToggleIcon(toggle)' \
  'context.createOscillator()' \
  'context.createBufferSource()' \
  'context.createGain()' \
  'toggleIcon.classList.remove("ph-moon", "ph-sun")' \
  'toggleIcon.classList.add(isDark ? "ph-moon" : "ph-sun")' \
  'applyTheme(nextTheme, true);' \
  'playThemeToggleSound();'; do
  if ! grep -q -- "$expected" "$scripts_js"; then
    echo "Expected theme toggle sound/state JS to include '$expected'." >&2
    exit 1
  fi
done

if grep -q -- 'theme-toggle__track\|theme-toggle__thumb\|theme-toggle__icon--sun\|theme-toggle__icon--moon' "$header" "$header_css"; then
  echo "Expected theme toggle to use one Aave-style round icon button, not a pill switch." >&2
  exit 1
fi
