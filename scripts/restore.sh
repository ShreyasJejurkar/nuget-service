#!/usr/bin/env bash
set -e

ROOT_DIR="$(pwd)"
OUT_DIR="$ROOT_DIR/output/packages"

mkdir -p "$OUT_DIR"

echo "📦 NuGet offline restore starting"
echo "--------------------------------"

while IFS="|" read -r PACKAGE VERSION
do
  [[ -z "$PACKAGE" ]] && continue

  echo "➡️  Restoring $PACKAGE $VERSION"

  nuget install "$PACKAGE" \
    -Version "$VERSION" \
    -OutputDirectory "$OUT_DIR" \
    -DependencyVersion Highest \
    -DirectDownload \
    -NoCache \
    -NonInteractive

done < packages.txt

echo "✅ Restore complete"
