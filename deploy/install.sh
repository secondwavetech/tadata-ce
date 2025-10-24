#!/usr/bin/env bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_URL="https://github.com/secondwave/tadata-ce.git"
INSTALL_DIR="${HOME}/tadata-ce"

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   tadata.ai Community Edition Installer   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}✗ git is not installed${NC}"
    echo "Please install git and try again."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed${NC}"
    echo "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Clone repository
echo -e "${BLUE}Downloading tadata.ai...${NC}"
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${RED}✗ Directory $INSTALL_DIR already exists${NC}"
    read -p "Remove existing directory and continue? (y/N): " remove
    if [[ ! $remove =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi
    rm -rf "$INSTALL_DIR"
fi

git clone "$REPO_URL" "$INSTALL_DIR"
echo -e "${GREEN}✓ Downloaded${NC}\n"

# Change to deploy directory
cd "$INSTALL_DIR/deploy"

# Run setup
echo -e "${BLUE}Starting setup...${NC}\n"
./setup.sh

echo ""
echo -e "${GREEN}Installation directory: ${NC}$INSTALL_DIR"
