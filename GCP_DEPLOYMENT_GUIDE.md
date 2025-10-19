# GCP VM Deployment Guide - Polling App

## Current Status on Your GCP VM

Based on your logs:
- ✅ **PostgreSQL**: Healthy and running
- ✅ **Backend**: Running and responding (but healthcheck using wrong method)
- ⚠️ **Frontend**: Unhealthy (healthcheck checking wrong endpoint)
- ⚠️ **API Connection**: Frontend can't reach backend (CORS or URL issue)

---

## Quick Fix for Your Running Instance

### Option 1: Restart with Fixed Healthchecks

SSH into your GCP VM and run:

```bash
# Stop all containers
docker-compose down

# Pull latest images (if using registry)
docker pull us-central1-docker.pkg.dev/yeswanth-475406/yeswanth/polling-backend:latest
docker pull us-central1-docker.pkg.dev/yeswanth-475406/yeswanth/polling-frontend:latest

# Start with fixed healthchecks
docker-compose up -d
```

### Option 2: Override Healthchecks Temporarily

Create a `docker-compose.override.yml` file:

```yaml
version: '3.8'

services:
  backend:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]

  frontend:
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost/health"]
    environment:
      - VITE_API_URL=http://YOUR_GCP_EXTERNAL_IP:8080/api
```

Then restart:
```bash
docker-compose down
docker-compose up -d
```

---

## Complete Rebuild and Redeploy

### Step 1: Rebuild Docker Images Locally

On your **local machine** (where you have the updated Dockerfiles):

```bash
# Set your GCP project and registry
export GCP_PROJECT="yeswanth-475406"
export GCP_REGION="us-central1"
export REGISTRY="${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT}/yeswanth"

# Authenticate Docker to GCP
gcloud auth configure-docker ${GCP_REGION}-docker.pkg.dev

# Build and push backend
docker build -t ${REGISTRY}/polling-backend:latest .
docker push ${REGISTRY}/polling-backend:latest

# Build and push frontend with correct API URL
cd frontend
docker build \
  --build-arg VITE_API_URL=http://YOUR_GCP_EXTERNAL_IP:8080/api \
  -t ${REGISTRY}/polling-frontend:latest .
docker push ${REGISTRY}/polling-frontend:latest
cd ..
```

### Step 2: Deploy to GCP VM

SSH into your GCP VM:

```bash
gcloud compute ssh pooling-instance --zone=YOUR_ZONE
```

Then run:

```bash
# Authenticate Docker on the VM
gcloud auth configure-docker us-central1-docker.pkg.dev

# Stop existing containers
docker-compose down

# Create/update docker-compose file
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: polling-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: pollingdb
      POSTGRES_USER: polling_user
      POSTGRES_PASSWORD: polling_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U polling_user -d pollingdb"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    image: us-central1-docker.pkg.dev/yeswanth-475406/yeswanth/polling-backend:latest
    container_name: polling-backend
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/pollingdb
      SPRING_DATASOURCE_USERNAME: polling_user
      SPRING_DATASOURCE_PASSWORD: polling_password
      SPRING_JPA_HIBERNATE_DDL_AUTO: update
      SPRING_JPA_SHOW_SQL: "false"
      JWT_SECRET: 5367566B59703373367639792F423F4528482B4D6251655468576D5A71347437
      JWT_EXPIRATION: 86400000
      SPRING_PROFILES_ACTIVE: prod
    depends_on:
      postgres:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s

  frontend:
    image: us-central1-docker.pkg.dev/yeswanth-475406/yeswanth/polling-frontend:latest
    container_name: polling-frontend
    restart: unless-stopped
    ports:
      - "80:80"
    depends_on:
      - backend
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s

volumes:
  postgres_data:
    driver: local
EOF

# Pull latest images
docker-compose pull

# Start services
docker-compose up -d

# Monitor logs
docker-compose logs -f
```

---

## Verify Deployment

### Check Container Status

```bash
docker-compose ps
```

All containers should show "healthy" status.

### Test Backend

```bash
# Health check
curl http://localhost:8080/actuator/health

# Test API
curl http://localhost:8080/api/polls/all
```

### Test Frontend

```bash
# Health endpoint
curl http://localhost/health

# Homepage
curl http://localhost/
```

### Test from Browser

1. Get your GCP VM external IP:
   ```bash
   gcloud compute instances describe pooling-instance --zone=YOUR_ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
   ```

2. Open in browser:
   - Frontend: `http://YOUR_EXTERNAL_IP`
   - Backend API: `http://YOUR_EXTERNAL_IP:8080/api/polls/all`

---

## Troubleshooting

### Backend "Unhealthy"

Check if curl is installed in the container:
```bash
docker exec polling-backend curl --version
```

If not, rebuild with the updated Dockerfile (which installs curl).

### Frontend "Unhealthy"

Check nginx health endpoint:
```bash
docker exec polling-frontend wget -O- http://localhost/health
```

### Frontend Can't Connect to Backend

Check browser console for CORS errors. If you see CORS errors:

1. Check frontend is using correct API URL:
   ```bash
   docker exec polling-frontend cat /usr/share/nginx/html/assets/index-*.js | grep -o 'http://[^"]*8080'
   ```

2. Verify backend CORS allows your IP:
   ```bash
   docker logs polling-backend | grep CORS
   ```

### "Failed to load polls"

This means frontend can't reach backend. Check:

1. Backend is running: `docker logs polling-backend`
2. Network connectivity: `docker exec polling-frontend curl http://polling-backend:8080/api/polls/all`
3. Frontend API URL is correct (should use external IP, not localhost)

---

## Production Considerations

### 1. Use Environment-Specific API URL

For GCP deployment, frontend should use the external IP:

```bash
# Rebuild frontend with correct API URL
docker build \
  --build-arg VITE_API_URL=http://YOUR_EXTERNAL_IP:8080/api \
  -t ${REGISTRY}/polling-frontend:latest \
  ./frontend
```

### 2. Enable HTTPS

Use Let's Encrypt with nginx-proxy:

```bash
# Install certbot
sudo apt-get install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d your-domain.com
```

### 3. Secure Database Password

Use GCP Secret Manager instead of hardcoding passwords:

```bash
# Store secret
gcloud secrets create postgres-password --data-file=-

# Access in docker-compose
POSTGRES_PASSWORD=$(gcloud secrets versions access latest --secret=postgres-password)
```

### 4. Set up Monitoring

```bash
# Install monitoring agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

# View logs
gcloud logging read "resource.type=gce_instance"
```

---

## Clean Up

To stop and remove everything:

```bash
docker-compose down -v
```

To keep database data:

```bash
docker-compose down
```

---

## Summary of Fixes Applied

1. ✅ **Backend Dockerfile**: Changed to non-Alpine, installed curl
2. ✅ **Backend Healthcheck**: Changed from `wget HEAD` to `curl GET`
3. ✅ **Frontend Healthcheck**: Changed from `/` to `/health`
4. ✅ **CORS Configuration**: Added `http://localhost` and `http://localhost:80`
5. ⚠️ **Frontend API URL**: Needs to be set to GCP external IP (not localhost)

The main issue causing "Failed to load polls" is likely #5 - the frontend is trying to reach `http://localhost:8080` from the **user's browser**, but it should be using your **GCP external IP**.
