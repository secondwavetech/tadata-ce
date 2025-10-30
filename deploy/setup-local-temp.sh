#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   tadata.ai CE Setup (LOCAL TEST)         ║${NC}"
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

# Get Anthropic API Key
echo -e "${BLUE}[3/5] Configuration${NC}"
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
    echo "(or press Enter to use test key for basic testing)"
    echo ""
    read -p "Anthropic API Key: " anthropic_key

    if [ -z "$anthropic_key" ]; then
        echo -e "${YELLOW}Using test API key (for testing only)${NC}"
        anthropic_key="sk-test-key-not-for-production"
    fi

    # Create .env from template
    cp .env.template .env

    # Set API key
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|ANTHROPIC_API_KEY=|ANTHROPIC_API_KEY=$anthropic_key|" .env
    else
        sed -i "s|ANTHROPIC_API_KEY=|ANTHROPIC_API_KEY=$anthropic_key|" .env
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

# Skip pulling images (we're using local images)
echo -e "${BLUE}[4/5] Using local images (skipping pull)...${NC}"
echo -e "${GREEN}✓ Local images ready${NC}\n"

# Start services with local override
echo -e "${BLUE}[5/5] Starting services...${NC}"
docker-compose -f docker-compose.yml -f docker-compose.local.yml up -d
echo ""

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 10

# Verify installation
./scripts/verify-installation.sh

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Installation Complete! 🎉             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Access tadata.ai at: ${BLUE}http://localhost:3000${NC}"
echo ""
echo "Useful commands:"
echo "  View logs:    docker-compose -f docker-compose.yml -f docker-compose.local.yml logs -f"
echo "  Stop:         docker-compose -f docker-compose.yml -f docker-compose.local.yml stop"
echo "  Restart:      docker-compose -f docker-compose.yml -f docker-compose.local.yml restart"
echo "  Remove:       docker-compose -f docker-compose.yml -f docker-compose.local.yml down"
echo ""
