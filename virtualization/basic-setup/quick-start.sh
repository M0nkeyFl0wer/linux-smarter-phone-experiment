#!/bin/bash

# AIROS Virtual Environment Quick Start
# Sets up and launches the basic virtualization environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emojis
ROCKET="🚀"
ROBOT="🤖"
PHONE="📱"
GEAR="⚙️"
CHECK="✅"
CROSS="❌"

echo -e "${CYAN}${ROCKET} AIROS Virtual Environment Quick Start${NC}"
echo "==========================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${CROSS} ${RED}Docker is not installed. Please install Docker first.${NC}"
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${CROSS} ${RED}Docker Compose is not installed. Please install Docker Compose first.${NC}"
    echo "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo -e "${CROSS} ${RED}Docker daemon is not running. Please start Docker.${NC}"
    exit 1
fi

echo -e "${CHECK} ${GREEN}Docker environment ready${NC}"
echo ""

# Create necessary directories
echo -e "${GEAR} Setting up directories..."
mkdir -p logs

# Make scripts executable
chmod +x scripts/*.sh

echo -e "${CHECK} ${GREEN}Setup complete${NC}"
echo ""

# Build and start the environment
echo -e "${ROBOT} Building AIROS virtual environment..."
echo "This may take a few minutes on first run..."
echo ""

# Build the Docker image
docker-compose build

echo ""
echo -e "${CHECK} ${GREEN}Build complete!${NC}"
echo ""

# Start the services
echo -e "${ROCKET} Starting AIROS virtual environment..."
docker-compose up -d

echo ""
echo -e "${CHECK} ${GREEN}AIROS Virtual Environment is now running!${NC}"
echo ""

# Wait for services to be ready
echo -e "${GEAR} Waiting for services to start..."
sleep 10

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    echo -e "${CHECK} ${GREEN}Services are running${NC}"
    echo ""

    echo -e "${BLUE}Access your AIROS environment:${NC}"
    echo "================================"
    echo -e "${PHONE} Web UI:      ${CYAN}http://localhost:3000${NC}"
    echo -e "${ROBOT} API:         ${CYAN}http://localhost:8080/api/status${NC}"
    echo -e "${GEAR} Terminal:    ${CYAN}docker exec -it airos-basic-vm /usr/local/bin/airos-terminal${NC}"
    echo ""

    echo -e "${BLUE}Quick commands:${NC}"
    echo "==============="
    echo "  View logs:    docker-compose logs -f"
    echo "  Stop:         docker-compose down"
    echo "  Restart:      docker-compose restart"
    echo "  Shell access: docker exec -it airos-basic-vm bash"
    echo ""

    echo -e "${BLUE}Demo scenarios:${NC}"
    echo "==============="
    echo "1. Open web UI and click on app icons to test compatibility fixing"
    echo "2. Use terminal commands:"
    echo "   docker exec -it airos-basic-vm airos-demo"
    echo "3. Test API directly:"
    echo "   curl http://localhost:8080/api/status"
    echo ""

    # Test API connection
    echo -e "${GEAR} Testing API connection..."
    sleep 5

    if curl -s http://localhost:8080/api/status | grep -q "running"; then
        echo -e "${CHECK} ${GREEN}API is responding correctly${NC}"

        # Show status
        echo ""
        echo -e "${BLUE}Current Status:${NC}"
        curl -s http://localhost:8080/api/status | python3 -m json.tool 2>/dev/null || echo "Status API working"

    else
        echo -e "${YELLOW}API not yet ready, may need a few more seconds...${NC}"
    fi

else
    echo -e "${CROSS} ${RED}Some services failed to start${NC}"
    echo "Check logs with: docker-compose logs"
    exit 1
fi

echo ""
echo -e "${ROCKET} ${GREEN}AIROS Virtual Environment is ready!${NC}"
echo -e "${PURPLE}Happy testing! 🧪${NC}"
echo ""

# Optionally open web browser
if command -v xdg-open &> /dev/null; then
    read -p "Open web UI in browser? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        xdg-open http://localhost:3000
    fi
fi