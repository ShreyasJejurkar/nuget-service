$ErrorActionPreference = "Stop"

$PackagesFile = "packages.txt"
$OutputDir = "$PSScriptRoot\..\nupkgs"

Write-Host "NuGet offline restore starting"
Write-Host "Packages file: $PackagesFile"
Write-Host "Output dir  : $OutputDir"
Write-Host "--------------------------------"

if (!(Test-Path $PackagesFile)) {
    Write-Error "packages.txt not found"
}

if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$Packages = Get-Content $PackagesFile | Where-Object { $_ -and -not $_.StartsWith("#") }

foreach ($Pkg in $Packages) {
    if ($Pkg -notmatch "@") {
        Write-Error "Invalid format: $Pkg (expected Package@Version)"
    }

    $Name, $Version = $Pkg.Split("@")

    Write-Host "Restoring $Name $Version"

    nuget install $Name `
        -Version $Version `
        -OutputDirectory $OutputDir `
        -DependencyVersion Highest `
        -Framework Any `
        -Source https://api.nuget.org/v3/index.json `
