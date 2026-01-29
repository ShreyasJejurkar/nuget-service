$ErrorActionPreference = "Stop"

$Root = Get-Location
$OutputDir   = Join-Path $Root "output"
$PackagesDir = Join-Path $OutputDir "packages"
$NupkgDir    = Join-Path $OutputDir "nupkgs"
$ConfigFile  = Join-Path $Root "packages.config"
$JsonFile    = Join-Path $Root "packages.json"

Write-Host "NuGet offline restore starting"
Write-Host "--------------------------------"

# Clean output
Remove-Item $OutputDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $PackagesDir | Out-Null
New-Item -ItemType Directory -Force -Path $NupkgDir | Out-Null

# Load packages.json
if (!(Test-Path $JsonFile)) {
    Write-Error "packages.json not found"
}

$Packages = Get-Content $JsonFile -Raw | ConvertFrom-Json

# Generate packages.config
$xml = New-Object System.Xml.XmlDocument
$decl = $xml.CreateXmlDeclaration("1.0", "utf-8", $null)
$xml.AppendChild($decl) | Out-Null

$packagesNode = $xml.CreateElement("packages")
$xml.AppendChild($packagesNode) | Out-Null

foreach ($pkg in $Packages) {
    Write-Host "Adding package $($pkg.id) $($pkg.version)"

    $pkgNode = $xml.CreateElement("package")
    $pkgNode.SetAttribute("id", $pkg.id)
    $pkgNode.SetAttribute("version", $pkg.version)
    $pkgNode.SetAttribute("targetFramework", "net8.0")

    $packagesNode.AppendChild($pkgNode) | Out-Null
}

$xml.Save($ConfigFile)

# Restore packages (downloads .nupkg files)
nuget restore $ConfigFile `
    -PackagesDirectory $PackagesDir `
    -NoCache `
    -NonInteractive

# Collect .nupkg files into flat folder
Get-ChildItem $PackagesDir -Recurse -Filter "*.nupkg" | ForEach-Object {
    Copy-Item $_.FullName $NupkgDir -Force
}

# Verify
$Count = (Get-ChildItem $NupkgDir -Filter "*.nupkg").Count

if ($Count -eq 0) {
    Write-Error "No NuGet packages were downloaded"
}

Write-Host "Verified $Count NuGet packages"
Write-Host "Output location: $NupkgDir"
