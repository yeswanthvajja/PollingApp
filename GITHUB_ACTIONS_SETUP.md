# GitHub Actions CI/CD Setup Guide

This guide will help you set up the complete CI/CD pipeline using GitHub Actions to automatically deploy your Polling App to GCP.

## 🎯 Overview

**What happens when you push code to main branch:**
1. GitHub Actions triggers automatically
2. Runs tests for backend (Maven) and frontend (npm)
3. Builds Docker images for both services
4. Pushes images to GCP Artifact Registry
5. SSHs into your GCP VM
6. Pulls new images and restarts containers
7. Runs health checks to verify deployment

**For pull requests:** Only builds and tests - no deployment.

---

## 📋 Prerequisites

Before starting, ensure you have:
- [ ] GitHub repository with your code
- [ ] GCP project with Artifact Registry enabled
- [ ] GCP VM running and accessible
- [ ] Docker and Docker Compose installed on VM
- [ ] `gcloud` CLI installed on VM

---

## 🔧 Step-by-Step Setup

### Step 1: Create GCP Service Account

The service account will allow GitHub Actions to interact with GCP services.

```bash
# Set your project ID
PROJECT_ID="yeswanth-475406"

# Create a service account for GitHub Actions
gcloud iam service-accounts create github-actions-sa \
    --display-name="GitHub Actions Service Account" \
    --project=$PROJECT_ID

# Grant necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/compute.instanceAdmin.v1"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

# Create and download service account key
gcloud iam service-accounts keys create ~/github-actions-key.json \
    --iam-account=github-actions-sa@${PROJECT_ID}.iam.gserviceaccount.com

# Display the key content (you'll need this for GitHub Secrets)
cat ~/github-actions-key.json
```

**Important:** Copy the entire JSON content. You'll add this to GitHub Secrets.

---

### Step 2: Configure GitHub Secrets

Add the following secrets to your GitHub repository:

**Go to:** `GitHub Repository → Settings → Secrets and variables → Actions → New repository secret`

| Secret Name | Description | Example Value |
|------------|-------------|---------------|
| `GCP_SA_KEY` | Service account JSON key | Paste the entire JSON from Step 1 |
| `GCP_VM_NAME` | Your VM instance name | `polling-app-vm` |
| `GCP_VM_ZONE` | VM zone | `us-central1-a` |
| `VITE_API_URL` | Frontend API URL | `http://35.193.17.6:8080/api` |

**How to add secrets:**

1. **GCP_SA_KEY:**
   ```
   Name: GCP_SA_KEY
   Value: (Paste the entire JSON from ~/github-actions-key.json)
   ```

2. **GCP_VM_NAME:**
   ```bash
   # Find your VM name
   gcloud compute instances list

   # Add to GitHub Secret:
   Name: GCP_VM_NAME
   Value: your-vm-name
   ```

3. **GCP_VM_ZONE:**
   ```
   Name: GCP_VM_ZONE
   Value: us-central1-a (or your VM's zone)
   ```

4. **VITE_API_URL:**
   ```bash
   # Get your VM's external IP
   gcloud compute instances describe YOUR_VM_NAME \
       --zone=YOUR_ZONE \
       --format='get(networkInterfaces[0].accessConfigs[0].natIP)'

   # Add to GitHub Secret:
   Name: VITE_API_URL
   Value: http://YOUR_VM_EXTERNAL_IP:8080/api
   ```

---

### Step 3: Prepare Your GCP VM

SSH into your VM and set up the project directory:

```bash
# SSH into your VM
gcloud compute ssh YOUR_VM_NAME --zone=YOUR_ZONE

# Create project directory
mkdir -p ~/polling-app
cd ~/polling-app

# Authenticate gcloud (if not already done)
gcloud auth login

# Configure Docker for Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev

# Test Docker authentication
docker pull us-central1-docker.pkg.dev/yeswanth-475406/yeswanth/polling-backend:latest

# Verify Docker Compose is installed
docker-compose --version

# If not installed, install it:
sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

---

### Step 4: Update VM Firewall Rules (if needed)

Ensure your VM can accept HTTP/HTTPS traffic:

```bash
# Allow HTTP traffic (port 80)
gcloud compute firewall-rules create allow-http \
    --allow tcp:80 \
    --source-ranges 0.0.0.0/0 \
    --description="Allow HTTP traffic"

# Allow HTTPS traffic (port 443) - for future SSL
gcloud compute firewall-rules create allow-https \
    --allow tcp:443 \
    --source-ranges 0.0.0.0/0 \
    --description="Allow HTTPS traffic"

# Allow backend API (port 8080)
gcloud compute firewall-rules create allow-backend \
    --allow tcp:8080 \
    --source-ranges 0.0.0.0/0 \
    --description="Allow backend API traffic"
```

---

### Step 5: Test the Pipeline

Now test your CI/CD pipeline:

```bash
# Make a small change to trigger the pipeline
echo "# CI/CD Test" >> README.md

# Commit and push
git add .
git commit -m "test: trigger CI/CD pipeline"
git push origin main
```

**Monitor the pipeline:**
1. Go to your GitHub repository
2. Click on "Actions" tab
3. Watch the workflow run in real-time
4. Check each job: Build Backend → Build Frontend → Build & Push → Deploy

---

### Step 6: Verify Deployment

After the pipeline completes:

```bash
# SSH into your VM
gcloud compute ssh YOUR_VM_NAME --zone=YOUR_ZONE

# Check running containers
cd ~/polling-app
docker-compose ps

# Check logs
docker-compose logs -f backend
docker-compose logs -f frontend

