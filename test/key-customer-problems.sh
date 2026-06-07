#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/key-customer-problems-jekyll.log

post="_site/blog/feet-on-street-app/index.html"

if grep -q '/assets/img/fos-app/slide-19.png' "$post"; then
  echo "Expected the first key customer problem image to be removed." >&2
  exit 1
fi

if grep -q 'Credit unblocking flow showing the wait between payment and the next order' "$post"; then
  echo "Expected the first key customer problem image alt text to be removed." >&2
  exit 1
fi

if ! grep -q '<h4>1. Credit unblocking</h4>' "$post"; then
  echo "Expected the first key customer problem to have a numbered title." >&2
  exit 1
fi

if ! grep -q '<h4>2. Invoice reconciliation</h4>' "$post"; then
  echo "Expected the second key customer problem to have a numbered title." >&2
  exit 1
fi

if grep -q '/assets/img/fos-app/slide-21.png' "$post"; then
  echo "Expected the second key customer problem image to be removed." >&2
  exit 1
fi

if grep -q 'Trust issues caused by duplicate invoices and payment tracking gaps' "$post"; then
  echo "Expected the second key customer problem image alt text to be removed." >&2
  exit 1
fi

if ! grep -q '<h4>3. Trust issues</h4>' "$post"; then
  echo "Expected the third key customer problem to have a numbered title." >&2
  exit 1
fi

if ! grep -q 'BDOs sometimes present a duplicate invoice and ask for payment' "$post"; then
  echo "Expected the trust issue from the removed image to be rendered as text." >&2
  exit 1
fi
