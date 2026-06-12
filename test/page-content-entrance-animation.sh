#!/usr/bin/env bash
set -euo pipefail

head_file="_includes/head.html"
scripts_file="assets/js/scripts.js"
css_file="assets/css/overrides/case-study-nav.css"

if ! grep -q 'document.documentElement.classList.add("js", "page-entering")' "$head_file"; then
  echo "Expected the head script to add js/page-entering before styles load." >&2
  exit 1
fi

if ! grep -q 'function initPageEntrance()' "$scripts_file"; then
  echo "Expected scripts.js to initialize the shared page entrance animation." >&2
  exit 1
fi

if ! grep -q 'document.documentElement.classList.add("page-ready")' "$scripts_file"; then
  echo "Expected scripts.js to release page-entering into page-ready." >&2
  exit 1
fi

if grep -q 'case-study-shell--entering' "$scripts_file"; then
  echo "Expected case-study nav not to own the page entrance animation." >&2
  exit 1
fi

if ! grep -q 'html.js.page-entering .content > .container:not(.container--post)' "$css_file"; then
  echo "Expected non-post page content to use the shared entrance animation." >&2
  exit 1
fi

if ! grep -q 'html.js.page-entering .case-study-main' "$css_file"; then
  echo "Expected case-study content to use the shared entrance animation." >&2
  exit 1
fi

if ! grep -q 'html.js.page-entering.page-ready .content > .container:not(.container--post)' "$css_file"; then
  echo "Expected page-ready content transition styles." >&2
  exit 1
fi

if ! grep -q '420ms cubic-bezier(0.22, 1, 0.36, 1)' "$css_file"; then
  echo "Expected the content entrance to match the side-nav motion curve." >&2
  exit 1
fi

if ! grep -q 'prefers-reduced-motion: reduce' "$css_file"; then
  echo "Expected reduced-motion users to be respected." >&2
  exit 1
fi
