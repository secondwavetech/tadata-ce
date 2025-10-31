#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   tadata.ai Community Edition Setup       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
echo -e "${BLUE}[1/5] Checking prerequisites...${NC}"
./scripts/check-prerequisites.sh || exit 1
echo -e "${GREEN}✓ Prerequisites met${NC}\n"

# Generate secrets
echo -e "${BLUE}[2/5] Generating secure secrets...${NC}"
./scripts/generate-secrets.sh
echo -e "${GREEN}✓ Secrets generated${NC}\n"

# Get Anthropic API Key and Port
echo -e "${BLUE}[3/6] Configuration${NC}"
if [ -f .env ]; then
    echo -e "${YELLOW}⚠ .env file already exists${NC}"
    read -p "Overwrite existing configuration? (y/N): " overwrite
    if [[ ! $overwrite =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Using existing configuration${NC}\n"
    else
        rm .env
    fi
fi

if [ ! -f .env ]; then
    echo "Please provide your Anthropic API key."
    echo "Get one at: https://console.anthropic.com/"
    echo ""

    # Allow providing ANTHROPIC_API_KEY via environment for non-interactive installs
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        anthropic_key="$ANTHROPIC_API_KEY"
        echo "Using ANTHROPIC_API_KEY from environment"
    else
        read -p "Anthropic API Key: " anthropic_key
    fi
    
    if [ -z "$anthropic_key" ]; then
        echo -e "${RED}✗ API key is required${NC}"
        exit 1
    fi

    # Allow pre-setting CLIENT_PORT via environment
    if [ -n "$CLIENT_PORT" ]; then
        client_port="$CLIENT_PORT"
        echo "Using CLIENT_PORT=$client_port from environment"
    else
        read -p "Frontend port [3000]: " client_port
        client_port="${client_port:-3000}"
    fi
    
    # Create .env from template
    cp .env.template .env
    
    # Set API key and port
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|ANTHROPIC_API_KEY=|ANTHROPIC_API_KEY=$anthropic_key|" .env
        sed -i '' "s|CLIENT_PORT=3000|CLIENT_PORT=$client_port|" .env
    else
        sed -i "s|ANTHROPIC_API_KEY=|ANTHROPIC_API_KEY=$anthropic_key|" .env
        sed -i "s|CLIENT_PORT=3000|CLIENT_PORT=$client_port|" .env
    fi
    
    # Load generated secrets from temporary file
    if [ -f /tmp/tadata-secrets.env ]; then
        source /tmp/tadata-secrets.env
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|JWT_SECRET=|JWT_SECRET=$JWT_SECRET|" .env
            sed -i '' "s|ENCRYPTION_KEY=|ENCRYPTION_KEY=$ENCRYPTION_KEY|" .env
            sed -i '' "s|INTERNAL_API_SECRET=|INTERNAL_API_SECRET=$INTERNAL_API_SECRET|" .env
            sed -i '' "s|DOWNLOAD_TOKEN_SECRET=|DOWNLOAD_TOKEN_SECRET=$DOWNLOAD_TOKEN_SECRET|" .env
            sed -i '' "s|POSTGRES_PASSWORD=|POSTGRES_PASSWORD=$POSTGRES_PASSWORD|" .env
            sed -i '' "s|POSTGRES_TADATA_PASSWORD=|POSTGRES_TADATA_PASSWORD=$POSTGRES_TADATA_PASSWORD|" .env
        else
            sed -i "s|JWT_SECRET=|JWT_SECRET=$JWT_SECRET|" .env
            sed -i "s|ENCRYPTION_KEY=|ENCRYPTION_KEY=$ENCRYPTION_KEY|" .env
            sed -i "s|INTERNAL_API_SECRET=|INTERNAL_API_SECRET=$INTERNAL_API_SECRET|" .env
            sed -i "s|DOWNLOAD_TOKEN_SECRET=|DOWNLOAD_TOKEN_SECRET=$DOWNLOAD_TOKEN_SECRET|" .env
            sed -i "s|POSTGRES_PASSWORD=|POSTGRES_PASSWORD=$POSTGRES_PASSWORD|" .env
            sed -i "s|POSTGRES_TADATA_PASSWORD=|POSTGRES_TADATA_PASSWORD=$POSTGRES_TADATA_PASSWORD|" .env
        fi
        
        rm /tmp/tadata-secrets.env
    fi
fi

echo -e "${GREEN}✓ Configuration complete${NC}\n"

# Database handling
echo -e "${BLUE}[4/6] Database configuration...${NC}"
EXISTING_VOLUMES=$(docker volume ls --format "{{.Name}}" | grep -E "^tadata-ce_postgres-data$" || true)
if [ -n "$EXISTING_VOLUMES" ]; then
    echo -e "${YELLOW}⚠ Existing database volume detected: $EXISTING_VOLUMES${NC}"
    read -p "Remove existing database for a clean install? (y/N): " db_choice
    if [[ $db_choice =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Removing existing database volumes...${NC}"
        docker-compose down -v 2>/dev/null || true
        echo -e "${GREEN}✓ Database volumes removed${NC}"
    else
        echo -e "${YELLOW}Keeping existing database${NC}"
    fi
else
    echo -e "${GREEN}✓ No existing database found - will create a fresh database${NC}"
fi

echo ""

# Pull images
echo -e "${BLUE}[5/6] Pulling Docker images...${NC}"
docker-compose pull || true

echo -e "${GREEN}✓ Images ready${NC}\n"

# Start services
echo -e "${BLUE}[6/6] Starting services...${NC}"
docker-compose up -d

echo -e "${BLUE}Monitoring server startup...${NC}"
MAX_WAIT=90
ELAPSED=0
SUCCESS=false
while [ $ELAPSED -lt $MAX_WAIT ]; do
  if docker ps --filter "name=tadata-server" --filter "health=healthy" | grep -q tadata-server; then
    SUCCESS=true
    break
  fi
  sleep 3
  ELAPSED=$((ELAPSED+3))
done

./scripts/verify-installation.sh || true

echo ""
if [ "$SUCCESS" = true ]; then
  echo -e "${GREEN}Installation Complete! 🎉${NC}"
else
  echo -e "${YELLOW}Services started, but health checks may still be initializing.${NC}"
fi

# Create convenience symlinks
ln -sf scripts/logs.sh logs.sh
ln -sf scripts/restart.sh restart.sh
ln -sf scripts/stop.sh stop.sh
ln -sf scripts/uninstall.sh uninstall.sh

# Show next steps
CLIENT_PORT=$(grep "^CLIENT_PORT=" .env | cut -d '=' -f2)
CLIENT_PORT="${CLIENT_PORT:-3000}"
echo -e "Access tadata.ai at: ${BLUE}http://localhost:${CLIENT_PORT}${NC}"
echo ""
echo "Useful commands:"
echo "  ./logs.sh            # View logs"
echo "  ./stop.sh            # Stop services"
echo "  ./restart.sh         # Restart services"
echo "  ./uninstall.sh       # Remove everything"
echo ""
