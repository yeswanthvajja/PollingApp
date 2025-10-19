#!/bin/bash

# Simple deployment script for GCP VM
# This script copies files and rebuilds the frontend with correct API URL

set -e

GCP_INSTANCE="pooling-instance"
GCP_ZONE="us-central1-a"  # UPDATE THIS with your zone
GCP_EXTERNAL_IP="35.193.17.6"

echo "=========================================="
echo "Deploying Polling App to GCP"
echo "=========================================="
echo "Instance: $GCP_INSTANCE"
echo "Zone: $GCP_ZONE"
echo "External IP: $GCP_EXTERNAL_IP"
echo "=========================================="
echo

# Copy files to GCP VM
echo "→ Copying files to GCP VM..."
gcloud compute scp docker-compose.yml ${GCP_INSTANCE}:~/ --zone=${GCP_ZONE}
gcloud compute scp .env.gcp ${GCP_INSTANCE}:~/.env --zone=${GCP_ZONE}

# SSH and rebuild
echo
echo "→ Connecting to GCP VM and rebuilding..."
gcloud compute ssh ${GCP_INSTANCE} --zone=${GCP_ZONE} --command="
    echo 'Rebuilding frontend with API_URL=http://${GCP_EXTERNAL_IP}:8080/api'
    export VITE_API_URL=http://${GCP_EXTERNAL_IP}:8080/api

    # Rebuild and restart frontend
    docker-compose up -d --build frontend

    echo ''
    echo '✅ Deployment complete!'
    echo ''
    echo 'Check status:'
    docker-compose ps

    echo ''
    echo 'Access your app at: http://${GCP_EXTERNAL_IP}'
"

echo
echo "=========================================="
echo "✅ Done!"
echo "=========================================="
echo
echo "Access your app at: http://${GCP_EXTERNAL_IP}"
echo
