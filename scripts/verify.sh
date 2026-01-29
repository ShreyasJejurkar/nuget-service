#!/usr/bin/env bash
set -e

echo "🔍 Verifying packages"

if [ ! -d "output/nupkgs" ]; then
  echo "❌ output/nupkgs folder missing"
  exit 1
fi

COUNT=$(ls output/nupkgs/*.nupkg 2>/dev/null | wc -l)

if [ "$COUNT" -eq 0 ]; then
  echo "❌ No .nupkg files found"
  exit 1
fi

echo "✅ Found $COUNT .nupkg packages"
