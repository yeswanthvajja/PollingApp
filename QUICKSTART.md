# Jenkins CI/CD Quick Start Guide

This guide will help you get your Jenkins CI/CD pipeline up and running in **30 minutes**.

## Prerequisites Checklist

- [ ] Java 17 installed
- [ ] Maven installed
- [ ] Docker installed and running
- [ ] Git repository set up

## Step-by-Step Setup

### Step 1: Install Jenkins (5 minutes)

#### Option A: Using Docker (Recommended)

```bash
# Create Jenkins container
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts-jdk17

# Get initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

#### Option B: macOS (using Homebrew)

```bash
brew install jenkins-lts
brew services start jenkins-lts

# Get initial password
cat ~/.jenkins/secrets/initialAdminPassword
```

### Step 2: Initial Jenkins Configuration (5 minutes)

1. **Open Jenkins**: Navigate to `http://localhost:8080`

2. **Unlock Jenkins**: Paste the initial admin password

3. **Install Plugins**: Click "Install suggested plugins"

4. **Create Admin User**: Fill in your details

5. **Jenkins URL**: Keep default `http://localhost:8080/`

### Step 3: Install Additional Plugins (3 minutes)

Go to **Manage Jenkins** → **Manage Plugins** → **Available**

Search and install:
- [ ] Docker Pipeline
- [ ] Maven Integration
- [ ] NodeJS Plugin

Click "Install without restart"

### Step 4: Configure Tools (5 minutes)

#### Configure JDK

**Manage Jenkins** → **Global Tool Configuration** → **JDK**

- Name: `Java-17`
- Check "Install automatically"
- Version: Select Java 17

#### Configure Maven

**Manage Jenkins** → **Global Tool Configuration** → **Maven**

- Name: `Maven-3.9`
- Check "Install automatically"
- Version: Select 3.9.x

#### Configure NodeJS

**Manage Jenkins** → **Global Tool Configuration** → **NodeJS**

- Name: `NodeJS-18`
- Check "Install automatically"
- Version: Select 18.x

Click **Save**

### Step 5: Set Up Your Git Repository (2 minutes)

```bash
cd /Users/yeswanthvajja/PollingApp

# Initialize git if not already done
git init

# Add all files
git add .

# Commit
git commit -m "Add Jenkins pipeline configuration"

# Add remote (replace with your repository URL)
git remote add origin https://github.com/YOUR_USERNAME/PollingApp.git

# Push to GitHub
git push -u origin main
```

### Step 6: Configure Credentials (3 minutes)

**Manage Jenkins** → **Manage Credentials** → **Global** → **Add Credentials**

#### Add Docker Hub Credentials

- Kind: Username with password
- ID: `dockerhub-credentials`
- Username: Your Docker Hub username
- Password: Your Docker Hub password/token
- Click **Create**

#### Add Database Credentials (for deployment)

- Kind: Username with password
- ID: `postgres-credentials`
- Username: Your database username
- Password: Your database password
- Click **Create**

#### Add JWT Secret

- Kind: Secret text
- ID: `jwt-secret`
- Secret: Your JWT secret key
- Click **Create**

### Step 7: Create Jenkins Pipeline Job (5 minutes)

1. **Go to Jenkins Dashboard**

2. **Click "New Item"**

3. **Enter item name**: `PollingApp-Pipeline`

4. **Select**: "Pipeline"

5. **Click**: "OK"

6. **In Pipeline Configuration**:
   - Description: "CI/CD Pipeline for Polling Application"
   - **Build Triggers**: Check "Poll SCM"
     - Schedule: `H/5 * * * *` (checks every 5 minutes)
   - **Pipeline**:
     - Definition: "Pipeline script from SCM"
     - SCM: Git
     - Repository URL: `https://github.com/YOUR_USERNAME/PollingApp.git`
     - Credentials: Add your Git credentials if private repo
     - Branch: `*/main`
     - Script Path: `Jenkinsfile`

7. **Click Save**

### Step 8: Update Jenkinsfile (2 minutes)

Edit the [Jenkinsfile](Jenkinsfile) in your project:

1. **Line 14**: Change `DOCKER_REGISTRY` to your Docker Hub username:
   ```groovy
   DOCKER_REGISTRY = "your-dockerhub-username" // Change this!
   ```

2. **Commit and push**:
   ```bash
   git add Jenkinsfile
   git commit -m "Update Docker registry username"
   git push
   ```

### Step 9: Run Your First Build (5 minutes)

1. **Go to your pipeline job**: `PollingApp-Pipeline`

2. **Click "Build Now"**

