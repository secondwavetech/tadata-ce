#!/usr/bin/env pwsh
# View logs for Community Edition installation
# Shows logs for all or specific services
# Requires PowerShell 7.0 or later

param(
    [string]$Service = "",
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

    # Build the complete command array
    $cmdArray = @()
    foreach ($cmd in $composeCmd) {
        $cmdArray += $cmd
    }
    foreach ($arg in $Arguments) {
        $cmdArray += $arg
    }

    # Invoke with proper error handling
    $cmd = $cmdArray[0]
    $params = $cmdArray[1..($cmdArray.Length-1)]
    & $cmd $params
}

# Determine installation directory
if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    $InstallDir = Get-Location
}

if (-not (Test-Path "$InstallDir\docker-compose.yml")) {
    Write-Color "✗ No tadata installation found in: $InstallDir" "Red"
    Write-Host "Usage: .\logs.ps1 [service] [installation-directory]"
    Write-Host "Services: server, client, function-executor, faas, db"
    exit 1
}

Push-Location $InstallDir

$composeFiles = @("-f", "docker-compose.yml")
if (Test-Path "docker-compose.local.yml") {
    $composeFiles += @("-f", "docker-compose.local.yml")
}

# Validate service if specified
$validServices = @("server", "client", "function-executor", "faas", "db")
if (-not [string]::IsNullOrWhiteSpace($Service) -and $Service -notin $validServices) {
    Write-Color "Unknown service: $Service" "Yellow"
    Write-Host "(showing all logs)"
    $Service = ""
}

Write-Color "tadata CE - Logs" "Blue"
Write-Host "Directory: $InstallDir"
if (-not [string]::IsNullOrWhiteSpace($Service)) {
    Write-Host "Service: $Service"
}
Write-Color "Press Ctrl+C to exit" "Yellow"
Write-Host ""

try {
    if (-not [string]::IsNullOrWhiteSpace($Service)) {
        Invoke-DockerCompose @composeFiles logs -f --tail=200 $Service
    } else {
        Invoke-DockerCompose @composeFiles logs -f --tail=200
    }
} finally {
    Pop-Location
}
