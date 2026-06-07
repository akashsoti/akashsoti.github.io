#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/business-impact-text-jekyll.log

post="_site/blog/feet-on-street-app/index.html"

for image in slide-38.png slide-40.png; do
  if grep -q "/assets/img/fos-app/$image" "$post"; then
    echo "Expected $image to be replaced by text." >&2
    exit 1
  fi
done

for alt_text in \
  'Feet on Street app relationship and real-time tracking principle' \
  'Business impact metrics for the Feet on Street app'; do
  if grep -q "$alt_text" "$post"; then
    echo "Expected image alt text '$alt_text' to be removed." >&2
    exit 1
  fi
done

if grep -q 'The work contributed to a 20% increase in orders, 33% increase in credit depth, and 25% on-time collection.' "$post"; then
  echo "Expected the repeated business impact metrics sentence to be removed from the intro paragraph." >&2
  exit 1
fi

if grep -q 'class="case-study-quote"' "$post"; then
  echo "Expected the quote to use the regular blockquote style, not the custom quote class." >&2
  exit 1
fi

if ! grep -q '<blockquote>' "$post"; then
  echo "Expected the quote image to be replaced by a regular blockquote." >&2
  exit 1
fi

for text in \
  'We are' \
  'not replacing the 30 year old' \
  'relationship between retailers and BDOs' \
  'we are enhancing' \
  'FOS app is that' \
  'relationship.'; do
  if ! grep -q "$text" "$post"; then
    echo "Expected quote text '$text' to render." >&2
    exit 1
  fi
done

if ! grep -q 'class="case-study-impact-metrics"' "$post"; then
  echo "Expected the business impact image to be replaced by text metrics." >&2
  exit 1
fi

impact_line=$(grep -n '<h3>Business impact</h3>' "$post" | cut -d: -f1)
metrics_line=$(grep -n 'class="case-study-impact-metrics"' "$post" | cut -d: -f1)
quote_line=$(grep -n '<blockquote>' "$post" | cut -d: -f1)

if [[ -z "$impact_line" || -z "$metrics_line" || -z "$quote_line" ]]; then
  echo "Expected business impact heading, metrics, and quote to render." >&2
  exit 1
fi

if (( metrics_line <= impact_line )); then
  echo "Expected business impact metrics to appear inside the Business impact section." >&2
  exit 1
fi

if (( quote_line <= metrics_line )); then
  echo "Expected the business impact quote to come after the bold metrics." >&2
  exit 1
fi

for text in \
  '20%' \
  'Increase in orders' \
  '33%' \
  'Increase in credit depth' \
  '25%' \
  'On time collection'; do
  if ! grep -q "$text" "$post"; then
    echo "Expected business impact text '$text' to render." >&2
    exit 1
  fi
done

if ! grep -q '/assets/css/overrides/case-study-text-blocks.css' "$post"; then
  echo "Expected the text replacement stylesheet to be linked." >&2
  exit 1
fi

if grep -q 'case-study-quote' assets/css/overrides/case-study-text-blocks.css; then
  echo "Expected the regular blockquote to avoid custom quote styling." >&2
  exit 1
fi
