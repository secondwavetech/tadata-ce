#!/usr/bin/env bash
set -e

# View logs for Community Edition installation
# Shows logs for all or specific services

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

# Determine installation directory (default: current directory)
if [ -n "$2" ]; then
  INSTALL_DIR="$2"
elif [ -n "$1" ] && [ -d "$1" ]; then
  INSTALL_DIR="$1"
else
  INSTALL_DIR="$(pwd)"
fi

if [ ! -f "$INSTALL_DIR/docker-compose.yml" ]; then
  echo -e "${RED}✗ No tadata installation found in: $INSTALL_DIR${NC}"
  echo "Usage: $0 [service] [installation-directory]"
  echo "Services: server, client, function-executor, faas, db"
  exit 1
fi

cd "$INSTALL_DIR"

COMPOSE_FILES="-f docker-compose.yml"
# If an override exists (for dev scenarios), include it but it's optional
if [ -f "docker-compose.local.yml" ]; then
  COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.local.yml"
fi

SERVICE=""
if [ -n "$1" ] && [ "$1" != "$INSTALL_DIR" ]; then
  case "$1" in
    server|client|function-executor|faas|db)
      SERVICE="$1";;
    *) echo -e "${YELLOW}Unknown service: $1${NC} (showing all logs)";;
  esac
fi

echo -e "${BLUE}tadata CE - Logs${NC}\nDirectory: $INSTALL_DIR"
[ -n "$SERVICE" ] && echo "Service: $SERVICE"
echo -e "${YELLOW}Press Ctrl+C to exit${NC}\n"

if [ -n "$SERVICE" ]; then
  "${DOCKER_COMPOSE[@]}" $COMPOSE_FILES logs -f --tail=200 "$SERVICE"
else
  "${DOCKER_COMPOSE[@]}" $COMPOSE_FILES logs -f --tail=200
fi
