#!/usr/bin/env bash
set -euo pipefail

tokens_css="assets/css/overrides/tokens.css"
typography_css="assets/css/overrides/typography.css"
theme_css="assets/css/overrides/theme.css"
case_study_css="assets/css/overrides/case-study-nav.css"
compiled_css="assets/css/style.css"

if git grep -n -E "postTitle|postTitle-subTitle|postTitle-subtitle" -- _layouts _includes assets test _posts ':!test/heading-spacing-card-theme.sh' >/tmp/post-title-class-grep.log 2>/dev/null; then
  cat /tmp/post-title-class-grep.log >&2
  echo "Expected old post title utility classes to be removed from markup, styles, and tests." >&2
  exit 1
fi

if grep -q -- '--type-heading-tracking' "$tokens_css"; then
  echo "Expected heading tracking token to be removed; Inter should use natural letter spacing." >&2
  exit 1
fi

if grep -q -- 'letter-spacing:' "$typography_css"; then
  echo "Expected typography.css not to apply extra letter spacing to h1-h6." >&2
  exit 1
fi

if grep -Eq -- 'color:[[:space:]]*(rgba\(0,[[:space:]]*0,[[:space:]]*0|#000)' "$typography_css"; then
  echo "Expected typography.css not to force black text colors that override dark mode." >&2
  exit 1
fi

if ! grep -q -- '.case-study-main > .post-header > \\*' "$case_study_css"; then
  echo "Expected case-study CSS to reset post header children structurally." >&2
  exit 1
fi

if ! grep -q -- 'width: auto;' "$case_study_css"; then
  echo "Expected case-study CSS to let post header children use normal block width." >&2
  exit 1
fi

if ! grep -q -- '.post .post-header h1{text-align:left;width:auto;margin:.5rem 0 1.5rem}' "$compiled_css"; then
  echo "Expected compiled CSS to remove auto side margins from the post header h1." >&2
  exit 1
fi

for expected in \
  ".posts .post-card-link," \
  ".posts .post-card-link:active," \
  ".posts .post-card-content," \
  "color: var(--fg-1);" \
  ".posts .post-card-content p" \
  "color: var(--fg-2);"; do
  if ! grep -q -- "$expected" "$theme_css"; then
    echo "Expected theme.css to own card text color with token '$expected'." >&2
    exit 1
  fi
done

if ! grep -q -- 'html.theme-dark .posts {' "$theme_css"; then
  echo "Expected theme.css to override the legacy dark-mode card rule." >&2
  exit 1
fi

if ! awk '/html\.theme-dark \.posts \{/ { in_rule = 1 } in_rule && /transform: none;/ { found = 1 } in_rule && /\}/ { in_rule = 0 } END { exit found ? 0 : 1 }' "$theme_css"; then
  echo "Expected dark-mode cards to keep transform: none at rest." >&2
  exit 1
fi

if ! awk '/html\.theme-dark \.posts \{/ { in_rule = 1 } in_rule && /transition: box-shadow 0\.2s cubic-bezier\(0\.25, 0\.8, 0\.25, 1\);/ { found = 1 } in_rule && /\}/ { in_rule = 0 } END { exit found ? 0 : 1 }' "$theme_css"; then
  echo "Expected dark-mode cards to transition only box-shadow." >&2
  exit 1
fi

if ! awk '/html\.theme-dark \.posts:hover \{/ { in_rule = 1 } in_rule && /transform: none;/ { found = 1 } in_rule && /\}/ { in_rule = 0 } END { exit found ? 0 : 1 }' "$theme_css"; then
  echo "Expected dark-mode card hover to avoid transform lift." >&2
  exit 1
fi
