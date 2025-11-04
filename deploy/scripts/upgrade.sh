#!/usr/bin/env bash
set -e

# Upgrade Community Edition to latest version

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
VERSION=""
INSTALL_DIR="$(pwd)"

while [[ $# -gt 0 ]]; do
  case $1 in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --version=*)
      VERSION="${1#*=}"
      shift
      ;;
    *)
      INSTALL_DIR="$1"
      shift
      ;;
  esac
done

if [ ! -f "$INSTALL_DIR/docker-compose.yml" ]; then
  echo -e "${RED}✗ No tadata installation found in: $INSTALL_DIR${NC}"
  echo "Usage: $0 [installation-directory]"
  exit 1
fi

cd "$INSTALL_DIR"
COMPOSE_FILES="-f docker-compose.yml"
if [ -f "docker-compose.local.yml" ]; then
  COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.local.yml"
fi

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   tadata.ai Community Edition Upgrade     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Show current versions
echo -e "${BLUE}Current versions:${NC}"
docker-compose $COMPOSE_FILES ps --format "table {{.Service}}\t{{.Image}}" 2>/dev/null || true
echo ""

# Load environment variables
if [ ! -f .env ]; then
  echo -e "${RED}✗ .env file not found${NC}"
  exit 1
fi

source .env

# Update version tags in .env if specified
if [ -n "$VERSION" ]; then
  echo -e "${BLUE}Setting version to: $VERSION${NC}"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|CLIENT_IMAGE_TAG=.*|CLIENT_IMAGE_TAG=$VERSION|" .env
    sed -i '' "s|SERVER_IMAGE_TAG=.*|SERVER_IMAGE_TAG=$VERSION|" .env
    sed -i '' "s|FAAS_IMAGE_TAG=.*|FAAS_IMAGE_TAG=$VERSION|" .env
    sed -i '' "s|FUNCTION_EXECUTOR_IMAGE_TAG=.*|FUNCTION_EXECUTOR_IMAGE_TAG=$VERSION|" .env
  else
    sed -i "s|CLIENT_IMAGE_TAG=.*|CLIENT_IMAGE_TAG=$VERSION|" .env
    sed -i "s|SERVER_IMAGE_TAG=.*|SERVER_IMAGE_TAG=$VERSION|" .env
    sed -i "s|FAAS_IMAGE_TAG=.*|FAAS_IMAGE_TAG=$VERSION|" .env
    sed -i "s|FUNCTION_EXECUTOR_IMAGE_TAG=.*|FUNCTION_EXECUTOR_IMAGE_TAG=$VERSION|" .env
  fi
  echo ""
else
  echo -e "${BLUE}Upgrading to version: ${SERVER_IMAGE_TAG:-latest}${NC}"
  echo ""
fi

echo -e "${YELLOW}⚠  This will:${NC}"
echo "  • Backup current database"
echo "  • Pull Docker images"
echo "  • Stop running services"
echo "  • Start services with new images"
echo "  • Run database migrations"
echo ""

read -p "Continue with upgrade? (y/N): " CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
  echo -e "${BLUE}Upgrade cancelled.${NC}"
  exit 0
fi

echo ""
echo -e "${BLUE}[1/5] Creating database backup...${NC}"

# Create backups directory if it doesn't exist
BACKUP_DIR="${DATA_DIR}/backups"
mkdir -p "$BACKUP_DIR"

# Generate backup filename with timestamp
BACKUP_FILE="$BACKUP_DIR/tadata_backup_$(date +%Y%m%d_%H%M%S).sql"

# Perform backup using pg_dump via docker exec
if docker-compose $COMPOSE_FILES exec -T db pg_dump -U "${POSTGRES_USER:-postgres}" "${POSTGRES_DB:-tadata}" > "$BACKUP_FILE" 2>/dev/null; then
  echo -e "${GREEN}✓ Database backed up to: $BACKUP_FILE${NC}"
  echo -e "${YELLOW}  To rollback: psql -U postgres -d tadata < $BACKUP_FILE${NC}"
else
  echo -e "${RED}✗ Database backup failed${NC}"
  read -p "Continue without backup? (y/N): " CONTINUE
  if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Upgrade cancelled.${NC}"
    exit 1
  fi
fi

echo ""
echo -e "${BLUE}[2/5] Pulling latest images...${NC}"
docker-compose $COMPOSE_FILES pull

echo ""
echo -e "${BLUE}[3/5] Stopping services...${NC}"
docker-compose $COMPOSE_FILES stop

echo ""
echo -e "${BLUE}[4/5] Starting services with new images...${NC}"
docker-compose $COMPOSE_FILES up -d

echo ""
echo -e "${BLUE}[5/5] Waiting for services to be healthy...${NC}"
MAX_WAIT=90
ELAPSED=0
SUCCESS=false
while [ $ELAPSED -lt $MAX_WAIT ]; do
  if docker-compose $COMPOSE_FILES ps server | grep -q "healthy\|Up"; then
    SUCCESS=true
    break
  fi
  sleep 3
  ELAPSED=$((ELAPSED+3))
  echo -n "."
done
echo ""

if [ "$SUCCESS" = true ]; then
  echo ""
  echo -e "${GREEN}✓ Upgrade complete!${NC}"
  
  # Show new versions
  echo ""
  echo -e "${BLUE}New versions:${NC}"
  docker-compose $COMPOSE_FILES ps --format "table {{.Service}}\t{{.Image}}"
  
  # Show access URL
  CLIENT_PORT=3000
  if [ -f .env ]; then
    CLIENT_PORT=$(grep "^CLIENT_PORT=" .env | cut -d '=' -f2)
    CLIENT_PORT="${CLIENT_PORT:-3000}"
  fi
  
  echo ""
  echo -e "Access tadata.ai at: ${BLUE}http://localhost:${CLIENT_PORT}${NC}"
  
  if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
    echo ""
    echo -e "${GREEN}Database backup saved at:${NC}"
    echo "  $BACKUP_FILE"
  fi
else
  echo ""
  echo -e "${YELLOW}⚠  Services started but health checks are still initializing${NC}"
  echo "Check status with: docker-compose $COMPOSE_FILES ps"
  echo "View logs with: ./logs.sh"
  
  if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
    echo ""
    echo -e "${YELLOW}To rollback, run:${NC}"
    echo "  docker-compose $COMPOSE_FILES stop"
    echo "  docker-compose $COMPOSE_FILES exec -T db psql -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-tadata} < $BACKUP_FILE"
    echo "  docker-compose $COMPOSE_FILES up -d"
  fi
fi
