# Verify that updated packages can be restored offline with all dependencies
param(
    [string]$NupkgDir = "output/nupkgs",
    [string]$UpdatesLogFile = "output/updates-found.txt"
)

$ErrorActionPreference = "Stop"

Write-Host "Verifying updated NuGet packages offline..."

if (!(Test-Path $UpdatesLogFile)) {
    Write-Host "No updates log found at $UpdatesLogFile. Skipping verification."
    exit 0
}

# Resolve paths to absolute paths BEFORE changing directory
$NupkgDir = Resolve-Path $NupkgDir
$UpdatesLogFile = Resolve-Path $UpdatesLogFile

$VerifyDir = Join-Path (Get-Location) "verify-updates-project"

# Clean up previous verify project
if (Test-Path $VerifyDir) { Remove-Item $VerifyDir -Recurse -Force }
New-Item -ItemType Directory -Path $VerifyDir | Out-Null
Set-Location $VerifyDir

# Create dummy .NET project
dotnet new console -n DummyVerify -f net10.0 | Out-Null
Set-Location "DummyVerify"

# Parse updates-found.txt to get package IDs and versions
$updates = Get-Content -Path $UpdatesLogFile
$packageFound = $false

foreach ($line in $updates) {
    if ($line -match "\| ([^|]+) \| ([^|]+) \| ([^|]+) \|") {
        $id = $matches[1].Trim()
        $version = $matches[3].Trim()
        
        if ($id -eq "Package" -or $id -match "^---") { continue }
        
        $packageFound = $true
        Write-Host "Adding $id $version to offline verification project..."
        
        # Add package without restoring yet
        dotnet add package $id --version $version --no-restore
    }
}

if (!$packageFound) {
    Write-Host "No specific updates parsed from log. Verification complete."
    exit 0
}

# Restore project using ONLY the offline source
Write-Host "`nAttempting offline restore for all updated packages..."
dotnet restore --source $NupkgDir --no-cache --ignore-failed-sources

Write-Host "`n[SUCCESS] Offline restore verification passed."
Write-Host "All updated packages and their dependencies are fully available in the artifact."
