#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/post-nav-work-order-jekyll.log

first_post="_site/blog/feet-on-street-app/index.html"
middle_post="_site/blog/ola-shuttle-case-study/index.html"
last_post="_site/blog/punchh-website-redesign/index.html"

if grep -q 'class="prev' "$first_post"; then
  echo "Expected the first Work case study to have no left-side previous footer link." >&2
  exit 1
fi

if ! grep -q 'class="next image" href="/blog/ola-shuttle-case-study/"' "$first_post"; then
  echo "Expected the first Work case study to link to Ola Shuttle on the right side." >&2
  exit 1
fi

if ! grep -q 'class="prev image" href="/blog/feet-on-street-app/"' "$middle_post"; then
  echo "Expected Ola Shuttle to link back to Feet on Street on the left side." >&2
  exit 1
fi

if ! grep -q 'class="next image" href="/blog/ola-outstation-case-study/"' "$middle_post"; then
  echo "Expected Ola Shuttle to link forward to Ola Outstation on the right side." >&2
  exit 1
fi

if ! grep -q 'class="prev image" href="/blog/farmerboys/"' "$last_post"; then
  echo "Expected the last Work case study to link back to Farmerboys on the left side." >&2
  exit 1
fi

if grep -q 'class="next' "$last_post"; then
  echo "Expected the last Work case study to have no right-side next footer link." >&2
  exit 1
fi
