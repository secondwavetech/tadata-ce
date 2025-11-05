#!/usr/bin/env bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_URL="https://github.com/secondwavetech/tadata-ce.git"

# Parse arguments
VERSION="latest"
INSTALL_DIR=""

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
    --dir)
      INSTALL_DIR="$2"
      shift 2
      ;;
    --dir=*)
      INSTALL_DIR="${1#*=}"
      shift
      ;;
    *)
      echo -e "${RED}Unknown argument: $1${NC}"
      echo "Usage: $0 [--version=VERSION] [--dir=DIRECTORY]"
      exit 1
      ;;
  esac
done

# Default to ~/tadata-ce if no directory specified
if [ -z "$INSTALL_DIR" ]; then
  INSTALL_DIR="$HOME/tadata-ce"
fi

# Expand ~ to home directory if present
INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"

# Convert to absolute path
if [[ ! "$INSTALL_DIR" = /* ]]; then
  INSTALL_DIR="$PWD/$INSTALL_DIR"
fi

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   tadata.ai Community Edition Installer   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Installation directory:${NC} $INSTALL_DIR"
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

# Prepare installation directory
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${BLUE}Creating installation directory...${NC}"
    mkdir -p "$INSTALL_DIR"
    echo -e "${GREEN}✓ Directory created${NC}"
    echo ""
else
    # If directory is not empty, confirm
    if [ "$(ls -A "$INSTALL_DIR" 2>/dev/null)" ]; then
        echo -e "${YELLOW}⚠ Directory $INSTALL_DIR is not empty.${NC}"
        read -p "Continue and potentially overwrite files? (y/N): " cont
        if [[ ! $cont =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Installation cancelled.${NC}"
            echo -e "To install in a different directory, use: ${BLUE}--dir=/path/to/directory${NC}"
            exit 1
        fi
        echo ""
    fi
fi

# Clone to a temporary directory, then copy only the deploy assets
TMP_DIR=$(mktemp -d)
echo -e "${BLUE}Downloading tadata.ai...${NC}"
git clone "$REPO_URL" "$TMP_DIR" >/dev/null 2>&1
cp -R "$TMP_DIR/deploy/." "$INSTALL_DIR/"
rm -rf "$TMP_DIR"
echo -e "${GREEN}✓ Downloaded${NC}"
echo ""

# Make sure scripts are executable
chmod +x "$INSTALL_DIR"/setup.sh || true
chmod +x "$INSTALL_DIR"/scripts/*.sh || true

# Change to installation directory
cd "$INSTALL_DIR"

# Run setup
# If invoked via curl | bash, stdin is a pipe; explicitly feed setup.sh from the TTY.
if [ ! -t 0 ] && [ -e /dev/tty ]; then
  bash ./setup.sh --version="$VERSION" </dev/tty
else
  ./setup.sh --version="$VERSION"
fi

echo ""
echo -e "${GREEN}Installation directory: ${NC}$INSTALL_DIR"
echo ""
