#!/usr/bin/env bash
set -e

echo "🔍 Verifying packages"

COUNT=$(find output/packages -name "*.nupkg" | wc -l)

if [ "$COUNT" -eq 0 ]; then
  echo "❌ No packages found"
  exit 1
fi

echo "✅ Found $COUNT packages"
