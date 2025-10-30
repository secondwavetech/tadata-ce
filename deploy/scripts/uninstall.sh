#!/usr/bin/env bash
set -e

# Uninstall Community Edition
# Removes containers and volumes; optionally remove installation directory

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

echo -e "${RED}⚠️  WARNING: This will permanently delete:${NC}"
echo "  • All tadata containers"
echo "  • All database data"
echo "  • All function data"
echo ""

docker-compose $COMPOSE_FILES ps || true

echo ""
read -p "Type 'yes' to confirm uninstall: " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo -e "${BLUE}Uninstall cancelled.${NC}"
  exit 0
fi

echo -e "${YELLOW}Stopping and removing containers...${NC}"
docker-compose $COMPOSE_FILES down

echo -e "${YELLOW}Removing volumes...${NC}"
docker-compose $COMPOSE_FILES down -v

echo -e "${GREEN}✓ Containers and volumes removed${NC}"

echo ""
read -p "Remove installation directory '$INSTALL_DIR'? (y/N): " REMOVE
if [[ $REMOVE =~ ^[Yy]$ ]]; then
  cd .. && rm -rf "$INSTALL_DIR"
  echo -e "${GREEN}✓ Installation directory removed${NC}"
else
  echo -e "${BLUE}Installation directory preserved${NC}"
fi
