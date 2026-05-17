#!/usr/bin/env bash
set -euo pipefail

THRESHOLD=${COVERAGE_THRESHOLD:-60}
BUILD_DIR=${1:-build}

if [ ! -d "$BUILD_DIR" ]; then
  echo "Build directory '$BUILD_DIR' not found"
  exit 1
fi

cd "$BUILD_DIR"

# Capture coverage data
genhtml filtered.info --output-directory coverage_html >/dev/null
lcov --capture --directory . --output-file coverage.info --ignore-errors mismatch

# Extract only project sources under src/
lcov --extract coverage.info '*/src/*' --output-file extracted.info

# Remove system and test files just in case
lcov --remove extracted.info '/usr/*' '*/external/*' '*/tests/*' --output-file filtered.info

# Generate HTML report
genhtml filtered.info --output-directory coverage_html >/dev/null

# Extract total line coverage percentage
PCT=$(lcov --summary filtered.info | awk '/lines/{print $2}' | tr -d '%')
if [ -z "$PCT" ]; then
  echo "Failed to parse coverage percentage"
  exit 1
fi

printf "TOTAL_COVERAGE=%s\n" "$PCT" > coverage_summary.txt

echo "Coverage: $PCT%"

# Compare against threshold (allow decimal comparison)
awk -v p="$PCT" -v t="$THRESHOLD" 'BEGIN{ if (p+0 < t+0) exit 2; else exit 0 }'

echo "Coverage meets threshold $THRESHOLD%"
