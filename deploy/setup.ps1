#!/usr/bin/env pwsh
# tadata.ai Community Edition Setup Script for Windows
# Requires PowerShell 5.1 or later

param(
    [string]$Version = "latest"
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

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Color "╔════════════════════════════════════════════╗" "Cyan"
Write-Color "║   tadata.ai Community Edition Setup       ║" "Cyan"
Write-Color "╚════════════════════════════════════════════╝" "Cyan"
Write-Host ""

# [1/5] Check prerequisites
Write-Color "[1/5] Checking prerequisites..." "Cyan"

# Check Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Color "✗ Docker is not installed" "Red"
    Write-Host "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    exit 1
}

# Check Docker Compose (V2 or V1)
$composeCmd = Get-DockerComposeCommand
if (-not $composeCmd) {
    Write-Color "✗ Docker Compose is not installed" "Red"
    Write-Host "Please install Docker Compose"
    Write-Host "Modern Docker Desktop includes Docker Compose V2 by default"
    exit 1
}

Write-Color "✓ Prerequisites met" "Green"
Write-Host ""

# [2/5] Generate secrets
Write-Color "[2/5] Generating secure secrets..." "Cyan"

function Get-RandomBase64 {
    param([int]$Bytes = 32)
    $randomBytes = New-Object byte[] $Bytes
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($randomBytes)
    return [Convert]::ToBase64String($randomBytes)
}

function Get-RandomHex {
    param([int]$Bytes = 32)
    $randomBytes = New-Object byte[] $Bytes
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($randomBytes)
    return ($randomBytes | ForEach-Object { $_.ToString("x2") }) -join ''
}

$JWT_SECRET = Get-RandomBase64 32
$ENCRYPTION_KEY = Get-RandomHex 32
$INTERNAL_API_SECRET = Get-RandomBase64 32
$DOWNLOAD_TOKEN_SECRET = Get-RandomBase64 32
$POSTGRES_PASSWORD = Get-RandomBase64 24
$POSTGRES_TADATA_PASSWORD = Get-RandomBase64 24

Write-Color "✓ Secrets generated" "Green"
Write-Host ""

# [3/5] Configuration
Write-Color "[3/5] Configuration" "Cyan"

if (Test-Path "$scriptDir\.env") {
    Write-Color "⚠ .env file already exists" "Yellow"
    $overwrite = Read-Host "Overwrite existing configuration? (y/N)"
    if ($overwrite -notmatch '^[Yy]$') {
        Write-Color "Using existing configuration" "Yellow"
        Write-Host ""
    } else {
        Remove-Item "$scriptDir\.env"
    }
}

if (-not (Test-Path "$scriptDir\.env")) {
    # Get CLIENT_PORT
    if ($env:CLIENT_PORT) {
        $clientPort = $env:CLIENT_PORT
        Write-Host "Using CLIENT_PORT=$clientPort from environment"
    } else {
        $clientPort = Read-Host "Frontend port [3000]"
        if ([string]::IsNullOrWhiteSpace($clientPort)) {
            $clientPort = "3000"
        }
    }

    # Get DATA_DIR
    if ($env:DATA_DIR) {
        $dataDir = $env:DATA_DIR
        Write-Host "Using DATA_DIR=$dataDir from environment"
    } else {
        $defaultDataDir = Join-Path $scriptDir "data"
        $dataDirInput = Read-Host "Data directory [$defaultDataDir]"
        $dataDir = if ([string]::IsNullOrWhiteSpace($dataDirInput)) { $defaultDataDir } else { $dataDirInput }
    }

    # Convert to absolute path
    if (-not [System.IO.Path]::IsPathRooted($dataDir)) {
        $dataDir = Join-Path $scriptDir $dataDir
    }

    # Create data directory if it doesn't exist
    if (-not (Test-Path $dataDir)) {
        New-Item -ItemType Directory -Path $dataDir | Out-Null
        Write-Color "✓ Created data directory: $dataDir" "Green"
    } else {
        Write-Color "Using existing data directory: $dataDir" "Yellow"
    }

    # Create .env from template
    Copy-Item "$scriptDir\.env.template" "$scriptDir\.env"

    # Read .env content
    $envContent = Get-Content "$scriptDir\.env" -Raw

    # Replace values
    $envContent = $envContent -replace 'CLIENT_PORT=3000', "CLIENT_PORT=$clientPort"
    $envContent = $envContent -replace '^DATA_DIR=.*', "DATA_DIR=$dataDir"
    $envContent = $envContent -replace 'CLIENT_IMAGE_TAG=latest', "CLIENT_IMAGE_TAG=$Version"
    $envContent = $envContent -replace 'SERVER_IMAGE_TAG=latest', "SERVER_IMAGE_TAG=$Version"
    $envContent = $envContent -replace 'FAAS_IMAGE_TAG=latest', "FAAS_IMAGE_TAG=$Version"
    $envContent = $envContent -replace 'FUNCTION_EXECUTOR_IMAGE_TAG=latest', "FUNCTION_EXECUTOR_IMAGE_TAG=$Version"
    
    # Insert secrets
    $envContent = $envContent -replace 'JWT_SECRET=', "JWT_SECRET=$JWT_SECRET"
    $envContent = $envContent -replace 'ENCRYPTION_KEY=', "ENCRYPTION_KEY=$ENCRYPTION_KEY"
    $envContent = $envContent -replace 'INTERNAL_API_SECRET=', "INTERNAL_API_SECRET=$INTERNAL_API_SECRET"
    $envContent = $envContent -replace 'DOWNLOAD_TOKEN_SECRET=', "DOWNLOAD_TOKEN_SECRET=$DOWNLOAD_TOKEN_SECRET"
    $envContent = $envContent -replace 'POSTGRES_PASSWORD=', "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"
    $envContent = $envContent -replace 'POSTGRES_TADATA_PASSWORD=', "POSTGRES_TADATA_PASSWORD=$POSTGRES_TADATA_PASSWORD"

    # Write back to .env
    $envContent | Set-Content "$scriptDir\.env" -NoNewline
}

