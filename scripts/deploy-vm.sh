#!/bin/bash

#############################################
# Deployment Script for GCP VM
# This script pulls latest images and restarts containers
#############################################

set -e  # Exit on error

echo "========================================="
echo "Starting deployment on GCP VM..."
echo "========================================="

# Configuration
COMPOSE_FILE="docker-compose.yml"
PROJECT_DIR="$HOME/polling-app"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Navigate to project directory
cd "$PROJECT_DIR" || {
    echo -e "${RED}Error: Project directory not found at $PROJECT_DIR${NC}"
    exit 1
}

echo -e "${YELLOW}Step 1: Authenticating Docker with Artifact Registry...${NC}"
gcloud auth configure-docker us-central1-docker.pkg.dev --quiet

echo -e "${YELLOW}Step 2: Pulling latest Docker images...${NC}"
docker-compose pull

echo -e "${YELLOW}Step 3: Stopping current containers...${NC}"
docker-compose down

echo -e "${YELLOW}Step 4: Starting new containers...${NC}"
docker-compose up -d

echo -e "${YELLOW}Step 5: Waiting for services to start...${NC}"
sleep 15

echo -e "${YELLOW}Step 6: Checking container status...${NC}"
docker-compose ps

echo -e "${YELLOW}Step 7: Running health checks...${NC}"

# Check backend health
if curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Backend is healthy${NC}"
else
    echo -e "${RED}✗ Backend health check failed${NC}"
fi

# Check frontend health
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Frontend is healthy${NC}"
else
    echo -e "${RED}✗ Frontend health check failed${NC}"
fi

# Check database
if docker-compose exec -T postgres pg_isready -U polling_user > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Database is healthy${NC}"
else
    echo -e "${RED}✗ Database health check failed${NC}"
fi

echo -e "${YELLOW}Step 8: Cleaning up old Docker images...${NC}"
docker image prune -af > /dev/null 2>&1 || true

echo "========================================="
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo "========================================="
echo ""
echo "Service URLs:"
echo "  Backend:  http://localhost:8080"
echo "  Frontend: http://localhost"
echo ""
echo "To view logs:"
echo "  docker-compose logs -f backend"
echo "  docker-compose logs -f frontend"
echo ""
