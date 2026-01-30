# Stop on any error
$ErrorActionPreference = "Stop"

Write-Host "Starting NuGet offline mirror"

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

# Load package list (format: { "PackageId": "1.2.3", ... })
$Json = Get-Content $PackagesFile -Raw | ConvertFrom-Json

if ($null -eq $Json -or $Json.psobject.Properties.Count -eq 0) {
    throw "No packages defined in packages.json"
} 

# Download packages and dependencies
foreach ($Pair in $Json.psobject.Properties) {
    $Id = $Pair.Name
    $Version = $Pair.Value

    Write-Host "Restoring $Id $Version (including dependencies)"

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
    $dest = Join-Path $NupkgDir $_.Name
    if ($_.FullName -ne $dest) {
        Copy-Item $_.FullName -Destination $dest -Force
    }
}

# Optional: clean everything else to save space
Get-ChildItem $OutputDir | Where-Object { $_.FullName -ne $NupkgDir } | Remove-Item -Recurse -Force

# Verify
$Count = (Get-ChildItem $NupkgDir -Recurse -Filter "*.nupkg").Count
if ($Count -eq 0) {
    throw "No .nupkg files found after restore"
}

Write-Host "Offline NuGet mirror ready."
Write-Host "Total .nupkg files: $Count"
Write-Host "Packages available at: $NupkgDir"
