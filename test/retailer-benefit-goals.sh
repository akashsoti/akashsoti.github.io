#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/retailer-benefit-goals-jekyll.log

post="_site/blog/feet-on-street-app/index.html"

if grep -q '/assets/img/fos-app/slide-28.png' "$post"; then
  echo "Expected the goals image to be replaced by text." >&2
  exit 1
fi

if grep -q 'Improved flow where retailers can order again after paying' "$post"; then
  echo "Expected the goals image alt text to be removed." >&2
  exit 1
fi

if grep -q 'class="case-study-goals' "$post"; then
  echo "Expected the goals block to use regular section and list markup, not the custom goals component." >&2
  exit 1
fi

if ! grep -q '<h3 id="fos-goals-title">Goals</h3>' "$post"; then
  echo "Expected the goals title to use the regular h3 section-title treatment." >&2
  exit 1
fi

if ! grep -q '<ol aria-labelledby="fos-goals-title">' "$post"; then
  echo "Expected goals to render as a regular numbered list." >&2
  exit 1
fi

for text in \
  '<li><strong>130k</strong> Increase no. of buyers</li>' \
  '<li><strong>$20M</strong> Increase GMS</li>' \
  '<li><strong>-6%</strong> Bring cost down</li>'; do
  if ! grep -q -- "$text" "$post"; then
    echo "Expected goals text '$text' to render." >&2
    exit 1
  fi
done

key_line=$(grep -n '<h3>Key customer problems</h3>' "$post" | cut -d: -f1)
benefit_line=$(grep -n '<h3>Retailer benefit</h3>' "$post" | cut -d: -f1)
goals_line=$(grep -n '<h3 id="fos-goals-title">Goals</h3>' "$post" | cut -d: -f1)
design_line=$(grep -n '<h3>Design direction</h3>' "$post" | cut -d: -f1)
design_goals_line=$(grep -n 'Keeping these goals in mind, the design direction focused on three principles' "$post" | cut -d: -f1 || true)
first_design_item_line=$(grep -n '<h4>1. Easy management for BDOs</h4>' "$post" | cut -d: -f1 || true)

if [[ -z "$key_line" || -z "$benefit_line" || -z "$goals_line" || -z "$design_line" || -z "$design_goals_line" || -z "$first_design_item_line" ]]; then
  echo "Expected key customer problems, retailer benefit, design direction, goals, transition copy, and design item sections to render." >&2
  exit 1
fi

if grep -q '<h3>Product direction</h3>' "$post"; then
  echo "Expected Product direction to be renamed to Design direction." >&2
  exit 1
fi

if (( benefit_line <= key_line )); then
  echo "Expected Retailer benefit to appear after Key customer problems." >&2
  exit 1
fi

if (( design_line <= benefit_line || goals_line <= design_line || design_goals_line <= goals_line || first_design_item_line <= design_goals_line )); then
  echo "Expected Goals to sit inside Design direction before the design principle transition and design items." >&2
  exit 1
fi

between_design_and_goals=$(sed -n "${design_line},${goals_line}p" "$post")

if printf '%s' "$between_design_and_goals" | grep -q '</section>'; then
  echo "Expected Design direction to stay open until the Goals list renders." >&2
  exit 1
fi

if printf '%s' "$between_design_and_goals" | grep -q '<section class="section-bottom-margin">'; then
  echo "Expected Goals to be part of Design direction, not a separate section." >&2
  exit 1
fi

between_transition_and_items=$(sed -n "${design_goals_line},${first_design_item_line}p" "$post")

if ! printf '%s' "$between_transition_and_items" | grep -q '</section>'; then
  echo "Expected Design direction to close after the goals-aware transition copy." >&2
  exit 1
fi

if grep -q '/assets/css/overrides/goals.css' "$post"; then
  echo "Expected the custom goals stylesheet to be removed for the regular numbered list." >&2
  exit 1
fi
