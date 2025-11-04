#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
VERSION="latest"
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
      shift
      ;;
  esac
done

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   tadata.ai Community Edition Setup       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
echo -e "${BLUE}[1/5] Checking prerequisites...${NC}"
./scripts/check-prerequisites.sh || exit 1
echo -e "${GREEN}✓ Prerequisites met${NC}"
echo ""

# Generate secrets
echo -e "${BLUE}[2/5] Generating secure secrets...${NC}"
./scripts/generate-secrets.sh
echo -e "${GREEN}✓ Secrets generated${NC}"
echo ""

# Configuration (without API key)
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
    # Allow pre-setting CLIENT_PORT via environment
    if [ -n "$CLIENT_PORT" ]; then
        client_port="$CLIENT_PORT"
        echo "Using CLIENT_PORT=$client_port from environment"
    else
        read -p "Frontend port [3000]: " client_port
        client_port="${client_port:-3000}"
    fi

    # Allow pre-setting DATA_DIR via environment
    if [ -n "$DATA_DIR" ]; then
        data_dir="$DATA_DIR"
        echo "Using DATA_DIR=$data_dir from environment"
    else
        default_data_dir="$SCRIPT_DIR/data"
        read -p "Data directory [$default_data_dir]: " data_dir
        data_dir="${data_dir:-$default_data_dir}"
    fi

    # Expand ~ to home directory if present
    data_dir="${data_dir/#\~/$HOME}"

    # Convert to absolute path
    if [[ ! "$data_dir" = /* ]]; then
        data_dir="$SCRIPT_DIR/$data_dir"
    fi

    # Create data directory if it doesn't exist
    if [ ! -d "$data_dir" ]; then
        mkdir -p "$data_dir"
        echo -e "${GREEN}✓ Created data directory: $data_dir${NC}"
    else
        echo -e "${YELLOW}Using existing data directory: $data_dir${NC}"
    fi

    # Create .env from template
    cp .env.template .env

    # Note: We intentionally skip ANTHROPIC_API_KEY - users will configure AI during first login

    # Set port, data directory, and version tags
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|CLIENT_PORT=3000|CLIENT_PORT=$client_port|" .env
        sed -i '' "s|^DATA_DIR=.*|DATA_DIR=$data_dir|" .env
        sed -i '' "s|CLIENT_IMAGE_TAG=latest|CLIENT_IMAGE_TAG=$VERSION|" .env
        sed -i '' "s|SERVER_IMAGE_TAG=latest|SERVER_IMAGE_TAG=$VERSION|" .env
        sed -i '' "s|FAAS_IMAGE_TAG=latest|FAAS_IMAGE_TAG=$VERSION|" .env
        sed -i '' "s|FUNCTION_EXECUTOR_IMAGE_TAG=latest|FUNCTION_EXECUTOR_IMAGE_TAG=$VERSION|" .env
    else
        sed -i "s|CLIENT_PORT=3000|CLIENT_PORT=$client_port|" .env
        sed -i "s|^DATA_DIR=.*|DATA_DIR=$data_dir|" .env
        sed -i "s|CLIENT_IMAGE_TAG=latest|CLIENT_IMAGE_TAG=$VERSION|" .env
        sed -i "s|SERVER_IMAGE_TAG=latest|SERVER_IMAGE_TAG=$VERSION|" .env
        sed -i "s|FAAS_IMAGE_TAG=latest|FAAS_IMAGE_TAG=$VERSION|" .env
        sed -i "s|FUNCTION_EXECUTOR_IMAGE_TAG=latest|FUNCTION_EXECUTOR_IMAGE_TAG=$VERSION|" .env
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

echo -e "${GREEN}✓ Configuration complete${NC}"
echo ""

# Database handling
echo -e "${BLUE}[4/5] Database configuration...${NC}"
DATA_DIR=$(grep "^DATA_DIR=" .env | cut -d '=' -f2)
if [ -d "$DATA_DIR/postgres" ] && [ "$(ls -A "$DATA_DIR/postgres" 2>/dev/null)" ]; then
    echo -e "${YELLOW}⚠ Existing database detected in $DATA_DIR/postgres${NC}"
    read -p "Remove existing database for a clean install? (y/N): " db_choice
    if [[ $db_choice =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Removing existing database...${NC}"
        docker-compose down 2>/dev/null || true
        rm -rf "$DATA_DIR/postgres"
        echo -e "${GREEN}✓ Database removed${NC}"
    else
        echo -e "${YELLOW}Keeping existing database${NC}"
    fi
else
    echo -e "${GREEN}✓ No existing database found - will create a fresh database${NC}"
fi

echo ""

# Pull images
echo -e "${BLUE}[5/5] Starting services...${NC}"
docker-compose pull || true
echo -e "${BLUE}Starting containers...${NC}"
docker-compose up -d

echo -e "${BLUE}Monitoring server startup...${NC}"
MAX_WAIT=90
ELAPSED=0
SUCCESS=false
while [ $ELAPSED -lt $MAX_WAIT ]; do
  if docker-compose ps server | grep -q "healthy\|Up"; then
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
ln -sf scripts/upgrade.sh upgrade.sh
ln -sf scripts/uninstall.sh uninstall.sh

# Show next steps
CLIENT_PORT=$(grep "^CLIENT_PORT=" .env | cut -d '=' -f2)
CLIENT_PORT="${CLIENT_PORT:-3000}"
echo -e "Access tadata.ai at: ${BLUE}http://localhost:${CLIENT_PORT}${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Sign up for your account (first user)"
echo "  2. After login, configure your AI settings:"
echo "     • Go to Organization Settings → System LLM tab"
echo "     • Select your LLM service (Claude, OpenAI, Gemini, or AWS Bedrock)"
echo "     • Enter your API key"
echo "     • Save configuration"
echo ""
echo "Useful commands:"
echo "  ./logs.sh            # View logs"
echo "  ./stop.sh            # Stop services"
echo "  ./restart.sh         # Restart services"
echo "  ./upgrade.sh         # Upgrade to latest version"
echo "  ./uninstall.sh       # Remove everything"
echo ""
