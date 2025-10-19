# GCP Jenkins CI/CD - Quick Start Guide

**Get your application deployed to Google Cloud Platform in 60 minutes!**

This is a step-by-step beginner-friendly guide. Follow each step carefully.

---

## 📋 What You'll Build

```
GitHub Repository → Jenkins Pipeline → Docker Image → GCP Cloud Run
                                                      ↓
                                               GCP Cloud SQL
```

**Result**: Fully automated deployment to GCP every time you push code!

---

## Part 1: GCP Setup (20 minutes)

### Step 1: Create GCP Project

1. Go to https://console.cloud.google.com
2. Click the project dropdown (top left)
3. Click "New Project"
4. Enter project name: `pollingapp-prod`
5. Click "Create"
6. **Write down your Project ID** (e.g., `pollingapp-prod-123456`)

### Step 2: Install gcloud CLI

**macOS:**
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL  # Restart shell
gcloud init
```

**Windows:** Download from https://cloud.google.com/sdk/docs/install

**Linux:**
```bash
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz
tar -xf google-cloud-cli-linux-x86_64.tar.gz
./google-cloud-sdk/install.sh
exec -l $SHELL
gcloud init
```

Follow the prompts:
- Login with your Google account
- Select your project (`pollingapp-prod`)
- Choose default region: `us-central1`

### Step 3: Enable Required APIs

```bash
# Set your project (replace with your Project ID)
export GCP_PROJECT_ID="pollingapp-prod-123456"
gcloud config set project $GCP_PROJECT_ID

# Enable APIs (takes ~2 minutes)
gcloud services enable \
  run.googleapis.com \
  sqladmin.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com
```

### Step 4: Create Cloud SQL Database

```bash
# Create PostgreSQL instance (~5 minutes)
gcloud sql instances create pollingapp-db \
  --database-version=POSTGRES_14 \
  --tier=db-f1-micro \
  --region=us-central1 \
  --root-password=YourStrongPassword123!

# Create database
gcloud sql databases create pollingdb \
  --instance=pollingapp-db

# Create user
gcloud sql users create pollingapp_user \
  --instance=pollingapp-db \
  --password=YourUserPassword123!
```

**⚠️ IMPORTANT**: Write down these credentials:
- Database password: `YourStrongPassword123!`
- User password: `YourUserPassword123!`

### Step 5: Create Artifact Registry

```bash
# Create Docker repository
gcloud artifacts repositories create pollingapp-repo \
  --repository-format=docker \
  --location=us-central1 \
  --description="Docker repository for PollingApp"

# Configure Docker authentication
gcloud auth configure-docker us-central1-docker.pkg.dev
```

### Step 6: Create Service Account (for Jenkins)

```bash
# Create service account
gcloud iam service-accounts create jenkins-deployer \
  --display-name="Jenkins Deployment Service Account"

# Grant permissions
gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:jenkins-deployer@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:jenkins-deployer@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:jenkins-deployer@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"

gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
  --member="serviceAccount:jenkins-deployer@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

# Create and download key
gcloud iam service-accounts keys create ~/jenkins-gcp-key.json \
  --iam-account=jenkins-deployer@${GCP_PROJECT_ID}.iam.gserviceaccount.com

echo "✓ Service account key saved to: ~/jenkins-gcp-key.json"
echo "⚠️  Keep this file secure! Never commit to Git!"
```

### Step 7: Get Cloud SQL Connection Name

```bash
# Get connection name (you'll need this later)
CLOUD_SQL_INSTANCE=$(gcloud sql instances describe pollingapp-db \
  --format="value(connectionName)")

echo "Your Cloud SQL connection name:"
echo $CLOUD_SQL_INSTANCE
echo ""
echo "⚠️  Write this down! Format: project:region:instance"
```

---

## Part 2: Jenkins Setup (20 minutes)

### Step 1: Install Jenkins with Docker

```bash
# Run Jenkins container
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/jenkins-gcp-key.json:/var/jenkins_home/gcp-key.json \
  jenkins/jenkins:lts-jdk17

# Install gcloud CLI in Jenkins
docker exec -u root jenkins bash -c "
  apt-get update && \
  apt-get install -y curl gnupg && \
  echo 'deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main' | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
  apt-get update && \
  apt-get install -y google-cloud-sdk docker.io && \
  usermod -aG docker jenkins
"

# Restart Jenkins
docker restart jenkins

# Wait 30 seconds for Jenkins to restart
echo "Waiting for Jenkins to restart..."
sleep 30

# Get admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

**Copy the password!**

### Step 2: Initial Jenkins Configuration

1. **Open Jenkins**: http://localhost:8080
2. **Paste the admin password**
3. **Click**: "Install suggested plugins" (wait ~5 minutes)
4. **Create admin user**:
   - Username: `admin`
   - Password: (choose a password)
   - Full name: Your name
   - Email: your-email@example.com
5. **Click**: "Save and Continue"
6. **Jenkins URL**: Keep default, click "Save and Finish"

### Step 3: Install Additional Plugins

**Manage Jenkins** → **Manage Plugins** → **Available Plugins**

