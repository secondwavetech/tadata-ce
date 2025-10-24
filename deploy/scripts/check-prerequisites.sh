#!/usr/bin/env bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

failed=0

# Check Docker
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker is installed"
    
    # Check if Docker daemon is running
    if docker info &> /dev/null; then
        echo -e "${GREEN}✓${NC} Docker is running"
    else
        echo -e "${RED}✗${NC} Docker is not running"
        echo "  Please start Docker Desktop or Docker daemon"
        failed=1
    fi
    
    # Check Docker version
    docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null | cut -d. -f1)
    if [ "$docker_version" -ge 20 ]; then
        echo -e "${GREEN}✓${NC} Docker version is adequate ($(docker version --format '{{.Server.Version}}' 2>/dev/null))"
    else
        echo -e "${YELLOW}⚠${NC} Docker version may be too old ($(docker version --format '{{.Server.Version}}' 2>/dev/null))"
        echo "  Recommended: Docker 20.10 or newer"
    fi
else
    echo -e "${RED}✗${NC} Docker is not installed"
    echo "  Install from: https://www.docker.com/products/docker-desktop"
    failed=1
fi

# Check Docker Compose
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker Compose is available"
else
    echo -e "${RED}✗${NC} Docker Compose is not available"
    echo "  Docker Compose V2 is required"
    failed=1
fi

# Check available disk space
if command -v df &> /dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        available_gb=$(df -g . | tail -1 | awk '{print $4}')
    else
        available_gb=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
    fi
    
    if [ "$available_gb" -ge 10 ]; then
        echo -e "${GREEN}✓${NC} Sufficient disk space available (${available_gb}GB)"
    else
        echo -e "${YELLOW}⚠${NC} Low disk space (${available_gb}GB available)"
        echo "  Recommended: 10GB or more"
    fi
fi

# Check available memory (macOS and Linux)
if command -v sysctl &> /dev/null && [[ "$OSTYPE" == "darwin"* ]]; then
    total_mem_bytes=$(sysctl -n hw.memsize)
    total_mem_gb=$((total_mem_bytes / 1024 / 1024 / 1024))
    
    if [ "$total_mem_gb" -ge 4 ]; then
        echo -e "${GREEN}✓${NC} Sufficient memory available (${total_mem_gb}GB)"
    else
        echo -e "${YELLOW}⚠${NC} Low memory (${total_mem_gb}GB)"
        echo "  Recommended: 4GB or more"
    fi
elif [ -f /proc/meminfo ]; then
    total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    total_mem_gb=$((total_mem_kb / 1024 / 1024))
    
    if [ "$total_mem_gb" -ge 4 ]; then
        echo -e "${GREEN}✓${NC} Sufficient memory available (${total_mem_gb}GB)"
    else
        echo -e "${YELLOW}⚠${NC} Low memory (${total_mem_gb}GB)"
        echo "  Recommended: 4GB or more"
    fi
fi

if [ $failed -eq 1 ]; then
    exit 1
fi

exit 0
