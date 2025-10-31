#!/usr/bin/env bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Verifying installation..."
echo ""

# Check if containers are running
services=("db" "server" "faas" "function-executor" "client")
all_running=true

for service in "${services[@]}"; do
    if docker-compose ps --services --filter "status=running" | grep -q "^${service}$"; then
        echo -e "${GREEN}✓${NC} $service is running"
    else
        echo -e "${RED}✗${NC} $service is not running"
        all_running=false
    fi
done

echo ""

if [ "$all_running" = true ]; then
    echo -e "${GREEN}All services are running!${NC}"
    
    # Test server health endpoint
    sleep 5
    if curl -s http://localhost:3001/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Server health check passed"
    else
        echo -e "${YELLOW}⚠${NC} Server health check did not respond (may need more time to start)"
    fi
else
    echo -e "${RED}Some services failed to start${NC}"
    echo "Run 'docker-compose logs' to see error messages"
    exit 1
fi
