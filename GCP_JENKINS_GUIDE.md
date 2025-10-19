# Complete Jenkins CI/CD Pipeline for GCP Deployment

## End-to-End Setup Guide for Deploying to Google Cloud Platform

This guide will walk you through setting up a complete CI/CD pipeline using Jenkins that builds your application and deploys it to GCP using Docker images.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [GCP Setup](#gcp-setup)
3. [Jenkins Installation & Configuration](#jenkins-installation--configuration)
4. [GCP Integration](#gcp-integration)
5. [Pipeline Configuration](#pipeline-configuration)
6. [Running Your First Deployment](#running-your-first-deployment)
7. [Monitoring & Troubleshooting](#monitoring--troubleshooting)

---

## Prerequisites

### Required Accounts & Tools

- [ ] GCP account with billing enabled
- [ ] GitHub/GitLab account (for source code)
- [ ] Docker Hub account (optional, can use GCR instead)
- [ ] Local machine with:
  - Java 17
  - Maven 3.6+
  - Docker Desktop
  - Git
  - gcloud CLI

### Install gcloud CLI

#### macOS:
```bash
# Install gcloud CLI
curl https://sdk.cloud.google.com | bash

# Restart terminal, then initialize
gcloud init

# Verify installation
gcloud --version
```

#### Linux:
```bash
# Download and install
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz
tar -xf google-cloud-cli-linux-x86_64.tar.gz
./google-cloud-sdk/install.sh

# Initialize
gcloud init
```

#### Windows:
Download from: https://cloud.google.com/sdk/docs/install

---

## Part 1: GCP Setup (20 minutes)

### Step 1: Create GCP Project

1. **Go to GCP Console**: https://console.cloud.google.com

2. **Create a new project**:
   - Click on project dropdown (top left)
   - Click "New Project"
   - Project name: `pollingapp-prod`
   - Note your Project ID (e.g., `pollingapp-prod-123456`)
   - Click "Create"

3. **Enable billing** for the project

### Step 2: Enable Required APIs

```bash
# Set your project
gcloud config set project pollingapp-prod-123456

# Enable required APIs
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  containerregistry.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  run.googleapis.com \
  sqladmin.googleapis.com
```

**Or via Console**:
- Go to **APIs & Services** → **Library**
- Search and enable:
  - Compute Engine API
  - Cloud Run API
  - Container Registry API
  - Artifact Registry API
  - Cloud SQL Admin API

### Step 3: Choose Your Deployment Option

GCP offers multiple deployment options. Choose the one that fits your needs:

| Option | Best For | Complexity | Cost |
|--------|----------|------------|------|
| **Cloud Run** | Serverless, auto-scaling | Low | Pay-per-use |
| **GKE** (Kubernetes) | Complex apps, full control | High | Always running |
| **Compute Engine** | VM-based deployment | Medium | Predictable |

**Recommendation for beginners**: Start with **Cloud Run** (simplest and cheapest)

---

## Part 2: GCP Resources Setup

### Option A: Cloud Run Deployment (Recommended)

#### Step 1: Create Cloud SQL Database (PostgreSQL)

```bash
# Create Cloud SQL instance
gcloud sql instances create pollingapp-db \
  --database-version=POSTGRES_14 \
  --tier=db-f1-micro \
  --region=us-central1 \
  --root-password=YOUR_STRONG_PASSWORD

# Create database
gcloud sql databases create pollingdb \
  --instance=pollingapp-db

# Create user
gcloud sql users create pollingapp_user \
  --instance=pollingapp-db \
  --password=YOUR_USER_PASSWORD
```

**Note**: Save these credentials securely!

#### Step 2: Set up Artifact Registry (for Docker images)

```bash
# Create Artifact Registry repository
gcloud artifacts repositories create pollingapp-repo \
  --repository-format=docker \
  --location=us-central1 \
  --description="Docker repository for PollingApp"

# Configure Docker to use gcloud credentials
gcloud auth configure-docker us-central1-docker.pkg.dev
```

Your Docker image URL will be:
```
us-central1-docker.pkg.dev/pollingapp-prod-123456/pollingapp-repo/pollingapp
```

### Option B: GKE Deployment (Advanced)

#### Step 1: Create GKE Cluster

```bash
# Create GKE cluster
gcloud container clusters create pollingapp-cluster \
  --zone=us-central1-a \
  --num-nodes=2 \
  --machine-type=e2-medium \
  --enable-autoscaling \
  --min-nodes=1 \
  --max-nodes=3

# Get credentials
gcloud container clusters get-credentials pollingapp-cluster \
  --zone=us-central1-a
```

### Option C: Compute Engine (VM-based)

#### Step 1: Create VM Instance

```bash
# Create VM instance
gcloud compute instances create pollingapp-vm \
  --zone=us-central1-a \
  --machine-type=e2-medium \
  --image-family=ubuntu-2004-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=20GB \
  --tags=http-server,https-server

# Create firewall rule
gcloud compute firewall-rules create allow-http \
  --allow=tcp:8080 \
  --target-tags=http-server
```

---

## Part 3: Service Account Setup (IMPORTANT!)

Jenkins needs a service account to deploy to GCP.

### Step 1: Create Service Account

```bash
# Create service account
gcloud iam service-accounts create jenkins-deployer \
  --display-name="Jenkins Deployment Service Account"

# Get your project ID
PROJECT_ID=$(gcloud config get-value project)

# Grant necessary roles
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:jenkins-deployer@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:jenkins-deployer@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:jenkins-deployer@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:jenkins-deployer@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"
```

### Step 2: Create Service Account Key

```bash
# Create and download key
gcloud iam service-accounts keys create ~/jenkins-gcp-key.json \
  --iam-account=jenkins-deployer@${PROJECT_ID}.iam.gserviceaccount.com

# View the key file location
echo "Service account key saved to: ~/jenkins-gcp-key.json"

# IMPORTANT: Keep this file secure and never commit to Git!
```

**Security Note**: This JSON key file is like a password. Keep it safe!

---

## Part 4: Jenkins Installation & Configuration (30 minutes)

### Step 1: Install Jenkins

#### Option A: Using Docker (Recommended)

```bash
# Create Jenkins container with GCP CLI
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/jenkins-gcp-key.json:/var/jenkins_home/gcp-key.json \
  jenkins/jenkins:lts-jdk17

# Install gcloud CLI in Jenkins container
docker exec -u root jenkins bash -c "
  apt-get update && \
  apt-get install -y curl gnupg && \
  echo 'deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main' | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
  apt-get update && \
  apt-get install -y google-cloud-sdk
"

# Install Docker in Jenkins container
docker exec -u root jenkins bash -c "
  apt-get update && \
  apt-get install -y docker.io && \
  usermod -aG docker jenkins
"

# Restart Jenkins
docker restart jenkins

# Get initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

#### Option B: Native Installation on macOS

```bash
# Install Jenkins
brew install jenkins-lts

# Install gcloud CLI
curl https://sdk.cloud.google.com | bash

# Copy service account key
cp ~/jenkins-gcp-key.json ~/.jenkins/gcp-key.json

# Start Jenkins
brew services start jenkins-lts

# Get initial password
cat ~/.jenkins/secrets/initialAdminPassword
```

### Step 2: Initial Jenkins Setup

1. **Open Jenkins**: Navigate to `http://localhost:8080`

2. **Unlock Jenkins**: Paste the initial admin password

3. **Install Suggested Plugins**: Click "Install suggested plugins"

4. **Create Admin User**: Fill in your details and click "Save and Continue"

### Step 3: Install GCP Plugins

**Manage Jenkins** → **Manage Plugins** → **Available**

Search and install:
- [ ] **Google Kubernetes Engine Plugin**
- [ ] **Google Cloud Container Builder Plugin**
- [ ] **Docker Pipeline Plugin**
- [ ] **Maven Integration Plugin**
- [ ] **Pipeline Plugin**
- [ ] **Git Plugin**
- [ ] **NodeJS Plugin**

Click "Install without restart"

### Step 4: Configure Jenkins Tools

#### Configure JDK
**Manage Jenkins** → **Global Tool Configuration** → **JDK**

- Click "Add JDK"
- Name: `Java-17`
- Check "Install automatically"
- Version: Select Java 17
- Save

#### Configure Maven
**Manage Jenkins** → **Global Tool Configuration** → **Maven**

- Click "Add Maven"
- Name: `Maven-3.9`
- Check "Install automatically"
- Version: Select 3.9.x
- Save

#### Configure NodeJS
**Manage Jenkins** → **Global Tool Configuration** → **NodeJS**

- Click "Add NodeJS"
- Name: `NodeJS-18`
- Check "Install automatically"
- Version: Select 18.x
- Save

---

## Part 5: Configure GCP Credentials in Jenkins

### Step 1: Add GCP Service Account Credentials

**Manage Jenkins** → **Manage Credentials** → **Global** → **Add Credentials**

#### GCP Service Account JSON Key

- **Kind**: Secret file
- **File**: Upload `jenkins-gcp-key.json`
- **ID**: `gcp-service-account`
- **Description**: GCP Service Account for Deployment
- Click **Create**

#### Alternative: Secret Text Method

- **Kind**: Secret text
- **Secret**: Paste the entire content of `jenkins-gcp-key.json`
- **ID**: `gcp-service-account-json`
- **Description**: GCP Service Account JSON
- Click **Create**

### Step 2: Add Database Credentials

#### Database Password
- **Kind**: Secret text
- **ID**: `gcp-db-password`
- **Secret**: Your Cloud SQL database password
- Click **Create**

#### JWT Secret
- **Kind**: Secret text
- **ID**: `jwt-secret`
- **Secret**: Your JWT secret key
- Click **Create**

### Step 3: Add GCP Project Configuration

**Manage Jenkins** → **Configure System** → **Global Properties**

Check "Environment variables" and add:

| Name | Value |
|------|-------|
| `GCP_PROJECT_ID` | `pollingapp-prod-123456` |
| `GCP_REGION` | `us-central1` |
| `GCP_ZONE` | `us-central1-a` |
| `ARTIFACT_REGISTRY` | `us-central1-docker.pkg.dev/pollingapp-prod-123456/pollingapp-repo` |
| `CLOUD_SQL_INSTANCE` | `pollingapp-prod-123456:us-central1:pollingapp-db` |

Click **Save**

---

## Part 6: Create Jenkins Pipeline

### Step 1: Create New Pipeline Job

1. **Jenkins Dashboard** → **New Item**
2. Name: `PollingApp-GCP-Pipeline`
3. Type: **Pipeline**
4. Click **OK**

### Step 2: Configure Pipeline

#### General Settings
- **Description**: "CI/CD Pipeline for PollingApp - GCP Deployment"
- Check **GitHub project** (optional)
- Project URL: Your GitHub repository URL

#### Build Triggers
Select:
- [ ] **Poll SCM**: `H/5 * * * *` (checks every 5 minutes)
- [ ] **GitHub hook trigger for GITScm polling** (for webhooks)

#### Pipeline Definition
- **Definition**: Pipeline script from SCM
- **SCM**: Git
- **Repository URL**: Your Git repository URL
- **Credentials**: Add Git credentials if private repository
  - Click "Add" → Jenkins
  - Kind: Username with password
  - Username: Your GitHub username
  - Password: Your GitHub Personal Access Token
  - ID: `github-credentials`
  - Click **Add**
- **Branches to build**: `*/main`
- **Script Path**: `Jenkinsfile.gcp`

Click **Save**

---

## Part 7: Configure Your Application for GCP

### Step 1: Update application-prod.properties

Edit `src/main/resources/application-prod.properties`:

```properties
# Server Configuration
server.port=${PORT:8080}

# Database Configuration (Cloud SQL)
spring.datasource.url=jdbc:postgresql:///${DATABASE_NAME}?cloudSqlInstance=${CLOUD_SQL_INSTANCE_CONNECTION_NAME}&socketFactory=com.google.cloud.sql.postgres.SocketFactory
spring.datasource.username=${DATABASE_USER}
spring.datasource.password=${DATABASE_PASSWORD}
spring.datasource.driver-class-name=org.postgresql.Driver

# JPA Configuration
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect
spring.jpa.properties.hibernate.format_sql=true

# JWT Configuration
jwt.secret=${JWT_SECRET}
jwt.expirationMs=86400000

# Logging
logging.level.com.polling=INFO
logging.level.org.springframework.web=INFO
logging.level.org.hibernate=WARN

# Actuator for health checks
management.endpoints.web.exposure.include=health,info
management.endpoint.health.show-details=always
```

### Step 2: Update pom.xml (Add Cloud SQL Dependency)

Add this dependency to your `pom.xml`:

```xml
<!-- Add inside <dependencies> section -->
<dependency>
    <groupId>com.google.cloud.sql</groupId>
    <artifactId>postgres-socket-factory</artifactId>
    <version>1.13.1</version>
</dependency>
```

---

## Part 8: Deployment Configuration

### Get Your Database Connection Details

```bash
# Get Cloud SQL connection name
gcloud sql instances describe pollingapp-db --format="value(connectionName)"

# Example output: pollingapp-prod-123456:us-central1:pollingapp-db
```

Save this connection name - you'll need it!

### Environment Variables for Cloud Run

Your Cloud Run service will need these environment variables:

| Variable | Value | Source |
|----------|-------|--------|
| `SPRING_PROFILES_ACTIVE` | `prod` | Hardcoded |
| `DATABASE_NAME` | `pollingdb` | Hardcoded |
| `DATABASE_USER` | `pollingapp_user` | Hardcoded |
| `DATABASE_PASSWORD` | `***` | Secret |
| `CLOUD_SQL_INSTANCE_CONNECTION_NAME` | `project:region:instance` | From above |
| `JWT_SECRET` | `***` | Secret |

---

## Part 9: Running Your First Deployment

### Step 1: Push Code to Git

```bash
cd /Users/yeswanthvajja/PollingApp

# Add all files
git add .

# Commit
git commit -m "Add GCP deployment configuration"

# Push to repository
git push origin main
```

### Step 2: Trigger Jenkins Build

1. **Go to Jenkins Dashboard**
2. **Click on** `PollingApp-GCP-Pipeline`
3. **Click** "Build Now"
4. **Watch the build progress**:
   - Click on build number (e.g., #1)
   - Click "Console Output"
   - Watch real-time logs

### Step 3: Monitor Deployment

#### Check Cloud Run Deployment

```bash
# List Cloud Run services
gcloud run services list --region=us-central1

# Get service URL
gcloud run services describe pollingapp \
  --region=us-central1 \
  --format="value(status.url)"

# View logs
gcloud logging read "resource.type=cloud_run_revision" --limit 50
```

#### Test Your Application

```bash
# Get the service URL
SERVICE_URL=$(gcloud run services describe pollingapp \
  --region=us-central1 \
  --format="value(status.url)")

# Test health endpoint
curl $SERVICE_URL/actuator/health

# Expected output:
# {"status":"UP"}
```

---

## Part 10: Complete Pipeline Workflow

Here's what happens when you push code:

```
1. CODE PUSH (GitHub)
   ↓
2. WEBHOOK TRIGGER (GitHub → Jenkins)
   ↓
3. JENKINS PIPELINE STARTS
   ├─ Checkout code
   ├─ Build backend (Maven)
   ├─ Run tests
   ├─ Build frontend (npm)
   ├─ Build Docker image
   ├─ Push to Artifact Registry
   ├─ Deploy to Cloud Run
   └─ Health check
   ↓
4. APPLICATION LIVE ON GCP
```

---

## Part 11: Automatic Builds (GitHub Webhook)

### Step 1: Get Jenkins Webhook URL

Your webhook URL format:
```
http://YOUR_JENKINS_URL:8080/github-webhook/
```

**Important**: If Jenkins is on localhost, GitHub can't reach it. Options:
1. Use ngrok for testing
2. Deploy Jenkins to a public server
3. Use GitHub Actions instead

### Step 2: Set Up ngrok (for local Jenkins)

```bash
# Install ngrok
brew install ngrok

# Start ngrok
ngrok http 8080

# Copy the HTTPS URL (e.g., https://abc123.ngrok.io)
```

### Step 3: Configure GitHub Webhook

1. **Go to your GitHub repository**
2. **Settings** → **Webhooks** → **Add webhook**
3. **Payload URL**: `https://abc123.ngrok.io/github-webhook/`
4. **Content type**: `application/json`
5. **Which events**: "Just the push event"
6. **Active**: Checked
7. Click **Add webhook**

---

## Part 12: Monitoring & Troubleshooting

### View Cloud Run Logs

```bash
# Real-time logs
gcloud logging tail "resource.type=cloud_run_revision AND resource.labels.service_name=pollingapp"

# Recent errors
gcloud logging read "resource.type=cloud_run_revision AND severity>=ERROR" --limit 50
```

### View Jenkins Logs

```bash
# Docker installation
docker logs -f jenkins

# View specific build logs
# Go to Jenkins UI → Build number → Console Output
```

### Common Issues

#### Issue 1: Authentication Failed to Artifact Registry

**Solution**:
```bash
# Authenticate Docker
gcloud auth configure-docker us-central1-docker.pkg.dev

# In Jenkins container
docker exec jenkins gcloud auth activate-service-account \
  --key-file=/var/jenkins_home/gcp-key.json
```

#### Issue 2: Cloud SQL Connection Failed

**Solution**: Make sure Cloud SQL API is enabled and service account has `cloudsql.client` role

```bash
# Enable API
gcloud services enable sqladmin.googleapis.com

# Grant role
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:jenkins-deployer@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"
```

#### Issue 3: Cloud Run Deployment Permission Denied

**Solution**:
```bash
# Grant Cloud Run admin role
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:jenkins-deployer@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/run.admin"
```

#### Issue 4: Build Fails - Maven/Node not found

**Solution**: Check Global Tool Configuration in Jenkins
- Manage Jenkins → Global Tool Configuration
- Verify Java, Maven, and NodeJS are configured

---

## Part 13: Cost Optimization

### Cloud Run Pricing Tips

1. **Set max instances**: Prevent runaway costs
2. **Set min instances to 0**: Pay only when used
3. **Use appropriate CPU allocation**: Default is fine for most apps
4. **Monitor usage**: Check GCP Billing regularly

```bash
# Set max instances
gcloud run services update pollingapp \
  --region=us-central1 \
  --max-instances=5 \
  --min-instances=0
```

### Estimated Monthly Costs

| Service | Usage | Cost |
|---------|-------|------|
| Cloud Run | 1M requests/month | ~$0-5 |
| Cloud SQL (f1-micro) | Always on | ~$7-10 |
| Artifact Registry | 1 GB storage | ~$0.10 |
| **Total** | | **~$10-15/month** |

---

## Part 14: Production Best Practices

### 1. Use Secret Manager (Recommended)

Instead of environment variables, use GCP Secret Manager:

```bash
# Create secrets
echo -n "your-jwt-secret" | gcloud secrets create jwt-secret --data-file=-
echo -n "your-db-password" | gcloud secrets create db-password --data-file=-

# Grant access to Cloud Run
gcloud secrets add-iam-policy-binding jwt-secret \
  --member="serviceAccount:${PROJECT_ID}@appspot.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### 2. Enable Cloud CDN

For better performance, use Cloud CDN for static assets.

### 3. Set Up Monitoring

```bash
# Enable monitoring
gcloud services enable monitoring.googleapis.com

# Create uptime check
gcloud monitoring uptime create pollingapp-health \
  --resource-type=uptime-url \
  --resource-labels=host=YOUR_CLOUD_RUN_URL
```

### 4. Implement Blue-Green Deployment

Deploy new version with 0% traffic, then gradually shift traffic.

### 5. Set Up Alerts

Create alerts for:
- High error rate
- High latency
- High costs
- Low availability

---

## Part 15: Next Steps

### Immediate Actions

- [ ] Set up Cloud Run deployment
- [ ] Configure Cloud SQL database
- [ ] Create service account
- [ ] Install and configure Jenkins
- [ ] Run first successful deployment
- [ ] Set up GitHub webhooks

### Advanced Features

- [ ] Add staging environment
- [ ] Implement blue-green deployments
- [ ] Set up Cloud Armor (DDoS protection)
- [ ] Configure Cloud CDN
- [ ] Add monitoring and alerting
- [ ] Implement automated rollbacks
- [ ] Set up Cloud Build triggers

---

## Resources & Links

- **GCP Console**: https://console.cloud.google.com
- **Cloud Run Docs**: https://cloud.google.com/run/docs
- **Cloud SQL Docs**: https://cloud.google.com/sql/docs
- **Jenkins Docs**: https://www.jenkins.io/doc/
- **Your Project Files**:
  - [Jenkinsfile.gcp](Jenkinsfile.gcp) - Pipeline definition
  - [gcp-deploy.sh](gcp-deploy.sh) - Deployment script
  - [cloudbuild.yaml](cloudbuild.yaml) - Cloud Build config

---

## Summary

You now have:

✅ Complete GCP infrastructure (Cloud Run + Cloud SQL)
✅ Jenkins CI/CD pipeline
✅ Automated Docker builds
✅ Automated GCP deployments
✅ Database integration
✅ Health monitoring
✅ Cost-effective setup (~$10-15/month)

**Time to complete**: ~2-3 hours
**Difficulty**: Intermediate
**Cost**: ~$10-15/month

Happy Deploying! 🚀
