#!/bin/bash

# Quick fix script for GCP VM frontend
# This rebuilds the frontend with the correct API URL

set -e

GCP_EXTERNAL_IP="35.193.17.6"
API_URL="http://${GCP_EXTERNAL_IP}:8080/api"

echo "=========================================="
echo "Fixing Frontend API URL for GCP"
echo "=========================================="
echo "External IP: $GCP_EXTERNAL_IP"
echo "API URL: $API_URL"
echo "=========================================="
echo

# Build frontend with correct API URL
echo "→ Building frontend with API_URL=${API_URL}..."
cd frontend

docker build \
  --build-arg VITE_API_URL=${API_URL} \
  -t polling-frontend-gcp:latest \
  .

cd ..

echo
echo "→ Updating docker-compose to use local image..."

# Create a docker-compose override file
cat > docker-compose.override.yml <<EOF
version: '3.8'

services:
  frontend:
    image: polling-frontend-gcp:latest
    build:
      context: ./frontend
      dockerfile: Dockerfile
      args:
        VITE_API_URL: ${API_URL}
EOF

echo "→ Restarting frontend container..."
docker-compose up -d --build frontend

echo
echo "=========================================="
echo "✅ Frontend fixed!"
echo "=========================================="
echo
echo "Access your app at: http://${GCP_EXTERNAL_IP}"
echo
echo "Check status:"
echo "  docker-compose ps"
echo "  docker-compose logs -f frontend"
echo "=========================================="
