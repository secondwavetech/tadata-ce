#!/usr/bin/env pwsh
# tadata.ai Community Edition Installer for Windows
# Requires PowerShell 7.0 or later

param(
    [string]$Version = "latest",
    [string]$InstallDir = ""
)

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host ""
    Write-Host "ERROR: PowerShell 7.0 or later is required" -ForegroundColor Red
    Write-Host ""
    Write-Host "You are running PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please install PowerShell 7.x from:" -ForegroundColor Cyan
    Write-Host "  https://aka.ms/powershell-release?tag=stable" -ForegroundColor White
    Write-Host ""
    Write-Host "PowerShell 7 installs alongside Windows PowerShell 5.x (won't replace it)" -ForegroundColor Gray
    Write-Host "After installation, run this script again using 'pwsh' instead of 'powershell'" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# Set error handling - Stop on errors but allow specific operations to continue
$ErrorActionPreference = "Stop"

# Colors for output
function Write-Color {
    param(
        [string]$Text,
        [string]$Color = "White",
        [switch]$NoNewline
    )
    if ($NoNewline) {
        Write-Host $Text -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Text -ForegroundColor $Color
    }
}

$REPO_URL = "https://github.com/secondwavetech/tadata-ce.git"

# Get current directory safely
$currentDir = try { Get-Location | Select-Object -ExpandProperty Path } catch { $env:USERPROFILE }

# Default to ~/tadata-ce if no directory specified
if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    $InstallDir = Join-Path $env:USERPROFILE "tadata-ce"
}

# Convert to absolute path
try {
    if (-not [System.IO.Path]::IsPathRooted($InstallDir)) {
        $InstallDir = Join-Path $currentDir $InstallDir
    }
} catch {
    # If path operations fail, default to user profile
    $InstallDir = Join-Path $env:USERPROFILE "tadata-ce"
}

Write-Color "╔════════════════════════════════════════════╗" "Cyan"
Write-Color "║   tadata.ai Community Edition Installer   ║" "Cyan"
Write-Color "╚════════════════════════════════════════════╝" "Cyan"
Write-Host ""

# Confirm installation directory
$customDir = Read-Host "Installation directory [$InstallDir]"
if (-not [string]::IsNullOrWhiteSpace($customDir)) {
    $InstallDir = $customDir
    # Convert to absolute path
    try {
        if (-not [System.IO.Path]::IsPathRooted($InstallDir)) {
            $InstallDir = Join-Path $currentDir $InstallDir
        }
    } catch {
        # If path validation fails, use as-is
        Write-Host "Warning: Using path as-is" -ForegroundColor Yellow
    }
}

Write-Color "Installing to: " "Cyan" -NoNewline
Write-Host $InstallDir
Write-Host ""

# Check if git is installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Color "✗ git is not installed" "Red"
    Write-Host "Please install git from: https://git-scm.com/download/win"
    exit 1
}

# Check if Docker is installed
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Color "✗ Docker is not installed" "Red"
    Write-Host "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    exit 1
}

# Check if directory exists and is not empty
if ((Test-Path $InstallDir) -and ((Get-ChildItem $InstallDir -ErrorAction SilentlyContinue).Count -gt 0)) {
    Write-Color "✗ Installation directory is not empty: $InstallDir" "Red"
    Write-Host ""
    Write-Host "Please remove the directory manually or choose a different location."
    Write-Host ""
    exit 1
}

# Create installation directory if it doesn't exist
if (-not (Test-Path $InstallDir)) {
    Write-Color "Creating installation directory..." "Cyan"
    New-Item -ItemType Directory -Path $InstallDir | Out-Null
    Write-Color "✓ Directory created" "Green"
    Write-Host ""
}

# Clone to a temporary directory, then copy only the deploy assets
Write-Color "Downloading tadata.ai..." "Cyan"
$tempDir = Join-Path $env:TEMP ("tadata-temp-" + [System.Guid]::NewGuid().ToString())
try {
    git clone --quiet $REPO_URL $tempDir 2>&1 | Out-Null
    Copy-Item -Path (Join-Path $tempDir "deploy\*") -Destination $InstallDir -Recurse -Force
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    Write-Color "✓ Downloaded" "Green"
} catch {
    Write-Color "✗ Failed to download from repository" "Red"
    Write-Host $_.Exception.Message
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }
    exit 1
}
Write-Host ""

# Change to installation directory
Push-Location $InstallDir

# Run setup
Write-Color "Running setup..." "Cyan"
Write-Host ""
& "$InstallDir\setup.ps1" -Version $Version

Pop-Location

Write-Host ""
Write-Color "Installation directory: " "Green" -NoNewline
Write-Host $InstallDir
Write-Host ""
