# Complete Jenkins CI/CD Pipeline Setup Guide for PollingApp

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Jenkins Installation](#jenkins-installation)
3. [Jenkins Configuration](#jenkins-configuration)
4. [Pipeline Overview](#pipeline-overview)
5. [Step-by-Step Setup](#step-by-step-setup)
6. [Pipeline Stages Explained](#pipeline-stages-explained)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### System Requirements
- Java 17 (same as your application)
- Maven 3.6+
- Node.js 18+ and npm
- Docker (for containerized builds/deployments)
- Git
- At least 4GB RAM for Jenkins server

### Knowledge Requirements
- Basic Git commands
- Understanding of your application architecture
- Basic Linux/terminal commands

---

## Jenkins Installation

### Option 1: Using Docker (Recommended for beginners)

```bash
# Create a docker network
docker network create jenkins

# Run Jenkins in Docker
docker run -d \
  --name jenkins \
  --network jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts-jdk17
```

### Option 2: Native Installation on macOS

```bash
# Install using Homebrew
brew install jenkins-lts

# Start Jenkins
brew services start jenkins-lts
```

### Option 3: Linux Installation

```bash
# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt-get update
sudo apt-get install jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

---

## Jenkins Initial Setup

### 1. Access Jenkins

Open your browser and navigate to:
```
http://localhost:8080
```

### 2. Unlock Jenkins

Get the initial admin password:

```bash
# For Docker installation
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# For native installation (macOS)
cat ~/.jenkins/secrets/initialAdminPassword

# For Linux
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 3. Install Suggested Plugins

When prompted:
- Select "Install suggested plugins"
- Wait for installation to complete

### 4. Additional Required Plugins

Go to **Manage Jenkins** → **Manage Plugins** → **Available** and install:

- **Maven Integration Plugin**
- **Pipeline Plugin** (usually pre-installed)
- **Docker Pipeline Plugin**
- **Git Plugin** (usually pre-installed)
- **GitHub Integration Plugin**
- **NodeJS Plugin**
- **Slack Notification Plugin** (optional)
- **Email Extension Plugin** (optional)

Click "Install without restart"

### 5. Create Admin User

Fill in the form with your details:
- Username: (your choice)
- Password: (your choice)
- Full name: (your name)
- Email: (your email)

---

## Jenkins Configuration

### 1. Configure JDK

**Manage Jenkins** → **Global Tool Configuration** → **JDK**

Click "Add JDK"
- Name: `Java-17`
- Uncheck "Install automatically" if you have Java installed
- JAVA_HOME: Enter your Java 17 installation path
  ```bash
  # Find Java home on macOS/Linux
  /usr/libexec/java_home -v 17
  ```

### 2. Configure Maven

**Manage Jenkins** → **Global Tool Configuration** → **Maven**

Click "Add Maven"
- Name: `Maven-3.9`
- Check "Install automatically"
- Version: Select latest 3.9.x version

### 3. Configure NodeJS

**Manage Jenkins** → **Global Tool Configuration** → **NodeJS**

Click "Add NodeJS"
- Name: `NodeJS-18`
- Check "Install automatically"
- Version: Select 18.x or higher

### 4. Configure Git (Usually auto-detected)

**Manage Jenkins** → **Global Tool Configuration** → **Git**
- Usually automatically configured
- Verify path to git executable

### 5. Configure Docker (if needed)

**Manage Jenkins** → **Global Tool Configuration** → **Docker**

Click "Add Docker"
- Name: `Docker`
- Check "Install automatically"
- Select latest version

---

## Pipeline Overview

Your CI/CD pipeline will have the following stages:

```
┌─────────────────────────────────────────────────────────────┐
│                    CI/CD PIPELINE FLOW                      │
└─────────────────────────────────────────────────────────────┘

1. CHECKOUT
   └─> Clone code from Git repository

2. BUILD BACKEND
   └─> Compile Java code with Maven
   └─> Run backend unit tests
   └─> Create JAR file

3. BUILD FRONTEND
   └─> Install npm dependencies
   └─> Build React application with Vite
   └─> Run frontend tests (if any)

4. TEST
   └─> Run integration tests
   └─> Code quality analysis (SonarQube - optional)
   └─> Security scanning (optional)

5. PACKAGE
   └─> Build Docker image
   └─> Tag with build number

6. DEPLOY TO DEV/STAGING
   └─> Deploy to test environment
   └─> Run smoke tests

7. APPROVAL (Manual)
   └─> Wait for manual approval for production

8. DEPLOY TO PRODUCTION
   └─> Deploy to production environment
   └─> Health check verification

9. NOTIFICATION
   └─> Send success/failure notifications
```

---

## Step-by-Step Setup

### Step 1: Prepare Your Repository

1. **Ensure your code is in a Git repository**
   ```bash
   cd /Users/yeswanthvajja/PollingApp

   # If not already a Git repo
   git init
   git add .
   git commit -m "Initial commit"

   # Push to GitHub/GitLab/Bitbucket
   git remote add origin <your-repo-url>
   git push -u origin main
   ```

2. **Add the Jenkinsfile** (provided in this project)
   - The Jenkinsfile defines your pipeline stages
   - It should be in the root directory of your project

### Step 2: Create Jenkins Pipeline Job

1. **Go to Jenkins Dashboard**
2. **Click "New Item"**
3. **Enter job name**: `PollingApp-Pipeline`
4. **Select**: "Pipeline"
5. **Click**: "OK"

### Step 3: Configure Pipeline Job

In the job configuration page:

#### General Section
- **Description**: "CI/CD Pipeline for Polling Application"
- **GitHub project** (optional): Enter your repository URL

#### Build Triggers
Select one or more:
- ☑ **GitHub hook trigger for GITScm polling** (for automatic builds on push)
- ☑ **Poll SCM**: Schedule: `H/5 * * * *` (checks every 5 minutes)

#### Pipeline Section
- **Definition**: "Pipeline script from SCM"
- **SCM**: Git
- **Repository URL**: Your Git repository URL
- **Credentials**: Click "Add" to add Git credentials if private repo
  - Kind: Username with password
  - Username: Your Git username
  - Password: Your Git password or personal access token
- **Branch Specifier**: `*/main` (or `*/master`)
- **Script Path**: `Jenkinsfile`

Click **Save**

### Step 4: Configure Credentials (for deployment)

**Manage Jenkins** → **Manage Credentials** → **Global** → **Add Credentials**

Add the following credentials as needed:

#### For Docker Hub
- **Kind**: Username with password
- **ID**: `dockerhub-credentials`
- **Username**: Your Docker Hub username
- **Password**: Your Docker Hub password

#### For Database (Production)
- **Kind**: Secret text
- **ID**: `postgres-db-url`
- **Secret**: Your database URL

- **Kind**: Username with password
- **ID**: `postgres-credentials`
- **Username**: Database username
- **Password**: Database password

#### For JWT Secret
- **Kind**: Secret text
- **ID**: `jwt-secret`
- **Secret**: Your JWT secret key

### Step 5: Run Your First Build

1. **Go to your pipeline job**
2. **Click "Build Now"**
3. **Watch the pipeline execution**
   - Click on the build number (e.g., #1)
   - Click "Console Output" to see logs
   - View "Pipeline Steps" for stage-by-stage execution

---

## Pipeline Stages Explained

### Stage 1: Checkout
```groovy
stage('Checkout') {
    steps {
        checkout scm
    }
}
```
- Clones your Git repository
- Ensures latest code is available

### Stage 2: Build Backend
```groovy
stage('Build Backend') {
    steps {
        sh 'mvn clean compile'
    }
}
```
- Cleans previous builds
- Compiles Java source code
- Downloads dependencies

### Stage 3: Test Backend
```groovy
stage('Test Backend') {
    steps {
        sh 'mvn test'
    }
}
```
- Runs unit tests
- Generates test reports
- Fails build if tests fail

### Stage 4: Package Backend
```groovy
stage('Package Backend') {
    steps {
        sh 'mvn package -DskipTests'
    }
}
```
- Creates executable JAR file
- Located in `target/` directory

### Stage 5: Build Frontend
```groovy
stage('Build Frontend') {
    steps {
        sh 'npm install'
        sh 'npm run build'
    }
}
```
- Installs Node dependencies
- Builds production React bundle
- Output in `dist/` directory

### Stage 6: Docker Build
```groovy
stage('Build Docker Image') {
    steps {
        script {
            docker.build("pollingapp:${BUILD_NUMBER}")
        }
    }
}
```
- Builds Docker image using your Dockerfile
- Tags with Jenkins build number

### Stage 7: Deploy
```groovy
stage('Deploy') {
    steps {
        // Deployment commands
    }
}
```
- Deploys to target environment
- Can be staging or production

---

## Environment-Specific Configurations

### Development Environment
- Automatic deployment on every commit
- Uses local or dev database
- No approval required

### Staging/QA Environment
- Deployment after successful tests
- Mirror of production setup
- Testing ground for QA team

### Production Environment
- Manual approval required
- Uses production database
- Rollback strategy in place

---

## Webhook Setup (Automatic Builds)

### GitHub Webhook

1. **Go to your GitHub repository**
2. **Settings** → **Webhooks** → **Add webhook**
3. **Payload URL**: `http://<jenkins-url>:8080/github-webhook/`
4. **Content type**: application/json
5. **Events**: Select "Just the push event"
6. **Active**: Checked
7. Click **Add webhook**

### GitLab Webhook

1. **Go to your GitLab repository**
2. **Settings** → **Webhooks**
3. **URL**: `http://<jenkins-url>:8080/project/<job-name>`
4. **Trigger**: Push events
5. Click **Add webhook**

---

## Best Practices

### 1. Use Multi-Branch Pipeline
For larger projects, consider using Multi-Branch Pipeline:
- Automatically creates pipelines for each branch
- Separate pipelines for feature branches
- PR validation before merge

### 2. Parallel Execution
Run independent stages in parallel:
```groovy
stage('Parallel Tests') {
    parallel {
        stage('Backend Tests') { ... }
        stage('Frontend Tests') { ... }
    }
}
```

### 3. Artifact Archiving
Save build artifacts:
```groovy
post {
    always {
        archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
        junit 'target/surefire-reports/*.xml'
    }
}
```

### 4. Notifications
Add Slack/Email notifications:
```groovy
post {
    success {
        slackSend color: 'good', message: "Build ${BUILD_NUMBER} succeeded"
    }
    failure {
        slackSend color: 'danger', message: "Build ${BUILD_NUMBER} failed"
    }
}
```

---

## Deployment Strategies

### Strategy 1: Docker Compose Deployment (Simple)
```bash
docker-compose down
docker-compose up -d
```

### Strategy 2: Kubernetes Deployment (Scalable)
```bash
kubectl apply -f k8s-deployment.yaml
kubectl rollout status deployment/pollingapp
```

### Strategy 3: Cloud Platform Deployment
- **AWS**: ECS, EKS, Elastic Beanstalk
- **GCP**: GKE, Cloud Run, App Engine
- **Azure**: AKS, Container Instances

---

## Monitoring and Health Checks

Your application has Spring Boot Actuator configured:

```bash
# Health check endpoint
curl http://localhost:8080/actuator/health

# Application info
curl http://localhost:8080/actuator/info
```

Add this to your deployment stage:
```groovy
stage('Health Check') {
    steps {
        sh '''
            sleep 10
            curl -f http://localhost:8080/actuator/health || exit 1
        '''
    }
}
```

---

## Troubleshooting

### Issue 1: Maven not found
**Solution**: Configure Maven in Jenkins Global Tool Configuration

### Issue 2: Node/npm not found
**Solution**: Install NodeJS plugin and configure in Global Tool Configuration

### Issue 3: Docker permission denied
**Solution**: Add Jenkins user to docker group
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Issue 4: Port 8080 already in use
**Solution**: Change Jenkins port
```bash
# Edit Jenkins config
sudo nano /etc/default/jenkins
# Change HTTP_PORT=8080 to HTTP_PORT=9090
```

### Issue 5: Build fails with Java version mismatch
**Solution**: Ensure Jenkins uses Java 17 (same as your app)

### Issue 6: Database connection fails during build
**Solution**: Use H2 in-memory database for testing
```properties
# In application-test.properties
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driver-class-name=org.h2.Driver
spring.jpa.hibernate.ddl-auto=create-drop
```

---

## Security Considerations

1. **Never commit credentials** to Git
2. **Use Jenkins Credentials** for sensitive data
3. **Enable CSRF protection** in Jenkins
4. **Use HTTPS** for production Jenkins
5. **Implement role-based access** control
6. **Regular Jenkins updates**
7. **Scan Docker images** for vulnerabilities

---

## Next Steps

1. ✅ Install Jenkins
2. ✅ Configure tools (JDK, Maven, NodeJS)
3. ✅ Create pipeline job
4. ✅ Add Jenkinsfile to your repository
5. ✅ Run first build
6. ☐ Add tests to your application
7. ☐ Setup deployment environment
8. ☐ Configure webhooks for automatic builds
9. ☐ Add notifications
10. ☐ Setup production deployment with approval

---

## Additional Resources

- [Jenkins Official Documentation](https://www.jenkins.io/doc/)
- [Pipeline Syntax Reference](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Docker Pipeline Plugin](https://plugins.jenkins.io/docker-workflow/)
- [Spring Boot with Jenkins](https://spring.io/guides/gs/jenkins/)

---

## Getting Help

If you encounter issues:
1. Check Jenkins console output
2. Review Jenkins system logs: **Manage Jenkins** → **System Log**
3. Search Jenkins community forums
4. Check your application logs

Remember: CI/CD is iterative - start simple and add complexity as needed!
