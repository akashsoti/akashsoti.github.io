#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/case-study-section-nav-scaffold-jekyll.log

post="_site/blog/feet-on-street-app/index.html"
home="_site/index.html"
css="assets/css/overrides/case-study-nav.css"
header_css="assets/css/overrides/header.css"

if ! grep -q 'class="container container--post"' "$post"; then
  echo "Expected post pages to use the post-specific container class." >&2
  exit 1
fi

if grep -q 'container--post' "$home"; then
  echo "Expected non-post pages to keep the normal container class." >&2
  exit 1
fi

if ! grep -q '/assets/css/overrides/case-study-nav.css' "$post"; then
  echo "Expected case-study nav stylesheet to be linked from post pages." >&2
  exit 1
fi

for expected in \
  'data-case-study-shell' \
  'class="case-study-sidebar' \
  'aria-label="Case study sections"' \
  'class="case-study-sidebar__back" href="/index.html"' \
  'class="ph ph-arrow-left"' \
  'data-case-study-nav-list' \
  'class="case-study-section-nav__dot"' \
  'class="case-study-main"' \
  'data-case-study-content'; do
  if ! grep -q "$expected" "$post"; then
    echo "Expected post page scaffold to include '$expected'." >&2
    exit 1
  fi
done

if grep -q 'case-study-shell' "$home"; then
  echo "Expected home page to avoid rendering the case-study shell." >&2
  exit 1
fi

if [[ ! -f "$css" ]]; then
  echo "Expected case-study nav stylesheet file to exist." >&2
  exit 1
fi

for expected in \
  'max-width: 960px' \
  'grid-template-columns: 200px minmax(0, 720px)' \
  'gap: 40px' \
  '.case-study-section-nav .case-study-section-nav__list' \
  'position: sticky' \
  'height: 100vh' \
  'top: 0' \
  'padding-top: 2rem' \
  'left: -14px' \
  'width: 6px' \
  'height: 6px' \
  'background: var(--fg-1)' \
  'html.theme-dark .case-study-section-nav__dot' \
  'background: var(--fg-1)' \
  '360ms cubic-bezier(0.22, 1, 0.36, 1)' \
  'prefers-reduced-motion: reduce'; do
  if ! grep -q "$expected" "$css"; then
    echo "Expected case-study nav CSS to include '$expected'." >&2
    exit 1
  fi
done

if ! grep -q 'max-width: 960px' "$header_css"; then
  echo "Expected header container to keep the original content area." >&2
  exit 1
fi
