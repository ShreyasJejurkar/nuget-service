# Preview what packages would be updated without actually downloading them
# This script performs a dry-run check against public NuGet

param(
    [string]$PackagesFile = "../packages.json"
)

# Stop on any error
$ErrorActionPreference = "Stop"

# Resolve paths
$PackagesFile = Resolve-Path $PackagesFile

Write-Host "=================================================="
Write-Host "NuGet Packages - Dry Run Check"
Write-Host "=================================================="
Write-Host "Checking against public NuGet feed..."
Write-Host ""

# Check packages.json exists
if (!(Test-Path $PackagesFile)) {
    throw "packages.json not found at $PackagesFile"
}

# Load package list
$Json = Get-Content $PackagesFile -Raw | ConvertFrom-Json
if ($null -eq $Json -or $Json.psobject.Properties.Count -eq 0) {
    throw "No packages defined in packages.json"
}

$updatesAvailable = @()
$upToDate = @()
$notFound = @()
$errors = @()

Write-Host "Checking package versions..."
Write-Host ""

foreach ($Pair in $Json.psobject.Properties) {
    $PackageId = $Pair.Name
    $InternalVersion = $Pair.Value
    
    Write-Host -NoNewline "• $PackageId ($InternalVersion) ... "
    
    try {
        # Query public NuGet API
        $nugetApiUrl = "https://api.nuget.org/v3-flatcontainer/$($PackageId.ToLower())/index.json"
        $response = Invoke-WebRequest -Uri $nugetApiUrl -UseBasicParsing -ErrorAction SilentlyContinue
        
        if ($response.StatusCode -eq 200) {
            $versions = $response.Content | ConvertFrom-Json
            $stableVersions = $versions.versions | Where-Object { $_ -notmatch '-' }
            
            if ($stableVersions) {
                $latestVersion = $stableVersions[-1]
                
                if ($latestVersion -ne $InternalVersion) {
                    Write-Host "Update available → $latestVersion" -ForegroundColor Yellow
                    $updatesAvailable += @{
                        Package = $PackageId
                        Current = $InternalVersion
                        Latest = $latestVersion
                    }
                } else {
                    Write-Host "Up to date (latest stable: $latestVersion)" -ForegroundColor Green
                    $upToDate += $PackageId
                }
            } else {
                Write-Host "No stable versions found" -ForegroundColor Red
                $notFound += $PackageId
            }
        } else {
            Write-Host "Not found on public NuGet" -ForegroundColor Red
            $notFound += $PackageId
        }
    }
    catch {
        Write-Host "Error" -ForegroundColor Red
        $errors += @{
            Package = $PackageId
            Error = $_.Exception.Message
        }
    }
}

# Summary report
Write-Host ""
Write-Host "=================================================="
Write-Host "Summary"
Write-Host "=================================================="
Write-Host "Total packages: $($Json.psobject.Properties.Count)" -ForegroundColor Cyan
Write-Host "Up to date: $($upToDate.Count)" -ForegroundColor Green
Write-Host "Updates available: $($updatesAvailable.Count)" -ForegroundColor Yellow
Write-Host "Not found: $($notFound.Count)" -ForegroundColor Red
Write-Host "Errors: $($errors.Count)" -ForegroundColor Red

if ($updatesAvailable.Count -gt 0) {
    Write-Host ""
    Write-Host "Packages with updates available:" -ForegroundColor Yellow
    foreach ($item in $updatesAvailable) {
        Write-Host "  → $($item.Package): $($item.Current) → $($item.Latest)"
    }
    Write-Host ""
    Write-Host "Run the following command to download updates:"
    Write-Host "  .\sync-with-public-nuget.ps1 -UpdatePackagesJson" -ForegroundColor Cyan
}

if ($notFound.Count -gt 0) {
    Write-Host ""
    Write-Host "Packages not found on public NuGet:" -ForegroundColor Red
    foreach ($pkg in $notFound) {
        Write-Host "  ✗ $pkg"
    }
}

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Packages with errors:" -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host "  ✗ $($err.Package): $($err.Error)"
    }
}

Write-Host "=================================================="
