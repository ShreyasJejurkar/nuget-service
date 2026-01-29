#!/usr/bin/env bash
set -e

ROOT_DIR="$(pwd)"
OUT_DIR="$ROOT_DIR/output/packages"
NUGET_PACKAGES_DIR="$ROOT_DIR/.nuget/packages"

mkdir -p "$OUT_DIR"
mkdir -p "$NUGET_PACKAGES_DIR"

echo "📦 NuGet offline restore starting"
echo "--------------------------------"

while IFS="|" read -r PACKAGE VERSION
do
  [[ -z "$PACKAGE" ]] && continue

  echo "➡️  Restoring $PACKAGE $VERSION"

  nuget install "$PACKAGE" \
    -Version "$VERSION" \
    -OutputDirectory "$OUT_DIR" \
    -PackagesDirectory "$NUGET_PACKAGES_DIR" \
    -DependencyVersion Highest \
    -DirectDownload \
    -NonInteractive \
    -ConfigFile nuget.config

done < packages.txt

echo "✅ Restore complete"
