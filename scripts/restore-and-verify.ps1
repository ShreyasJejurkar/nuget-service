$ErrorActionPreference = "Stop"

$Root = Get-Location
$OutputDir = Join-Path $Root "output"
$PackagesDir = Join-Path $OutputDir "packages"
$NupkgDir = Join-Path $OutputDir "nupkgs"
$ConfigFile = Join-Path $Root "packages.config"

Write-Host "📦 NuGet offline restore starting"
Write-Host "--------------------------------"

# Clean output
Remove-Item $OutputDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $PackagesDir | Out-Null
New-Item -ItemType Directory -Force -Path $NupkgDir | Out-Null

# Generate packages.config
$xml = New-Object System.Xml.XmlDocument
$decl = $xml.CreateXmlDeclaration("1.0","utf-8",$null)
$xml.AppendChild($decl) | Out-Null

$packagesNode = $xml.CreateElement("packages")
$xml.AppendChild($packagesNode) | Out-Null

Get-Content "packages.txt" | ForEach-Object {
    if ($_ -match "\|") {
        $parts = $_.Split("|")
        $pkg = $parts[0].Trim()
        $ver = $parts[1].Trim()

        Write-Host "➡️  Adding $pkg $ver"

        $pkgNode = $xml.CreateElement("package")
        $pkgNode.SetAttribute("id", $pkg)
        $pkgNode.SetAttribute("version", $ver)
        $pkgNode.SetAttribute("targetFramework", "net8.0")

        $packagesNode.AppendChild($pkgNode) | Out-Null
    }
}

$xml.Save($ConfigFile)

# Restore (this downloads .nupkg files)
nuget restore $ConfigFile `
    -PackagesDirectory $PackagesDir `
    -NoCache `
    -NonInteractive

# Collect .nupkg files
Get-ChildItem $PackagesDir -Recurse -Filter "*.nupkg" | ForEach-Object {
    Copy-Item $_.FullName $NupkgDir -Force
}

# Verify
$Count = (Get-ChildItem $NupkgDir -Filter "*.nupkg").Count

if ($Count -eq 0) {
    Write-Error "❌ No .nupkg files found"
}

Write-Host "✅ Verified $Count NuGet packages"
Write-Host "📦 Output folder: $NupkgDir"
