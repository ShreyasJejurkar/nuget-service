#!/usr/bin/env bash
set -e

WIN_ROOT=$(pwd -W)

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

  CMD="set NUGET_PACKAGES=$LOCAL_NUGET_PACKAGES && nuget install $PACKAGE -Version $VERSION -OutputDirectory $OUT_DIR -DependencyVersion Highest -DirectDownload -NonInteractive -ConfigFile nuget.config"

  cmd.exe /c "$CMD"

done < packages.txt

echo "✅ Restore complete"

echo "✅ Restore complete"
