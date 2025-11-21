#!/bin/bash
#
# tadata.ai Community Edition - Password Reset Script
# This script resets a user's password by connecting to the database container
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     tadata.ai Community Edition - Password Reset Tool     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: .env file not found at $ENV_FILE${NC}"
    echo "Please run this script from the deploy directory or ensure .env exists"
    exit 1
fi

# Load environment variables
echo -e "${BLUE}[1/6]${NC} Loading configuration..."
source "$ENV_FILE"

# Check if Docker is running
if ! docker ps &> /dev/null; then
    echo -e "${RED}Error: Docker is not running or not accessible${NC}"
    echo "Please start Docker and try again"
    exit 1
fi

# Detect container name (try multiple patterns)
DB_CONTAINER=$(docker ps --format '{{.Names}}' | grep -E 'db|postgres|database' | head -n 1)

if [ -z "$DB_CONTAINER" ]; then
    echo -e "${RED}Error: Could not find database container${NC}"
    echo "Make sure tadata.ai is running: docker compose up -d"
    exit 1
fi

echo -e "${GREEN}✓${NC} Found database container: ${DB_CONTAINER}"

# Get database credentials from env
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-tadata}"

# Prompt for user email
echo ""
echo -e "${BLUE}[2/6]${NC} User Information"
read -p "Enter the email address of the user to reset: " USER_EMAIL

if [ -z "$USER_EMAIL" ]; then
    echo -e "${RED}Error: Email cannot be empty${NC}"
    exit 1
fi

# Check if user exists
echo -e "${BLUE}[3/6]${NC} Verifying user exists..."
USER_EXISTS=$(docker exec -i "$DB_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -A -c \
    "SELECT COUNT(*) FROM \"user\" WHERE email = '$USER_EMAIL';" 2>/dev/null || echo "0")

if [ "$USER_EXISTS" -eq "0" ]; then
    echo -e "${RED}Error: No user found with email: $USER_EMAIL${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} User found"

# Prompt for new password
echo ""
echo -e "${BLUE}[4/6]${NC} New Password"
echo -e "${YELLOW}Note: Password must be at least 8 characters${NC}"
read -s -p "Enter new password: " NEW_PASSWORD
echo ""
read -s -p "Confirm new password: " CONFIRM_PASSWORD
echo ""

if [ -z "$NEW_PASSWORD" ]; then
    echo -e "${RED}Error: Password cannot be empty${NC}"
    exit 1
fi

if [ "$NEW_PASSWORD" != "$CONFIRM_PASSWORD" ]; then
    echo -e "${RED}Error: Passwords do not match${NC}"
    exit 1
fi

if [ ${#NEW_PASSWORD} -lt 8 ]; then
    echo -e "${RED}Error: Password must be at least 8 characters${NC}"
    exit 1
fi

# Hash the password using Node.js in the server container
echo ""
echo -e "${BLUE}[5/6]${NC} Hashing password..."
SERVER_CONTAINER=$(docker ps --format '{{.Names}}' | grep -E 'server' | head -n 1)

if [ -z "$SERVER_CONTAINER" ]; then
    echo -e "${RED}Error: Could not find server container${NC}"
    echo "Make sure tadata.ai server is running"
    exit 1
fi

HASHED_PASSWORD=$(docker exec -i "$SERVER_CONTAINER" node -e "
const bcrypt = require('bcrypt');
bcrypt.hash('$NEW_PASSWORD', 10).then(hash => {
    console.log(hash);
    process.exit(0);
}).catch(err => {
    console.error(err);
    process.exit(1);
});
" 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to hash password${NC}"
    echo "$HASHED_PASSWORD"
    exit 1
fi

# Update the password in the database
echo -e "${BLUE}[6/6]${NC} Updating password in database..."
docker exec -i "$DB_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c \
    "UPDATE \"user\" SET password = '$HASHED_PASSWORD', password_reset_token = NULL WHERE email = '$USER_EMAIL';" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to update password in database${NC}"
    exit 1
fi

# Success message
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  Password Reset Successful!                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓${NC} Password has been reset for: ${BLUE}$USER_EMAIL${NC}"
echo -e "${GREEN}✓${NC} You can now log in with your new password"
echo ""
