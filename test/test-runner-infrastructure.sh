#!/usr/bin/env bash
set -euo pipefail

package_json="package.json"
run_all="test/run-all.sh"
run_static="test/run-static.sh"
run_browser="test/run-browser.sh"

for file in "$run_all" "$run_static" "$run_browser"; do
  if [[ ! -f "$file" ]]; then
    echo "Expected test runner to exist: $file" >&2
    exit 1
  fi

  if [[ ! -x "$file" ]]; then
    echo "Expected test runner to be executable: $file" >&2
    exit 1
  fi
done

for expected in \
  '"test": "bash test/run-static.sh"' \
  '"test:static": "bash test/run-static.sh"' \
  '"test:browser": "bash test/run-browser.sh"' \
  '"test:all": "bash test/run-all.sh"'; do
  if ! grep -q -- "$expected" "$package_json"; then
    echo "Expected package.json script missing: $expected" >&2
    exit 1
  fi
done

if ! grep -q -- 'run_suite "Static"' "$run_all"; then
  echo "Expected run-all.sh to run the static suite." >&2
  exit 1
fi

if ! grep -q -- 'run_suite "Browser"' "$run_all"; then
  echo "Expected run-all.sh to run the browser suite." >&2
  exit 1
fi

if ! grep -q -- 'find test -maxdepth 1' "$run_static" || ! grep -Fq -- "-name '*.sh'" "$run_static"; then
  echo "Expected run-static.sh to discover shell tests." >&2
  exit 1
fi

if ! grep -q -- 'browser_tests=(' "$run_browser"; then
  echo "Expected run-browser.sh to have an explicit browser test list." >&2
  exit 1
fi