# Test endpoints
curl http://localhost:8080/actuator/health
curl http://localhost/health
```

**Access your application:**
- Frontend: `http://YOUR_VM_EXTERNAL_IP`
- Backend: `http://YOUR_VM_EXTERNAL_IP:8080/api`

---

## 🔍 Pipeline Breakdown

### Job 1: Build Backend
- Checks out code
- Sets up JDK 17
- Runs Maven tests
- Builds JAR file
- Uploads artifact for next jobs

### Job 2: Build Frontend
- Checks out code
- Sets up Node.js 20
- Installs dependencies
- Runs tests (if available)
- Builds production bundle

### Job 3: Build & Push Docker Images
- Authenticates with GCP
- Builds Docker images for backend and frontend
- Tags images with commit SHA and 'latest'
- Pushes to Artifact Registry
- Uses Docker layer caching for faster builds

### Job 4: Deploy to GCP VM
- Copies docker-compose.yml to VM
- Pulls latest images
- Stops old containers
- Starts new containers
- Runs health checks
- Cleans up old images

### Job 5: Notification
- Shows deployment status
- Can be extended to send Slack/email notifications

---

## 🎛️ Customization Options

### Add manual approval for production

To require manual approval before deployment:

1. Go to GitHub Repository → **Settings** → **Environments**
2. Create environment named "production"
3. Add required reviewers
4. Update [.github/workflows/deploy.yml](.github/workflows/deploy.yml):

```yaml
deploy:
  needs: build-and-push
  environment:
    name: production
    url: http://YOUR_VM_IP
```

### Trigger deployment manually

You can trigger deployment manually from GitHub:
1. Go to **Actions** tab
2. Select **CI/CD Pipeline**
3. Click **Run workflow**
4. Select branch and click **Run workflow**

---

## 🐛 Troubleshooting

### Issue: Authentication failed to Artifact Registry

**Solution:**
```bash
# On your VM, re-authenticate
gcloud auth login
gcloud auth configure-docker us-central1-docker.pkg.dev
```

### Issue: SSH connection timeout

**Solution:**
```bash
# Ensure OS Login is configured
gcloud compute instances add-metadata YOUR_VM_NAME \
    --metadata enable-oslogin=TRUE \
    --zone=YOUR_ZONE

# Grant SSH access to service account
gcloud compute instances add-iam-policy-binding YOUR_VM_NAME \
    --member=serviceAccount:github-actions-sa@YOUR_PROJECT.iam.gserviceaccount.com \
    --role=roles/compute.osLogin \
    --zone=YOUR_ZONE
```

### Issue: Docker build fails

**Solution:**
- Check if Dockerfile syntax is correct
- Ensure all dependencies are available
- Check GitHub Actions logs for specific errors

### Issue: Health checks fail after deployment

**Solution:**
```bash
# SSH into VM and check logs
docker-compose logs backend
docker-compose logs frontend

# Check if containers are running
docker-compose ps

# Restart if needed
docker-compose restart
```

---

## 📊 Monitoring Deployments

### View recent deployments

```bash
# On your VM
docker-compose ps
docker-compose logs --tail=100 backend
docker-compose logs --tail=100 frontend
```

### Check GitHub Actions history

Go to: `GitHub Repository → Actions → All workflows`

---

## 🔐 Security Best Practices

1. **Rotate Service Account Keys Regularly**
   ```bash
   # Delete old key
   gcloud iam service-accounts keys delete KEY_ID \
       --iam-account=github-actions-sa@PROJECT_ID.iam.gserviceaccount.com

   # Create new key
   gcloud iam service-accounts keys create new-key.json \
       --iam-account=github-actions-sa@PROJECT_ID.iam.gserviceaccount.com
   ```

2. **Use Secret Scanning**
   - Enable GitHub secret scanning
   - Never commit secrets to repository

3. **Limit Service Account Permissions**
   - Only grant minimum required roles
   - Regularly audit IAM permissions

4. **Use Environment Protection Rules**
   - Add required reviewers for production
   - Set deployment branches

---

## 🚀 Next Steps

### 1. Add SSL/HTTPS
- Use Let's Encrypt with Nginx
- Update frontend Dockerfile to include SSL config

### 2. Add Database Backups
```yaml
- name: Backup Database
  run: |
    gcloud compute ssh $VM_NAME --command="
      docker-compose exec -T postgres pg_dump -U polling_user pollingdb > backup.sql
    "
```

### 3. Add Performance Monitoring
- Integrate Google Cloud Monitoring
- Add application performance monitoring (APM)

### 4. Add Slack Notifications
```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### 5. Add Multiple Environments
- Create separate VMs for staging and production
- Use GitHub environments for deployment control

---

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GCP Artifact Registry](https://cloud.google.com/artifact-registry/docs)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [GCP IAM Best Practices](https://cloud.google.com/iam/docs/best-practices)

---

## ✅ Checklist

Before going live, ensure:

- [ ] Service account created with correct permissions
- [ ] All GitHub secrets configured
- [ ] VM prepared with Docker and gcloud CLI
- [ ] Firewall rules configured
- [ ] Test deployment successful
- [ ] Health checks passing
- [ ] Logs accessible and monitored
- [ ] Backup strategy in place
- [ ] SSL certificate configured (for production)
- [ ] Monitoring and alerting set up

---

## 💬 Support

If you encounter issues:

1. Check GitHub Actions logs for detailed error messages
2. SSH into VM and check Docker logs
3. Verify all secrets are correctly configured
4. Ensure VM has internet access and can pull from Artifact Registry

---

**Happy Deploying! 🎉**
