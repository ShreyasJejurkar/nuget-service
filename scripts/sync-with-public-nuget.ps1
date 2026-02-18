# Sync internal NuGet packages with public NuGet repository
# This script checks for updates on public NuGet and downloads packages that are missing from the internal feed

param(
    [string]$PackagesFile = "../packages.json",
    [string]$OutputDir = "../output",
    [switch]$UpdatePackagesJson
)

# Stop on any error
$ErrorActionPreference = "Stop"

# Resolve paths
$PackagesFile = Resolve-Path $PackagesFile
$OutputDir = Resolve-Path $OutputDir
$NupkgDir = Join-Path $OutputDir "nupkgs"

Write-Host "=================================================="
Write-Host "NuGet Public Feed Sync Script"
Write-Host "=================================================="
Write-Host "Packages file: $PackagesFile"
Write-Host "Output directory: $OutputDir"
Write-Host ""

# Check packages.json exists
if (!(Test-Path $PackagesFile)) {
    throw "packages.json not found at $PackagesFile"
}

# Create nupkgs directory if it doesn't exist
if (!(Test-Path $NupkgDir)) {
    New-Item -ItemType Directory -Path $NupkgDir -Force | Out-Null
}

# Load package list
$Json = Get-Content $PackagesFile -Raw | ConvertFrom-Json
if ($null -eq $Json -or $Json.psobject.Properties.Count -eq 0) {
    throw "No packages defined in packages.json"
}

# Track packages that need to be downloaded
$PackagesToDownload = @{}
$InternalPackages = @{}

# First pass: Load internal packages and check for updates
Write-Host "Step 1: Checking for available updates on public NuGet..."
Write-Host ""

foreach ($Pair in $Json.psobject.Properties) {
    $PackageId = $Pair.Name
    $InternalVersion = $Pair.Value
    $InternalPackages[$PackageId] = $InternalVersion
    
    Write-Host "Checking $PackageId (internal: $InternalVersion)"
    
    try {
        # Query public NuGet API for latest version
        $nugetApiUrl = "https://api.nuget.org/v3-flatcontainer/$($PackageId.ToLower())/index.json"
        $response = Invoke-WebRequest -Uri $nugetApiUrl -UseBasicParsing -ErrorAction SilentlyContinue
        
        if ($response.StatusCode -eq 200) {
            $versions = $response.Content | ConvertFrom-Json
            $stableVersions = $versions.versions | Where-Object { $_ -notmatch '-' }
            
            if ($stableVersions) {
                $latestVersion = $stableVersions[-1]
                
                Write-Host "  → Latest stable on public NuGet: $latestVersion"
                
                # Compare versions
                if ($latestVersion -ne $InternalVersion) {
                    Write-Host "  ⚠ Update available: $InternalVersion → $latestVersion"
                    $PackagesToDownload[$PackageId] = $latestVersion
                } else {
                    Write-Host "  ✓ Already up to date"
                }
            } else {
                Write-Host "  ⚠ No stable versions found on public NuGet"
            }
        } else {
            Write-Host "  ⚠ Package not found on public NuGet"
        }
    }
    catch {
        Write-Host "  ✗ Error checking updates: $_"
    }
    
    Write-Host ""
}

# Check if there are any packages to download
if ($PackagesToDownload.Count -eq 0) {
    Write-Host "=================================================="
    Write-Host "✓ All packages are up to date!"
    Write-Host "=================================================="
    exit 0
}

# Second pass: Download packages that need updating
Write-Host "Step 2: Downloading $($PackagesToDownload.Count) updated package(s)..."
Write-Host ""

$downloadCount = 0
$failedDownloads = @{}

foreach ($Package in $PackagesToDownload.GetEnumerator()) {
    $PackageId = $Package.Key
    $Version = $Package.Value
    
    Write-Host "Downloading $PackageId@$Version (with dependencies)"
    
    try {
        # Download using nuget install
        nuget install $PackageId `
            -Version $Version `
            -OutputDirectory $OutputDir `
            -DependencyVersion Highest `
            -Framework Any `
            -DirectDownload `
            -NonInteractive `
            -Verbosity quiet
        
        $downloadCount++
        Write-Host "  ✓ Downloaded successfully"
        
        # Update internal packages list
        $InternalPackages[$PackageId] = $Version
    }
    catch {
        Write-Host "  ✗ Failed: $_"
        $failedDownloads[$PackageId] = $Version
    }
    
    Write-Host ""
}

# Third pass: Copy all .nupkg files to nupkgs directory
Write-Host "Step 3: Organizing downloaded packages..."
$nupkgFiles = Get-ChildItem -Path $OutputDir -Recurse -Filter "*.nupkg"
$copiedCount = 0

foreach ($file in $nupkgFiles) {
    $dest = Join-Path $NupkgDir $file.Name
    if ($file.FullName -ne $dest) {
        Copy-Item $file.FullName -Destination $dest -Force
        $copiedCount++
    }
}

Write-Host "  ✓ Copied $copiedCount .nupkg file(s) to nupkgs directory"

# Clean up temp folders (keep only nupkgs directory)
Write-Host "  Cleaning up temporary files..."
Get-ChildItem $OutputDir | Where-Object { $_.FullName -ne $NupkgDir } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# Fourth pass: Update packages.json if requested
if ($UpdatePackagesJson -and $downloadCount -gt 0) {
    Write-Host ""
    Write-Host "Step 4: Updating packages.json..."
    
    # Sort packages alphabetically
    $sortedPackages = $InternalPackages.GetEnumerator() | Sort-Object Name
    $updatedJson = @{}
    
    foreach ($item in $sortedPackages) {
        $updatedJson[$item.Key] = $item.Value
    }
    
    # Write back to packages.json with pretty formatting
    $jsonContent = $updatedJson | ConvertTo-Json -Depth 10
    Set-Content -Path $PackagesFile -Value $jsonContent -Encoding UTF8
    
    Write-Host "  ✓ packages.json updated with $downloadCount new package(s)"
}

# Summary report
Write-Host ""
Write-Host "=================================================="
Write-Host "Sync Summary"
Write-Host "=================================================="
Write-Host "Total packages processed: $($InternalPackages.Count)"
Write-Host "Updates found: $($PackagesToDownload.Count)"
Write-Host "Successfully downloaded: $downloadCount"
Write-Host "Failed downloads: $($failedDownloads.Count)"

if ($failedDownloads.Count -gt 0) {
    Write-Host ""
    Write-Host "Failed packages:"
    foreach ($pkg in $failedDownloads.GetEnumerator()) {
        Write-Host "  - $($pkg.Key)@$($pkg.Value)"
    }
}

# Final verification
$totalNupkgs = (Get-ChildItem $NupkgDir -Recurse -Filter "*.nupkg" | Measure-Object).Count
Write-Host ""
Write-Host "Total .nupkg files in offline repository: $totalNupkgs"
Write-Host "Location: $NupkgDir"
Write-Host "=================================================="

if ($failedDownloads.Count -gt 0) {
    Write-Host "⚠ Sync completed with errors. Please review failed packages."
    exit 1
} else {
    Write-Host "✓ Sync completed successfully!"
    exit 0
}
