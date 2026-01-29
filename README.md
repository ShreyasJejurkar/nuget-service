# NuGet Offline Mirror

A project for creating an offline NuGet package repository. This tool allows you to download NuGet packages and their dependencies for offline use in environments with restricted internet access.

## Project Structure

```
nuget-offline/
├── packages.json              # Configuration file listing packages to download
├── scripts/
│   ├── restore-and-verify.ps1 # Main script to download packages and verify
│   └── verify-offline.ps1      # Script to verify offline package integrity
└── output/                     # Generated output directory with downloaded packages
    └── nupkgs/                 # Directory containing downloaded .nupkg files
```

## Features

- **Offline Package Management**: Download NuGet packages for offline use
- **Dependency Resolution**: Automatically downloads package dependencies
- **Verification**: Includes scripts to verify package integrity
- **PowerShell-based**: Simple and scriptable automation

## Getting Started

### Prerequisites

- PowerShell 5.0 or higher
- NuGet CLI (or dotnet CLI)
- Internet connectivity (for initial package download)

### Configuration

Edit `packages.json` to specify the packages you want to download:

```json
{
  "packages": [
    {
      "id": "PackageName",
      "version": "1.0.0"
    }
  ]
}
```

### Usage

1. **Download Packages**

   ```powershell
   .\scripts\restore-and-verify.ps1
   ```

   This script will:
   - Read the package list from `packages.json`
   - Download all specified packages and dependencies
   - Store them in the `output/nupkgs/` directory

2. **Verify Packages**
   ```powershell
   .\scripts\verify-offline.ps1
   ```
   This script verifies the integrity of downloaded packages.

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

## Example

The included `packages.json` downloads:

- Serilog 3.1.1 (logging library)
- MSTest.TestAdapter 4.0.2 (testing framework)

## License

See LICENSE file for details.
