#!/usr/bin/env bash
set -e

# Restart Community Edition installation

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Detect Docker Compose command (V2 preferred, V1 fallback)
if docker compose version &> /dev/null; then
  DOCKER_COMPOSE=(docker compose)
elif command -v docker-compose &> /dev/null; then
  DOCKER_COMPOSE=(docker-compose)
else
  echo -e "${RED}✗ Docker Compose is not available${NC}" >&2
  exit 1
fi

INSTALL_DIR="${1:-$(pwd)}"

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

echo -e "${BLUE}Restarting services...${NC}"
"${DOCKER_COMPOSE[@]}" $COMPOSE_FILES restart

echo -e "${GREEN}✓ Services restarted${NC}"

# Show status and URL
CLIENT_PORT=3000
if [ -f .env ]; then
  CLIENT_PORT=$(grep "^CLIENT_PORT=" .env | cut -d '=' -f2)
  CLIENT_PORT="${CLIENT_PORT:-3000}"
fi

echo -e "Access tadata.ai at: ${BLUE}http://localhost:${CLIENT_PORT}${NC}"
