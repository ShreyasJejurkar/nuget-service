$ErrorActionPreference = "Stop"

$Root       = Get-Location
$OutputDir  = Join-Path $Root "output"
$NupkgDir   = Join-Path $OutputDir "nupkgs"
$JsonFile   = Join-Path $Root "packages.json"
$DummyProj  = Join-Path $OutputDir "DummyRestore.csproj"

Write-Host "NuGet offline restore starting"
Write-Host "--------------------------------"

# Clean output
Remove-Item $OutputDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $NupkgDir | Out-Null

# Load packages.json
if (!(Test-Path $JsonFile)) { Write-Error "packages.json not found" }

$Packages = Get-Content $JsonFile -Raw | ConvertFrom-Json

# Generate dummy .csproj
$ProjectContent = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
"@

foreach ($pkg in $Packages) {
    $ProjectContent += "    <PackageReference Include=`"$($pkg.id)`" Version=`"$($pkg.version)`" />`r`n"
}

$ProjectContent += @"
  </ItemGroup>
</Project>
"@

# Write dummy project file
New-Item -ItemType File -Force -Path $DummyProj | Out-Null
Set-Content -Path $DummyProj -Value $ProjectContent

Write-Host "Generated dummy project for restore at $DummyProj"

# Restore all packages (downloads .nupkg files including dependencies)
dotnet restore $DummyProj --packages $NupkgDir --ignore-failed-sources --verbosity minimal

# Verify .nupkg files exist
$Count = (Get-ChildItem $NupkgDir -Recurse -Filter "*.nupkg").Count

if ($Count -eq 0) { Write-Error "❌ No .nupkg files found after restore" }

Write-Host "✅ Verified $Count NuGet packages and dependencies"
Write-Host "📦 Packages output: $NupkgDir"
