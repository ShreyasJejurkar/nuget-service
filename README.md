# NuGet Offline Mirror

A project for creating an offline NuGet package repository. This tool allows you to download NuGet packages and their dependencies for offline use in environments with restricted internet access.

## Project Structure

```
nuget-offline/
├── packages.json                    # Configuration file listing packages with versions
├── scripts/
│   ├── check-public-nuget.ps1       # Preview available updates from public NuGet (dry-run)
│   ├── sync-with-public-nuget.ps1   # Sync packages with public NuGet and download updates
│   ├── restore-and-verify.ps1       # Download packages specified in packages.json and verify
│   └── verify-offline.ps1           # Verify offline package integrity
└── output/                          # Generated output directory with downloaded packages
    └── nupkgs/                      # Directory containing downloaded .nupkg files
```

## Features

- **Offline Package Management**: Download NuGet packages for offline use
- **Dependency Resolution**: Automatically downloads package dependencies
- **Public NuGet Sync**: Check for updates on public NuGet and automatically download newer versions
- **Selective Updates**: Only downloads packages that have newer versions available
- **Verification**: Includes scripts to verify package integrity
- **PowerShell-based**: Simple and scriptable automation

## Getting Started

### Prerequisites

- PowerShell 5.0 or higher
- NuGet CLI (or dotnet CLI)
- Internet connectivity (for initial package download)

### Configuration

Edit `packages.json` to specify the packages you want to download (simple key/value object):

```json
{
  "PackageName": "1.0.0",
  "Another.Package": "2.3.4"
}
```

### Usage

#### Workflow 1: Check for Updates (Dry Run)

First, check what updates are available on public NuGet without downloading:

```powershell
.\scripts\check-public-nuget.ps1
```

This script will:

- Read packages from `packages.json`
- Query public NuGet for the latest version of each package
- Display which packages have updates available
- Show which packages are up-to-date
- Display any packages not found on public NuGet

#### Workflow 2: Sync with Public NuGet (Download Updates)

Automatically download any packages that have newer versions available:

```powershell
.\scripts\sync-with-public-nuget.ps1 -UpdatePackagesJson
```

**Parameters:**

- `-UpdatePackagesJson`: (Optional) Automatically update `packages.json` with newly downloaded versions. Without this flag, it only downloads but doesn't update the config file.

This script will:

- Compare your internal package versions against public NuGet
- Download any packages with newer versions available
- Download all dependencies automatically
- Store packages in `output/nupkgs/`
- Update `packages.json` with new package versions (if `-UpdatePackagesJson` is specified)

#### Workflow 3: Download Specific Packages

If you've manually edited `packages.json`, use this to download all specified packages:

```powershell
.\scripts\restore-and-verify.ps1
```

This script will:

- Read the package list from `packages.json`
- Download all specified packages and dependencies
- Store them in the `output/nupkgs/` directory

#### Workflow 4: Verify Packages

After downloading, verify that all packages are available offline:

```powershell
.\scripts\verify-offline.ps1
```

This script verifies the integrity of downloaded packages and ensures they can be restored offline.

## GitHub Actions

This project includes automated GitHub Actions workflows for continuous package mirroring:

- **Workflow File**: `.github/workflows/mirror.yml`
- **Trigger**: Manual workflow dispatch
- **Steps**:
  1. Checks out the repository
  2. Sets up NuGet
  3. Runs the restore and verify script
  4. Runs the offline verification script
  5. Uploads the downloaded packages as artifacts

You can manually trigger the workflow from the GitHub Actions tab to automatically download and verify packages on a schedule or on-demand.

## Output

Downloaded packages are stored in `output/nupkgs/` with the following structure:

- `PackageName.version.nupkg` - Individual package files ready for offline use

## Example Workflow

### Initial Setup

1. Edit `packages.json` with your required packages:

```json
{
  "Microsoft.OpenApi": "2.6.1",
  "Serilog": "3.1.1",
  "MSTest.TestAdapter": "4.0.2"
}
```

### Keep Packages Updated

1. **Check for updates** (preview what would be downloaded):

```powershell
.\scripts\check-public-nuget.ps1
```

Output example:

```
• Microsoft.OpenApi (2.6.1) ... Up to date
• Serilog (3.1.1) ... Update available → 4.0.0
• MSTest.TestAdapter (4.0.2) ... Up to date
```

2. **Sync with public NuGet** (download new versions):

```powershell
.\scripts\sync-with-public-nuget.ps1 -UpdatePackagesJson
```

This automatically updates `packages.json` to:

```json
{
  "Microsoft.OpenApi": "2.6.1",
  "MSTest.TestAdapter": "4.0.2",
  "Serilog": "4.0.0"
}
```

3. **Verify everything works offline**:

```powershell
.\scripts\verify-offline.ps1
```

## Decision Logic

The sync script uses the following decision logic:

1. **Read `packages.json`** - These are your current internal package versions
2. **Query public NuGet API** - Get the latest version for each package
3. **Compare versions**:
   - ✓ If latest version **already exists** in `packages.json` → Skip download
   - ⚠ If **newer version** exists on public NuGet → Download it and its dependencies
4. **Update `packages.json`** (with `-UpdatePackagesJson` flag) with new versions

## License

See LICENSE file for details.