3. **Watch the pipeline execute**:
   - Click on the build number (e.g., #1)
   - Click "Console Output" to see real-time logs
   - View "Pipeline Steps" for stage-by-stage execution

4. **Wait for completion** (first build takes ~5-10 minutes due to downloads)

### Step 10: Verify Success

#### Check Build Status

- Green checkmark = Success!
- Red X = Failed (check console output)

#### View Artifacts

- Click on the build number
- See "Build Artifacts" section
- Your JAR file should be listed

#### Check Docker Image

```bash
docker images | grep pollingapp
```

You should see your newly built image!

## Common First-Time Issues & Solutions

### Issue: "Maven not found"

**Solution**: Go back to Step 4 and configure Maven in Global Tool Configuration

### Issue: "Docker permission denied"

**Solution**:
```bash
# Add your user to docker group
sudo usermod -aG docker $USER
# Logout and login again
```

### Issue: "Tests failing"

**Solution**: The sample tests are included. If you see test failures:
```bash
# Run tests locally first
mvn test

# Fix any issues, then commit and push
git add .
git commit -m "Fix tests"
git push
```

### Issue: "Cannot connect to Docker daemon"

**Solution**: Make sure Docker Desktop is running

### Issue: "Git credentials not working"

**Solution**: Use a Personal Access Token instead of password
- GitHub: Settings → Developer settings → Personal access tokens
- Use the token as your password in Jenkins credentials

## What Happens in the Pipeline?

```
1. Checkout        → Clones your code from Git
2. Build Backend   → Compiles Java code with Maven
3. Test Backend    → Runs JUnit tests
4. Package         → Creates JAR file
5. Build Frontend  → Builds React app with Vite
6. Build Docker    → Creates Docker image
7. Push Docker     → Pushes to Docker Hub
8. Deploy          → Deploys to environment (optional)
9. Health Check    → Verifies app is running
```

## Next Steps

### Enable Automatic Builds (GitHub Webhook)

1. **Go to your GitHub repository**
2. **Settings** → **Webhooks** → **Add webhook**
3. **Payload URL**: `http://YOUR_JENKINS_URL:8080/github-webhook/`
4. **Content type**: application/json
5. **Events**: Just the push event
6. **Add webhook**

Now every push to GitHub will trigger a build!

### Add Email Notifications

1. **Manage Jenkins** → **Configure System**
2. **E-mail Notification** section
3. Configure SMTP server
4. Uncomment email sections in Jenkinsfile

### Set Up Deployment Environment

#### Local Deployment (Docker Compose)

```bash
# Start PostgreSQL
docker-compose up -d postgres

# Deploy using deployment script
./deploy.sh deploy
```

#### Cloud Deployment

- AWS: Use ECS, EKS, or Elastic Beanstalk
- GCP: Use Cloud Run or GKE
- Azure: Use Container Instances or AKS

See [JENKINS_SETUP_GUIDE.md](JENKINS_SETUP_GUIDE.md) for detailed deployment strategies.

## Useful Commands

```bash
# View Jenkins logs (Docker)
docker logs -f jenkins

# Restart Jenkins
docker restart jenkins

# Access Jenkins CLI
java -jar jenkins-cli.jar -s http://localhost:8080/ help

# Run deployment script
ENVIRONMENT=development ./deploy.sh full

# Manual Docker build
docker build -t pollingapp:local .

# Run container locally
docker run -p 8080:8080 pollingapp:local
```

## Getting Help

### Jenkins Resources
- Dashboard: http://localhost:8080
- System Log: Manage Jenkins → System Log
- Plugin Manager: Manage Jenkins → Manage Plugins

### Project Resources
- Full Documentation: [JENKINS_SETUP_GUIDE.md](JENKINS_SETUP_GUIDE.md)
- Deployment Script: [deploy.sh](deploy.sh)
- Pipeline Definition: [Jenkinsfile](Jenkinsfile)

### Troubleshooting Checklist

- [ ] Is Jenkins running? (`docker ps` or `brew services list`)
- [ ] Are tools configured? (Java, Maven, NodeJS)
- [ ] Are credentials added? (Docker Hub, Git)
- [ ] Is Docker running?
- [ ] Is the Git repository accessible?
- [ ] Check console output for specific errors

## Success Indicators

You've successfully set up CI/CD when:

- [x] Jenkins is accessible at http://localhost:8080
- [x] Pipeline builds without errors
- [x] Tests pass successfully
- [x] Docker image is created and pushed
- [x] Build artifacts are archived
- [x] Automatic builds trigger on Git push

## What You've Accomplished

Congratulations! You now have:

1. ✅ Jenkins server running
2. ✅ Complete CI/CD pipeline
3. ✅ Automated builds on code changes
4. ✅ Automated testing
5. ✅ Docker containerization
6. ✅ Artifact archiving
7. ✅ Deployment automation (optional)

## Further Learning

- Add SonarQube for code quality analysis
- Implement multi-branch pipelines
- Set up staging and production environments
- Add integration and E2E tests
- Implement blue-green deployments
- Add monitoring with Prometheus/Grafana

---

**Time to first successful build**: ~30 minutes
**Difficulty**: Beginner-friendly
**Cost**: Free (local setup)

Happy Building! 🚀
