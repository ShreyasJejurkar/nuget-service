# Stop on any error
$ErrorActionPreference = "Stop"

Write-Host "Checking for updated NuGet packages"

# Paths
$Root          = Resolve-Path "."
$VersionFile   = Join-Path $Root "version.json"
$OutputDir     = Join-Path $Root "output"
$NupkgDir      = Join-Path $OutputDir "nupkgs"
$UpdatesLogFile = Join-Path $OutputDir "updates-found.txt"

# NuGet API endpoint
$NuGetApiUrl = "https://api.nuget.org/v3-flatcontainer"

# Check version.json exists
if (!(Test-Path $VersionFile)) {
    throw "version.json not found in $Root"
}

# Load version data (format: { "PackageId": ["1.0.0", "2.0.0"], ... })
$VersionData = Get-Content $VersionFile -Raw | ConvertFrom-Json

if ($null -eq $VersionData -or $VersionData.psobject.Properties.Count -eq 0) {
    throw "No packages defined in version.json"
}

# Prepare output folder
if (Test-Path $OutputDir) { Remove-Item $OutputDir -Recurse -Force }
New-Item -ItemType Directory -Path $NupkgDir | Out-Null

$UpdatesFound = @()
$PackagesToDownload = @{}

# Check each package for newer versions
Write-Host "`nQuerying NuGet.org for latest versions..."
foreach ($Pair in $VersionData.psobject.Properties) {
    $PackageId = $Pair.Name
    $StoredVersions = $Pair.Value
    
    # Get the latest version from the array
    $LatestStoredVersion = $StoredVersions[0]
    
    try {
        # Query NuGet API for available versions
        $VersionsUrl = "$NuGetApiUrl/$([System.Uri]::EscapeUriString($PackageId.ToLower()))/index.json"
        $Response = Invoke-RestMethod -Uri $VersionsUrl -Method Get -TimeoutSec 10 -ErrorAction Stop
        
        if ($Response.versions) {
            # Filter for stable versions only (exclude those with hyphens like -preview, -beta)
            $StableVersions = $Response.versions | Where-Object { $_ -notmatch '-' }
            
            if ($StableVersions) {
                # Get the latest stable version (versions are sorted)
                $LatestPublicVersion = $StableVersions[-1]
                
                # Compare versions
                # Note: NuGet API returns versions pre-sorted. 
                # If the latest public version is different from our latest stored, we treat it as an update.
                if ($LatestPublicVersion -ne $LatestStoredVersion) {
                    Write-Host "[UPDATE] Available: $PackageId ($LatestStoredVersion -> $LatestPublicVersion)"
                    $UpdatesFound += @{
                        Package = $PackageId
                        StoredVersion = $LatestStoredVersion
                        LatestVersion = $LatestPublicVersion
                    }
                    $PackagesToDownload[$PackageId] = $LatestPublicVersion
                } else {
                    Write-Host "  No update: $PackageId (latest stable: $LatestPublicVersion)"
                }
            } else {
                Write-Host "  No stable versions found for $PackageId"
            }
        }
    }
    catch {
        Write-Host "[WARN] Warning: Could not query package $PackageId : $_"
    }
}

# If no updates found, exit gracefully
if ($UpdatesFound.Count -eq 0) {
    Write-Host "`n[OK] No package updates available"
    Write-Host "All packages are up to date with their stored versions"
    exit 0
}

# Download updated packages and dependencies
Write-Host "`nDownloading $($PackagesToDownload.Count) updated package(s)..."

# Create a temporary directory for downloading
$TempDownloadDir = Join-Path $OutputDir "downloads"
New-Item -ItemType Directory -Path $TempDownloadDir | Out-Null

foreach ($PackageId in $PackagesToDownload.Keys) {
    $Version = $PackagesToDownload[$PackageId]
    
    Write-Host "Installing $PackageId $Version (including dependencies)"
    
    # Create a temporary project to download the package
    $TempProjectDir = Join-Path $TempDownloadDir $PackageId
    New-Item -ItemType Directory -Path $TempProjectDir -Force | Out-Null
    Set-Location $TempProjectDir
    
    # Create a minimal project file
    $ProjectContent = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="$PackageId" Version="$Version" />
  </ItemGroup>
</Project>
"@
    
    Set-Content -Path (Join-Path $TempProjectDir "Temp.csproj") -Value $ProjectContent
    
    try {
        # Restore packages to the root output directory
        dotnet restore --packages $OutputDir -v minimal 2>&1 | Where-Object { $_ -match "error" } | ForEach-Object { Write-Host "[ERROR] $_" }
    }
    catch {
        Write-Host "[WARN] Failed to download $PackageId : $_"
    }
    
    Set-Location $Root
}

# Collect only .nupkg files
Get-ChildItem -Path $OutputDir -Recurse -Filter "*.nupkg" | ForEach-Object {
    $dest = Join-Path $NupkgDir $_.Name
    if ($_.FullName -ne $dest) {
        Copy-Item $_.FullName -Destination $dest -Force
    }
}

# Clean everything else to save space
Get-ChildItem $OutputDir | Where-Object { $_.FullName -ne $NupkgDir } | Remove-Item -Recurse -Force

# Create a summary of updates
Write-Host "`nGenerating update summary..."
$summary = "# Updated Packages`n`n"
$summary += "The following packages have newer versions available:`n`n"
$summary += "| Package | Stored Version | Latest Version |`n"
$summary += "|---------|----------------|----------------|`n"

foreach ($update in $UpdatesFound) {
    $summary += "| $($update.Package) | $($update.StoredVersion) | $($update.LatestVersion) |`n"
}

Add-Content -Path $UpdatesLogFile -Value $summary

# Verify
$Count = (Get-ChildItem $NupkgDir -Recurse -Filter "*.nupkg").Count
if ($Count -eq 0) {
    throw "No .nupkg files found after download"
}

Write-Host "`nDownload complete!"
Write-Host "Total .nupkg files: $Count"
Write-Host "Packages available at: $NupkgDir"
Write-Host "Update summary: $UpdatesLogFile"
