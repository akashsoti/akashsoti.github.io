#!/usr/bin/env bash
set -euo pipefail

tokens_css="assets/css/overrides/tokens.css"
typography_css="assets/css/overrides/typography.css"

required_tokens=(
  "--font-family-base: Inter, sans-serif;"
  "--font-family-ui: var(--font-family-base);"
  "--font-family-sans: var(--font-family-ui);"
  "--font-family-heading: var(--font-family-base);"
  "--type-body-size: 16px;"
  "--type-body-line-height: 1.5;"
  "--type-body-weight: 400;"
  "--type-page-title-size: 2rem;"
  "--type-page-title-line-height: 1.2;"
  "--type-section-title-size: 1.375rem;"
  "--type-section-title-line-height: 1.5;"
  "--type-subsection-title-size: 1rem;"
  "--type-small-title-size: 0.8125rem;"
  "--type-heading-weight: 550;"
  "--type-subheading-weight: 450;"
  "--type-small-weight: 400;"
  "--type-meta-size: 0.875rem;"
  "--type-meta-line-height: 1.285714;"
)

for token in "${required_tokens[@]}"; do
  if ! grep -q -- "$token" "$tokens_css"; then
    echo "Expected typography token missing: $token" >&2
    exit 1
  fi
done

required_rules=(
  "body,"
  "font-size: var(--type-body-size);"
  "line-height: var(--type-body-line-height);"
  "font-weight: var(--type-body-weight);"
  "font-family: var(--font-family-heading);"
  "font-size: var(--type-page-title-size);"
  "font-size: var(--type-section-title-size);"
  "font-size: var(--type-subsection-title-size);"
  "font-size: var(--type-small-title-size);"
  ".post .meta,"
  "font-size: var(--type-meta-size);"
  ".case-study-content > section > h3,"
)

for rule in "${required_rules[@]}"; do
  if ! grep -q -- "$rule" "$typography_css"; then
    echo "Expected typography rule missing: $rule" >&2
    exit 1
  fi
done

if grep -q -- '--type-[a-z-]*:\\|--font-family-[a-z-]*:' "$typography_css"; then
  echo "Expected typography.css to consume tokens, not define them." >&2
  exit 1
fi

if grep -RIn -- '--type-[a-z-]*:' assets/css assets/scss \
  | grep -v '^assets/css/overrides/tokens.css:'; then
  echo "Expected typography tokens to be defined only in tokens.css." >&2
  exit 1
fi

if grep -RIn -- '--type-heading-tracking\\|letter-spacing:' "$tokens_css" "$typography_css"; then
  echo "Expected Inter headings to use natural letter spacing without tracking overrides." >&2
  exit 1
fi
