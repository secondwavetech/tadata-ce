#!/usr/bin/env pwsh
# tadata.ai Community Edition Upgrade Script for Windows
# Requires PowerShell 7.0 or later

param(
    [string]$Version = "",
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
    Write-Host "Usage: .\upgrade.ps1 [-Version <version>] [-InstallDir <path>]"
    exit 1
}

Set-Location $InstallDir

# Check for compose files
$composeFiles = @("-f", "docker-compose.yml")
if (Test-Path "docker-compose.local.yml") {
    $composeFiles += @("-f", "docker-compose.local.yml")
}

Write-Color "╔════════════════════════════════════════════╗" "Cyan"
Write-Color "║   tadata.ai Community Edition Upgrade     ║" "Cyan"
Write-Color "╚════════════════════════════════════════════╝" "Cyan"
Write-Host ""

# Show current versions
Write-Color "Current versions:" "Cyan"
Invoke-DockerCompose @composeFiles ps --format "table {{.Service}}\t{{.Image}}" 2>$null
Write-Host ""

# Load environment variables
if (-not (Test-Path ".env")) {
    Write-Color "✗ .env file not found" "Red"
    exit 1
}

# Parse .env file
$envVars = @{}
Get-Content ".env" | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        $envVars[$matches[1].Trim()] = $matches[2].Trim()
    }
}

# Update version tags in .env if specified
if (-not [string]::IsNullOrWhiteSpace($Version)) {
    Write-Color "Setting version to: $Version" "Cyan"
    $envContent = Get-Content ".env" -Raw
    $envContent = $envContent -replace '(?m)^CLIENT_IMAGE_TAG=.*$', "CLIENT_IMAGE_TAG=$Version"
    $envContent = $envContent -replace '(?m)^SERVER_IMAGE_TAG=.*$', "SERVER_IMAGE_TAG=$Version"
    $envContent = $envContent -replace '(?m)^FAAS_IMAGE_TAG=.*$', "FAAS_IMAGE_TAG=$Version"
    $envContent = $envContent -replace '(?m)^FUNCTION_EXECUTOR_IMAGE_TAG=.*$', "FUNCTION_EXECUTOR_IMAGE_TAG=$Version"
    $envContent | Set-Content ".env" -NoNewline
    Write-Host ""
} else {
    $currentVersion = if ($envVars.ContainsKey("SERVER_IMAGE_TAG")) { $envVars["SERVER_IMAGE_TAG"] } else { "latest" }
    Write-Color "Upgrading to version: $currentVersion" "Cyan"
    Write-Host ""
}

Write-Color "⚠  This will:" "Yellow"
Write-Host "  • Backup current database"
Write-Host "  • Pull Docker images"
Write-Host "  • Stop running services"
Write-Host "  • Start services with new images"
Write-Host "  • Run database migrations"
Write-Host ""

$confirm = Read-Host "Continue with upgrade? (y/N)"
if ($confirm -notmatch '^[Yy]$') {
    Write-Color "Upgrade cancelled." "Cyan"
    exit 0
}

Write-Host ""
Write-Color "[1/5] Creating database backup..." "Cyan"

# Get DATA_DIR from env
$dataDir = if ($envVars.ContainsKey("DATA_DIR")) { $envVars["DATA_DIR"] } else { ".\data" }
$backupDir = Join-Path $dataDir "backups"

# Create backups directory if it doesn't exist
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

# Generate backup filename with timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = Join-Path $backupDir "tadata_backup_$timestamp.sql"

# Perform backup using pg_dump via docker exec
$postgresUser = if ($envVars.ContainsKey("POSTGRES_USER")) { $envVars["POSTGRES_USER"] } else { "postgres" }
$postgresDb = if ($envVars.ContainsKey("POSTGRES_DB")) { $envVars["POSTGRES_DB"] } else { "tadata" }

try {
    Invoke-DockerCompose @composeFiles exec -T db pg_dump -U $postgresUser $postgresDb | Out-File -FilePath $backupFile -Encoding utf8 2>$null
    if (Test-Path $backupFile) {
        Write-Color "✓ Database backed up to: $backupFile" "Green"
        Write-Color "  To rollback: psql -U postgres -d tadata < $backupFile" "Yellow"
    } else {
        throw "Backup file was not created"
    }
} catch {
    Write-Color "✗ Database backup failed" "Red"
    $continue = Read-Host "Continue without backup? (y/N)"
    if ($continue -notmatch '^[Yy]$') {
        Write-Color "Upgrade cancelled." "Cyan"
        exit 1
    }
    $backupFile = ""
}

Write-Host ""
Write-Color "[2/5] Pulling latest images..." "Cyan"
Invoke-DockerCompose @composeFiles pull

Write-Host ""
Write-Color "[3/5] Stopping services..." "Cyan"
Invoke-DockerCompose @composeFiles stop

Write-Host ""
Write-Color "[4/5] Starting services with new images..." "Cyan"
Invoke-DockerCompose @composeFiles up -d

Write-Host ""
Write-Color "[5/5] Waiting for services to be healthy..." "Cyan"
$maxWait = 90
$elapsed = 0
$success = $false

while ($elapsed -lt $maxWait) {
    $status = Invoke-DockerCompose @composeFiles ps server 2>$null | Select-String -Pattern "healthy|Up"
    if ($status) {
        $success = $true
        break
    }
    Start-Sleep -Seconds 3
    $elapsed += 3
    Write-Host "." -NoNewline
}
Write-Host ""

if ($success) {
    Write-Host ""
    Write-Color "✓ Upgrade complete!" "Green"

    # Show new versions
    Write-Host ""
    Write-Color "New versions:" "Cyan"
    Invoke-DockerCompose @composeFiles ps --format "table {{.Service}}\t{{.Image}}"

    # Show access URL
    $clientPort = if ($envVars.ContainsKey("CLIENT_PORT")) { $envVars["CLIENT_PORT"] } else { "3000" }

    Write-Host ""
    Write-Color "Access tadata.ai at: " "White" -NoNewline
    Write-Color "http://localhost:$clientPort" "Cyan"

    if (-not [string]::IsNullOrWhiteSpace($backupFile) -and (Test-Path $backupFile)) {
        Write-Host ""
        Write-Color "Database backup saved at:" "Green"
        Write-Host "  $backupFile"
    }
} else {
    Write-Host ""
    Write-Color "⚠  Services started but health checks are still initializing" "Yellow"
    $composeCmd = Get-DockerComposeCommand
    $composeCmdStr = $composeCmd -join ' '
    Write-Host "Check status with: $composeCmdStr $($composeFiles -join ' ') ps"
    Write-Host "View logs with: .\logs.ps1"

    if (-not [string]::IsNullOrWhiteSpace($backupFile) -and (Test-Path $backupFile)) {
        Write-Host ""
        Write-Color "To rollback, run:" "Yellow"
        Write-Host "  $composeCmdStr $($composeFiles -join ' ') stop"
        Write-Host "  $composeCmdStr $($composeFiles -join ' ') exec -T db psql -U $postgresUser -d $postgresDb < $backupFile"
        Write-Host "  $composeCmdStr $($composeFiles -join ' ') up -d"
    }
}