Search and check:
- ✅ Docker Pipeline
- ✅ Maven Integration
- ✅ NodeJS Plugin
- ✅ Pipeline

Click "Install without restart"

### Step 4: Configure Tools

#### Java
**Manage Jenkins** → **Global Tool Configuration** → **JDK Installations**
- Click "Add JDK"
- Name: `Java-17`
- Check "Install automatically"
- Version: Select `jdk-17.0.x`
- Save

#### Maven
**Manage Jenkins** → **Global Tool Configuration** → **Maven Installations**
- Click "Add Maven"
- Name: `Maven-3.9`
- Check "Install automatically"
- Version: Select `3.9.x`
- Save

#### NodeJS
**Manage Jenkins** → **Global Tool Configuration** → **NodeJS Installations**
- Click "Add NodeJS"
- Name: `NodeJS-18`
- Check "Install automatically"
- Version: Select `18.x`
- Save

Click **Apply** and **Save**

### Step 5: Add GCP Credentials

**Manage Jenkins** → **Manage Credentials** → **System** → **Global credentials** → **Add Credentials**

#### 1. GCP Service Account
- Kind: **Secret file**
- File: Click "Choose File" → Upload `~/jenkins-gcp-key.json`
- ID: `gcp-service-account`
- Description: `GCP Service Account`
- Click **Create**

#### 2. GCP Project ID
- Kind: **Secret text**
- Secret: Your project ID (e.g., `pollingapp-prod-123456`)
- ID: `gcp-project-id`
- Description: `GCP Project ID`
- Click **Create**

#### 3. Cloud SQL Instance Name
- Kind: **Secret text**
- Secret: Your Cloud SQL connection name (e.g., `pollingapp-prod-123456:us-central1:pollingapp-db`)
- ID: `cloud-sql-instance-name`
- Description: `Cloud SQL Instance Connection Name`
- Click **Create**

#### 4. Database Password
- Kind: **Secret text**
- Secret: `YourUserPassword123!` (the password you set earlier)
- ID: `gcp-db-password`
- Description: `Database Password`
- Click **Create**

#### 5. JWT Secret
- Kind: **Secret text**
- Secret: Generate a random string (at least 32 characters)
  ```bash
  openssl rand -base64 32
  ```
- ID: `jwt-secret`
- Description: `JWT Secret Key`
- Click **Create**

---

## Part 3: Prepare Your Code (10 minutes)

### Step 1: Update Your Code

All the necessary files have been created for you:
- ✅ `Jenkinsfile.gcp` - Jenkins pipeline
- ✅ `gcp-deploy.sh` - Deployment script
- ✅ `application-gcp.properties` - GCP configuration
- ✅ `pom.xml` - Updated with Cloud SQL dependency

### Step 2: Create Git Repository

```bash
cd /Users/yeswanthvajja/PollingApp

# Initialize git (if not already done)
git init

# Add all files
git add .

# Commit
git commit -m "Add GCP CI/CD pipeline configuration"

# Create GitHub repository (via web or CLI)
# Then add remote
git remote add origin https://github.com/YOUR_USERNAME/PollingApp.git

# Push to GitHub
git push -u origin main
```

---

## Part 4: Create Jenkins Pipeline (10 minutes)

### Step 1: Create Pipeline Job

1. **Jenkins Dashboard** → **New Item**
2. **Item name**: `PollingApp-GCP`
3. **Type**: Select **Pipeline**
4. **Click**: "OK"

### Step 2: Configure Pipeline

**General Section:**
- Description: `CI/CD Pipeline for PollingApp - GCP Deployment`
- ✅ Check "GitHub project" (optional)
- Project URL: `https://github.com/YOUR_USERNAME/PollingApp`

**Build Triggers:**
- ✅ Poll SCM
- Schedule: `H/5 * * * *`

**Pipeline Section:**
- Definition: **Pipeline script from SCM**
- SCM: **Git**
- Repository URL: `https://github.com/YOUR_USERNAME/PollingApp.git`
- Credentials: Add your GitHub credentials
  - Click "Add" → Jenkins
  - Kind: Username with password
  - Username: Your GitHub username
  - Password: Your GitHub Personal Access Token
  - ID: `github-credentials`
  - Click "Add"
  - Select the credential from dropdown
- Branch Specifier: `*/main`
- Script Path: `Jenkinsfile.gcp`

**Click Save**

---

## Part 5: Run Your First Build! (5-10 minutes)

### Step 1: Start Build

1. **Go to**: `PollingApp-GCP` job
2. **Click**: "Build Now"
3. **Click** on build #1
4. **Click**: "Console Output"

### Step 2: Watch the Magic! ✨

You'll see these stages execute:
```
✓ Checkout
✓ Setup GCP Authentication
✓ Build Backend
✓ Run Unit Tests
✓ Package Application
✓ Build Frontend
✓ Build Docker Image
✓ Push to Artifact Registry
✓ Deploy to Cloud Run - Production
✓ Health Check - Production
✓ Tag Release
✓ Cleanup
```

**First build takes ~10-15 minutes** (downloads dependencies)

### Step 3: Get Your App URL

Once the build succeeds, find this in the console output:
```
Service URL: https://pollingapp-xxxxx-uc.a.run.app
```

