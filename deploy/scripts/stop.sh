#!/usr/bin/env bash
set -e

# Stop Community Edition services (preserves data)

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

echo -e "${BLUE}Stopping services...${NC}"
"${DOCKER_COMPOSE[@]}" $COMPOSE_FILES stop

echo -e "${GREEN}✓ Services stopped (data preserved)${NC}"

echo "To start again: ${DOCKER_COMPOSE[@]} $COMPOSE_FILES up -d"
