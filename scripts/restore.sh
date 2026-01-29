#!/usr/bin/env bash
set -e

# Convert repo root to Windows path
WIN_ROOT=$(cd . && pwd -W)

OUT_DIR="$WIN_ROOT\\output\\packages"
LOCAL_NUGET_PACKAGES="$WIN_ROOT\\.nuget\\packages"

mkdir -p output/packages
mkdir -p .nuget/packages

echo "📦 NuGet offline restore starting"
echo "--------------------------------"
echo "WIN_ROOT=$WIN_ROOT"

while IFS="|" read -r PACKAGE VERSION
do
  [[ -z "$PACKAGE" ]] && continue

  echo "➡️  Restoring $PACKAGE $VERSION"

  cmd.exe /c ^
    "set NUGET_PACKAGES=$LOCAL_NUGET_PACKAGES && ^
     nuget install $PACKAGE ^
       -Version $VERSION ^
       -OutputDirectory $OUT_DIR ^
       -DependencyVersion Highest ^
       -DirectDownload ^
       -NonInteractive ^
       -ConfigFile nuget.config"

done < packages.txt

echo "✅ Restore complete"
