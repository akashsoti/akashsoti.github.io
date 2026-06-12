#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/post-current-work-nav-jekyll.log

post="_site/blog/feet-on-street-app/index.html"

if ! grep -q '<a class="top-nav__link is-current" href="/index.html">Work</a>' "$post"; then
  echo "Expected case-study posts to mark the Work nav item as current." >&2
  exit 1
fi

if grep -q '<a class="top-nav__link is-current" href="/prototypes">Prototypes</a>' "$post"; then
  echo "Expected case-study posts not to mark Prototypes as current." >&2
  exit 1
fi

if grep -q '<a class="top-nav__link is-current" href="/about">About</a>' "$post"; then
  echo "Expected case-study posts not to mark About as current." >&2
  exit 1
fi
