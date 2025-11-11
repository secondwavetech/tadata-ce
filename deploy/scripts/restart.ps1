#!/usr/bin/env pwsh
# Restart Community Edition installation
# Requires PowerShell 7.0 or later

param(
    [string]$InstallDir = ""
)

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "ERROR: PowerShell 7.0 or later is required" -ForegroundColor Red
    Write-Host "Download from: https://aka.ms/powershell-release?tag=stable" -ForegroundColor Cyan
    exit 1
}

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
    Write-Host "Usage: .\restart.ps1 [installation-directory]"
    exit 1
}

Push-Location $InstallDir

$composeFiles = @("-f", "docker-compose.yml")
if (Test-Path "docker-compose.local.yml") {
    $composeFiles += @("-f", "docker-compose.local.yml")
}

Write-Color "Restarting services..." "Blue"
Invoke-DockerCompose @composeFiles restart

Write-Color "✓ Services restarted" "Green"
Write-Host ""

# Show status and URL
$clientPort = "3000"
if (Test-Path ".env") {
    $envContent = Get-Content ".env"
    $portLine = $envContent | Where-Object { $_ -match "^CLIENT_PORT=" }
    if ($portLine) {
        $clientPort = ($portLine -split "=", 2)[1]
    }
}

Write-Color "Access tadata.ai at: " "White" -NoNewline
Write-Color "http://localhost:$clientPort" "Blue"

Pop-Location
