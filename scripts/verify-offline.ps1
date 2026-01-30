# Stop on any error
$ErrorActionPreference = "Stop"

Write-Host "Verifying offline NuGet packages"

$Root        = Resolve-Path "."
$PackagesFile = Join-Path $Root "packages.json"
$NupkgDir     = Join-Path $Root "output/nupkgs"
$VerifyDir    = Join-Path $Root "verify-project"

# Clean up previous verify project
if (Test-Path $VerifyDir) { Remove-Item $VerifyDir -Recurse -Force }
New-Item -ItemType Directory -Path $VerifyDir | Out-Null
Set-Location $VerifyDir

# Create dummy .NET project
dotnet new console -n DummyVerify -f net10.0 | Out-Null
Set-Location "DummyVerify"

# Add offline NuGet source
dotnet nuget add source $NupkgDir -n OfflineTestSource | Out-Null

# Load package list (format: { "PackageId": "1.2.3", ... })
$Json = Get-Content $PackagesFile -Raw | ConvertFrom-Json

if ($null -eq $Json -or $Json.psobject.Properties.Count -eq 0) {
    throw "No packages defined in packages.json"
}

# Install each package offline
foreach ($Pair in $Json.psobject.Properties) {
    $Id = $Pair.Name
    $Version = $Pair.Value

    Write-Host "Installing $Id $Version from offline source"

    dotnet add package $Id `
        --version $Version `
        --source $NupkgDir `
        --no-restore
}

# Restore project using only offline source
Write-Host "Restoring dummy project offline..."
dotnet restore --source $NupkgDir --no-cache

Write-Host "Offline restore verification SUCCESS"
Write-Host "All packages and dependencies are available in $NupkgDir"
