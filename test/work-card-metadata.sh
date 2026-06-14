#!/usr/bin/env bash
set -euo pipefail

bundle exec jekyll build >/tmp/work-card-metadata-jekyll.log

home="_site/index.html"
index="index.html"
css="assets/css/overrides/work-cards.css"

for expected in \
  'class="post-card-meta"' \
  'class="post-card-company"' \
  "post.company | default: post.subtitle" \
  "post.date | date: '%Y'"; do
  if ! grep -Fq -- "$expected" "$index"; then
    echo "Expected home card markup to include '$expected'." >&2
    exit 1
  fi
done

for expected in \
  '#home .posts .post-card-meta' \
  'justify-content: space-between' \
  '#home .posts .post-card-company' \
  'text-overflow: ellipsis' \
  '#home .posts .date' \
  'text-align: right'; do
  if ! grep -Fq -- "$expected" "$css"; then
    echo "Expected work card metadata CSS to include '$expected'." >&2
    exit 1
  fi
done

assert_card_meta() {
  local title="$1"
  local company="$2"
  local year="$3"

  if ! perl -0ne "exit(/<article class=\"posts\">(?:(?!<\\/article>).)*<span class=\"post-card-company\">\\Q$company\\E<\\/span>\\s*<span class=\"date\">\\Q$year\\E<\\/span>(?:(?!<\\/article>).)*<h3>\\Q$title\\E<\\/h3>/s ? 0 : 1)" "$home"; then
    echo "Expected '$title' card to show company '$company' and year '$year'." >&2
    exit 1
  fi
}

assert_card_meta "Feet on Street app" "Amazon Distribution" "2019"
assert_card_meta "Ola Outstation" "Ola" "2017"
assert_card_meta "Ola Shuttle" "Ola" "2016"
assert_card_meta "Punchh website redesign" "Punchh" "2013"
assert_card_meta "Farmerboys restaurant app" "Punchh" "2013"
