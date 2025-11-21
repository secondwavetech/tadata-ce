#
# tadata.ai Community Edition - Password Reset Script
# This script resets a user's password by connecting to the database container
#

# Requires -Version 5.1

# Set strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Colors for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    Write-ColorOutput "╔════════════════════════════════════════════════════════════╗" "Blue"
    Write-ColorOutput "║     tadata.ai Community Edition - Password Reset Tool     ║" "Blue"
    Write-ColorOutput "╚════════════════════════════════════════════════════════════╝" "Blue"
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Error-Message {
    param([string]$Message)
    Write-ColorOutput "Error: $Message" "Red"
}

function Write-Step {
    param(
        [string]$Step,
        [string]$Message
    )
    Write-Host "[$Step] " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvFile = Join-Path $ScriptDir ".env"

# Display header
Write-Header

# Check if .env file exists
if (-not (Test-Path $EnvFile)) {
    Write-Error-Message ".env file not found at $EnvFile"
    Write-Host "Please run this script from the deploy directory or ensure .env exists"
    exit 1
}

# Load environment variables from .env file
Write-Step "1/6" "Loading configuration..."
Get-Content $EnvFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        [Environment]::SetEnvironmentVariable($key, $value, "Process")
    }
}

# Check if Docker is running
try {
    docker ps | Out-Null
} catch {
    Write-Error-Message "Docker is not running or not accessible"
    Write-Host "Please start Docker Desktop and try again"
    exit 1
}

# Detect database container
$DbContainer = docker ps --format "{{.Names}}" | Where-Object { $_ -match "db|postgres|database" } | Select-Object -First 1

if (-not $DbContainer) {
    Write-Error-Message "Could not find database container"
    Write-Host "Make sure tadata.ai is running: docker compose up -d"
    exit 1
}

Write-Success "Found database container: $DbContainer"

# Get database credentials from env
$PostgresUser = if ($env:POSTGRES_USER) { $env:POSTGRES_USER } else { "postgres" }
$PostgresDb = if ($env:POSTGRES_DB) { $env:POSTGRES_DB } else { "tadata" }

# Prompt for user email
Write-Host ""
Write-Step "2/6" "User Information"
$UserEmail = Read-Host "Enter the email address of the user to reset"

if ([string]::IsNullOrWhiteSpace($UserEmail)) {
    Write-Error-Message "Email cannot be empty"
    exit 1
}

# Check if user exists
Write-Step "3/6" "Verifying user exists..."
$UserExistsQuery = "SELECT COUNT(*) FROM \`"user\`" WHERE email = '$UserEmail';"
$UserExists = docker exec -i $DbContainer psql -U $PostgresUser -d $PostgresDb -t -A -c $UserExistsQuery 2>$null

if (-not $UserExists -or $UserExists -eq "0") {
    Write-Error-Message "No user found with email: $UserEmail"
    exit 1
}

Write-Success "User found"

# Prompt for new password
Write-Host ""
Write-Step "4/6" "New Password"
Write-ColorOutput "Note: Password must be at least 8 characters" "Yellow"

$NewPassword = Read-Host "Enter new password" -AsSecureString
$ConfirmPassword = Read-Host "Confirm new password" -AsSecureString

# Convert secure strings to plain text for comparison
$NewPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($NewPassword))
$ConfirmPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($ConfirmPassword))

if ([string]::IsNullOrWhiteSpace($NewPasswordPlain)) {
    Write-Error-Message "Password cannot be empty"
    exit 1
}

if ($NewPasswordPlain -ne $ConfirmPasswordPlain) {
    Write-Error-Message "Passwords do not match"
    exit 1
}

if ($NewPasswordPlain.Length -lt 8) {
    Write-Error-Message "Password must be at least 8 characters"
    exit 1
}

# Hash the password using Node.js in the server container
Write-Host ""
Write-Step "5/6" "Hashing password..."
$ServerContainer = docker ps --format "{{.Names}}" | Where-Object { $_ -match "server" } | Select-Object -First 1

if (-not $ServerContainer) {
    Write-Error-Message "Could not find server container"
    Write-Host "Make sure tadata.ai server is running"
    exit 1
}

# Escape single quotes in password for Node.js
$EscapedPassword = $NewPasswordPlain -replace "'", "\'"

$HashScript = @"
const bcrypt = require('bcrypt');
bcrypt.hash('$EscapedPassword', 10).then(hash => {
    console.log(hash);
    process.exit(0);
}).catch(err => {
    console.error(err);
    process.exit(1);
});
"@

try {
    $HashedPassword = docker exec -i $ServerContainer node -e $HashScript 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to hash password"
    }
} catch {
    Write-Error-Message "Failed to hash password"
    Write-Host $HashedPassword
    exit 1
}

# Update the password in the database
Write-Step "6/6" "Updating password in database..."
$UpdateQuery = "UPDATE \`"user\`" SET password = '$HashedPassword', password_reset_token = NULL WHERE email = '$UserEmail';"

try {
    docker exec -i $DbContainer psql -U $PostgresUser -d $PostgresDb -c $UpdateQuery 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Database update failed"
    }
} catch {
    Write-Error-Message "Failed to update password in database"
    exit 1
}

# Success message
Write-Host ""
Write-ColorOutput "╔════════════════════════════════════════════════════════════╗" "Green"
Write-ColorOutput "║                  Password Reset Successful!                ║" "Green"
Write-ColorOutput "╚════════════════════════════════════════════════════════════╝" "Green"
Write-Host ""
Write-Success "Password has been reset for: $UserEmail"
Write-Success "You can now log in with your new password"
Write-Host ""

# Clear password variables from memory
$NewPasswordPlain = $null
$ConfirmPasswordPlain = $null
$EscapedPassword = $null