Write-Color "✓ Configuration complete" "Green"
Write-Host ""

# [4/5] Database handling
Write-Color "[4/5] Database configuration..." "Cyan"

$envVars = Get-Content "$scriptDir\.env" | Where-Object { $_ -match '^DATA_DIR=' }
$dataDir = ($envVars -split '=', 2)[1]

$postgresPath = Join-Path $dataDir "postgres"
if ((Test-Path $postgresPath) -and ((Get-ChildItem $postgresPath -ErrorAction SilentlyContinue).Count -gt 0)) {
    Write-Color "⚠ Existing database detected in $postgresPath" "Yellow"
    $dbChoice = Read-Host "Remove existing database for a clean install? (y/N)"
    if ($dbChoice -match '^[Yy]$') {
        Write-Color "Removing existing database..." "Yellow"
        Invoke-DockerCompose -f "$scriptDir\docker-compose.yml" down 2>$null
        Remove-Item -Recurse -Force $postgresPath -ErrorAction SilentlyContinue
        Write-Color "✓ Database removed" "Green"
    } else {
        Write-Color "Keeping existing database" "Yellow"
    }
} else {
    Write-Color "✓ No existing database found - will create a fresh database" "Green"
}

Write-Host ""

# [5/5] Start services
Write-Color "[5/5] Starting services..." "Cyan"
Push-Location $scriptDir
Invoke-DockerCompose pull 2>$null
Write-Color "Starting containers..." "Cyan"
Invoke-DockerCompose up -d

Write-Color "Monitoring server startup..." "Cyan"
$maxWait = 90
$elapsed = 0
$success = $false

while ($elapsed -lt $maxWait) {
    $status = Invoke-DockerCompose ps server 2>$null | Select-String -Pattern "healthy|Up"
    if ($status) {
        $success = $true
        break
    }
    Start-Sleep -Seconds 3
    $elapsed += 3
}

Pop-Location

Write-Host ""
if ($success) {
    Write-Color "Installation Complete! 🎉" "Green"
} else {
    Write-Color "Services started, but health checks may still be initializing." "Yellow"
}

# Show next steps
$envVars = Get-Content "$scriptDir\.env" | Where-Object { $_ -match '^CLIENT_PORT=' }
$clientPort = if ($envVars) { ($envVars -split '=', 2)[1] } else { "3000" }

Write-Host ""
Write-Color "Access tadata.ai at: " "White" -NoNewline
Write-Color "http://localhost:$clientPort" "Cyan"
Write-Host ""
Write-Color "Next Steps:" "Yellow"
Write-Host "  1. Sign up for your account (first user)"
Write-Host "  2. After login, configure your AI settings:"
Write-Host "     • Go to Organization Settings → System LLM tab"
Write-Host "     • Select your LLM service (Claude, OpenAI, Gemini, or AWS Bedrock)"
Write-Host "     • Enter your API key"
Write-Host "     • Save configuration"
Write-Host ""
Write-Host "Useful commands:"
Write-Host "  .\scripts\logs.ps1         # View logs"
Write-Host "  .\scripts\stop.ps1         # Stop services"
Write-Host "  .\scripts\restart.ps1      # Restart services"
Write-Host "  .\scripts\uninstall.ps1    # Remove everything"
Write-Host ""
