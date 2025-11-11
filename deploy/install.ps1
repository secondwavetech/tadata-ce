#!/usr/bin/env pwsh
# tadata.ai Community Edition Installer for Windows
# Requires PowerShell 5.1 or later

param(
    [string]$Version = "latest",
    [string]$InstallDir = ""
)

$ErrorActionPreference = "Continue"

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

# Default to ~/tadata-ce if no directory specified
if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    $InstallDir = Join-Path $env:USERPROFILE "tadata-ce"
}

# Convert to absolute path
if (-not [System.IO.Path]::IsPathRooted($InstallDir)) {
    $InstallDir = Join-Path $PWD $InstallDir
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
    if (-not [System.IO.Path]::IsPathRooted($InstallDir)) {
        $InstallDir = Join-Path $PWD $InstallDir
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
