# Stop on any error
$ErrorActionPreference = "Stop"

Write-Host "📦 Starting NuGet offline mirror"

# Paths
$Root      = Resolve-Path "."
$PackagesFile = Join-Path $Root "packages.json"
$OutputDir = Join-Path $Root "output"
$NupkgDir  = Join-Path $OutputDir "nupkgs"

# Check packages.json exists
if (!(Test-Path $PackagesFile)) {
    throw "packages.json not found in $Root"
}

# Prepare output folder
if (Test-Path $OutputDir) { Remove-Item $OutputDir -Recurse -Force }
New-Item -ItemType Directory -Path $NupkgDir | Out-Null

# Load package list
$Json = Get-Content $PackagesFile -Raw | ConvertFrom-Json
$Packages = $Json.packages

if ($Packages.Count -eq 0) {
    throw "No packages defined in packages.json"
}

# Download packages and dependencies
foreach ($Pkg in $Packages) {
    $Id = $Pkg.id
    $Version = $Pkg.version

    Write-Host "➡ Restoring $Id $Version (with dependencies)"

    nuget install $Id `
        -Version $Version `
        -OutputDirectory $OutputDir `
        -DependencyVersion Highest `
        -Framework Any `
        -DirectDownload `
        -NonInteractive `
        -Verbosity quiet
}

# Collect only .nupkg files
Get-ChildItem -Path $OutputDir -Recurse -Filter "*.nupkg" | ForEach-Object {
    Copy-Item $_.FullName -Destination $NupkgDir -Force
}

# Optional: clean everything else to save space
Get-ChildItem $OutputDir | Where-Object { $_.FullName -ne $NupkgDir } | Remove-Item -Recurse -Force

# Verify
$Count = (Get-ChildItem $NupkgDir -Recurse -Filter "*.nupkg").Count
if ($Count -eq 0) {
    throw "❌ No .nupkg files found after restore"
}

Write-Host "✅ Offline NuGet mirror ready"
Write-Host "📦 Total .nupkg files: $Count"
Write-Host "📁 Packages available at: $NupkgDir"
