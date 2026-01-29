#!/usr/bin/env bash
set -e

ROOT_DIR="$(pwd)"
OUT_DIR="$ROOT_DIR/output/packages"
LOCAL_NUGET_PACKAGES="$ROOT_DIR/.nuget/packages"

mkdir -p "$OUT_DIR"
mkdir -p "$LOCAL_NUGET_PACKAGES"

# 🔥 Force NuGet to NEVER touch Program Files paths
export NUGET_PACKAGES="$LOCAL_NUGET_PACKAGES"

echo "📦 NuGet offline restore starting"
echo "--------------------------------"
echo "Using NUGET_PACKAGES=$NUGET_PACKAGES"

while IFS="|" read -r PACKAGE VERSION
do
  [[ -z "$PACKAGE" ]] && continue

  echo "➡️  Restoring $PACKAGE $VERSION"

  nuget install "$PACKAGE" \
    -Version "$VERSION" \
    -OutputDirectory "$OUT_DIR" \
    -DependencyVersion Highest \
    -DirectDownload \
    -NonInteractive \
    -ConfigFile nuget.config

done < packages.txt

echo "✅ Restore complete"
