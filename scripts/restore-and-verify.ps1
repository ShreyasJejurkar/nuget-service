$ErrorActionPreference = "Stop"

Write-Host "Starting NuGet offline mirror"

# Paths
$Root = Resolve-Path "."
$PackagesFile = Join-Path $Root "packages.json"
$OutputDir = Join-Path $Root "nupkgs"

if (!(Test-Path $PackagesFile)) {
    throw "packages.json not found"
}

# Prepare output directory
if (Test-Path $OutputDir) {
    Remove-Item $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputDir | Out-Null

# Load package list
$Json = Get-Content $PackagesFile -Raw | ConvertFrom-Json
$Packages = $Json.packages

if ($Packages.Count -eq 0) {
    throw "No packages defined"
}

foreach ($Pkg in $Packages) {
    $Id = $Pkg.id
    $Version = $Pkg.version

    Write-Host "Installing $Id $Version with dependencies"

    nuget install $Id `
        -Version $Version `
        -OutputDirectory $OutputDir `
        -DependencyVersion Highest `
        -DirectDownload `
        -NonInteractive `
        -Source https://api.nuget.org/v3/index.json
}

# Verify
$Nupkgs = Get-ChildItem $OutputDir -Recurse -Filter *.nupkg

if ($Nupkgs.Count -eq 0) {
    throw "No nupkg files downloaded"
}

Write-Host "Downloaded $($Nupkgs.Count) packages successfully"
Write-Host "Offline NuGet mirror ready"