**Copy this URL!**

### Step 4: Test Your App

```bash
# Replace with your actual URL
SERVICE_URL="https://pollingapp-xxxxx-uc.a.run.app"

# Test health endpoint
curl $SERVICE_URL/actuator/health

# Expected: {"status":"UP"}
```

🎉 **Congratulations! Your app is live on GCP!**

---

## Part 6: Set Up Automatic Builds (Optional)

### For Local Jenkins (using ngrok)

```bash
# Install ngrok
brew install ngrok  # macOS
# or download from https://ngrok.com/download

# Start ngrok
ngrok http 8080

# Copy the HTTPS URL (e.g., https://abc123.ngrok.io)
```

### GitHub Webhook

1. **Go to your GitHub repository**
2. **Settings** → **Webhooks** → **Add webhook**
3. **Payload URL**: `https://abc123.ngrok.io/github-webhook/`
4. **Content type**: `application/json`
5. **Events**: "Just the push event"
6. **Active**: ✅ Checked
7. **Add webhook**

Now every git push triggers a build automatically!

---

## Testing Your CI/CD Pipeline

### Test 1: Make a Simple Change

```bash
# Edit a file
echo "// Test change" >> src/main/java/com/polling/PollingApplication.java

# Commit and push
git add .
git commit -m "Test CI/CD pipeline"
git push

# Watch Jenkins automatically start a build!
```

### Test 2: Check Cloud Run

```bash
# List all Cloud Run services
gcloud run services list --region=us-central1

# Get service details
gcloud run services describe pollingapp --region=us-central1

# View logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=pollingapp" --limit=50
```

---

## Troubleshooting

### Build Failed: "gcloud: command not found"

**Solution**: gcloud not installed in Jenkins container
```bash
# Re-run the gcloud installation command from Step 1
docker exec -u root jenkins bash -c "apt-get update && apt-get install -y google-cloud-sdk"
docker restart jenkins
```

### Build Failed: "Permission denied" (Docker)

**Solution**: Jenkins user not in docker group
```bash
docker exec -u root jenkins usermod -aG docker jenkins
docker restart jenkins
```

### Deployment Failed: "Cloud SQL connection refused"

**Solution**: Check Cloud SQL instance is running
```bash
gcloud sql instances describe pollingapp-db
# Status should be "RUNNABLE"

# If not running, start it:
gcloud sql instances patch pollingapp-db --activation-policy=ALWAYS
```

### Health Check Failed

**Solution**: Check application logs
```bash
gcloud logging tail "resource.type=cloud_run_revision AND resource.labels.service_name=pollingapp"
```

---

## What You've Accomplished! 🎉

✅ Set up complete GCP infrastructure
✅ Created Cloud SQL PostgreSQL database
✅ Set up Artifact Registry for Docker images
✅ Installed and configured Jenkins
✅ Created automated CI/CD pipeline
✅ Deployed application to Cloud Run
✅ Application is live and accessible!

## Pipeline Flow

```
1. Push code to GitHub
         ↓
2. Jenkins detects change
         ↓
3. Run tests
         ↓
4. Build application (Maven + npm)
         ↓
5. Create Docker image
         ↓
6. Push to Artifact Registry
         ↓
7. Deploy to Cloud Run
         ↓
8. Health check
         ↓
9. ✅ Live on GCP!
```

## Useful Commands

```bash
# View all Cloud Run services
gcloud run services list

# Get app URL
gcloud run services describe pollingapp \
  --region=us-central1 \
  --format='value(status.url)'

# View logs
gcloud logging tail "resource.type=cloud_run_revision"

# Manually deploy using script
export GCP_PROJECT_ID="pollingapp-prod-123456"
export DATABASE_PASSWORD="YourUserPassword123!"
export JWT_SECRET="your-jwt-secret"
export CLOUD_SQL_INSTANCE="pollingapp-prod-123456:us-central1:pollingapp-db"
./gcp-deploy.sh full

# Rollback deployment
./gcp-deploy.sh rollback

# View Jenkins logs
docker logs -f jenkins
```

## Cost Estimate

| Service | Monthly Cost |
|---------|-------------|
| Cloud Run (1M requests) | ~$0-5 |
| Cloud SQL (f1-micro) | ~$7-10 |
| Artifact Registry (1GB) | ~$0.10 |
| **Total** | **~$10-15/month** |

## Next Steps

1. ✅ Set up monitoring (Cloud Monitoring)
2. ✅ Add staging environment
3. ✅ Configure custom domain
4. ✅ Set up Cloud CDN
5. ✅ Add alerts for errors

## Resources

- Full Documentation: [GCP_JENKINS_GUIDE.md](GCP_JENKINS_GUIDE.md)
- Jenkins Pipeline: [Jenkinsfile.gcp](Jenkinsfile.gcp)
- Deployment Script: [gcp-deploy.sh](gcp-deploy.sh)
- GCP Console: https://console.cloud.google.com

---

**Questions?** Review the detailed [GCP_JENKINS_GUIDE.md](GCP_JENKINS_GUIDE.md)

**Happy Deploying!** 🚀
