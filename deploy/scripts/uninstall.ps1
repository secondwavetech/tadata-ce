#!/usr/bin/env pwsh
# Uninstall Community Edition
# Removes containers and volumes; optionally remove installation directory

param(
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

# Docker Compose command detection (V2 preferred, V1 fallback)
function Get-DockerComposeCommand {
    # Try docker compose (V2) first
    $v2Result = & docker compose version 2>$null
    if ($LASTEXITCODE -eq 0) {
        return @("docker", "compose")
    }

    # Fall back to docker-compose (V1)
    if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
        return @("docker-compose")
    }

    return $null
}

# Helper to run docker-compose commands
function Invoke-DockerCompose {
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Arguments
    )

    $composeCmd = Get-DockerComposeCommand
    if (-not $composeCmd) {
        Write-Color "✗ Docker Compose is not available" "Red"
        exit 1
    }

    $prefix = if ($composeCmd.Length -gt 1) { $composeCmd[1..($composeCmd.Length-1)] } else { @() }
    & $composeCmd[0] @prefix @Arguments
}

# Determine installation directory
if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    $InstallDir = Get-Location
}

if (-not (Test-Path "$InstallDir\docker-compose.yml")) {
    Write-Color "✗ No tadata installation found in: $InstallDir" "Red"
    Write-Host "Usage: .\uninstall.ps1 [installation-directory]"
    exit 1
}

Push-Location $InstallDir

$composeFiles = @("-f", "docker-compose.yml")
if (Test-Path "docker-compose.local.yml") {
    $composeFiles += @("-f", "docker-compose.local.yml")
}

# Get data directory from .env if it exists
$dataDir = ""
if (Test-Path ".env") {
    $envContent = Get-Content ".env"
    $dataDirLine = $envContent | Where-Object { $_ -match "^DATA_DIR=" }
    if ($dataDirLine) {
        $dataDir = ($dataDirLine -split "=", 2)[1]
    }
}

Write-Color "⚠️  WARNING: This will permanently delete:" "Red"
Write-Host "  • All tadata containers"
if ($dataDir -and (Test-Path $dataDir)) {
    Write-Host "  • All data in: $dataDir"
} else {
    Write-Host "  • All database data"
    Write-Host "  • All function data"
}
Write-Host ""

Invoke-DockerCompose @composeFiles ps

Write-Host ""
$confirm = Read-Host "Type 'yes' to confirm uninstall"
if ($confirm -ne "yes") {
    Write-Color "Uninstall cancelled." "Blue"
    Pop-Location
    exit 0
}

Write-Color "Stopping and removing containers..." "Yellow"
Invoke-DockerCompose @composeFiles down

if ($dataDir -and (Test-Path $dataDir)) {
    Write-Color "Removing data directory..." "Yellow"
    Remove-Item -Recurse -Force $dataDir
    Write-Color "✓ Data directory removed" "Green"
} else {
    Write-Color "Removing volumes..." "Yellow"
    Invoke-DockerCompose @composeFiles down -v
    Write-Color "✓ Volumes removed" "Green"
}

Write-Color "✓ Containers removed" "Green"
Write-Host ""

$remove = Read-Host "Remove installation directory '$InstallDir'? (y/N)"
if ($remove -match '^[Yy]$') {
    Pop-Location
    Remove-Item -Recurse -Force $InstallDir
    Write-Color "✓ Installation directory removed" "Green"
} else {
    Pop-Location
    Write-Color "Installation directory preserved" "Blue"
}
