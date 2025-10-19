pipeline {
    agent any

    tools {
        maven 'Maven-3.9'
        jdk 'Java-17'
    }

    environment {
        DOCKER_IMAGE = "pollingapp"
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKER_REGISTRY = "your-dockerhub-username" // Change this to your Docker Hub username
        POSTGRES_CREDENTIALS = credentials('postgres-credentials')
        JWT_SECRET = credentials('jwt-secret')
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from repository...'
                checkout scm
                echo 'Code checkout completed'
            }
        }

        stage('Build Backend') {
            steps {
                echo 'Building Spring Boot backend...'
                dir('.') {
                    sh 'mvn clean compile'
                }
                echo 'Backend compilation completed'
            }
        }

        stage('Test Backend') {
            steps {
                echo 'Running backend unit tests...'
                dir('.') {
                    sh 'mvn test'
                }
                echo 'Backend tests completed'
            }
            post {
                always {
                    // Publish JUnit test results
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Package Backend') {
            steps {
                echo 'Packaging Spring Boot application...'
                dir('.') {
                    sh 'mvn package -DskipTests'
                }
                echo 'Backend packaging completed'
            }
            post {
                success {
                    // Archive the built JAR file
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }

        stage('Build Frontend') {
            tools {
                nodejs 'NodeJS-18'
            }
            steps {
                echo 'Building React frontend...'
                dir('frontend') {
                    sh 'npm install'
                    sh 'npm run build'
                }
                echo 'Frontend build completed'
            }
        }

        stage('Code Quality Analysis') {
            steps {
                echo 'Running code quality checks...'
                // Optional: Add SonarQube analysis here
                // sh 'mvn sonar:sonar'
                echo 'Code quality analysis completed'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                script {
                    dockerImage = docker.build("${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}")
                    // Also tag as latest
                    dockerImage.tag("latest")
                }
                echo 'Docker image built successfully'
            }
        }

        stage('Push Docker Image') {
            steps {
                echo 'Pushing Docker image to registry...'
                script {
                    // Login to Docker Hub using credentials
                    docker.withRegistry('https://registry.hub.docker.com', 'dockerhub-credentials') {
                        dockerImage.push("${DOCKER_TAG}")
                        dockerImage.push("latest")
                    }
                }
                echo 'Docker image pushed successfully'
            }
        }

        stage('Deploy to Development') {
            when {
                branch 'develop'
            }
            steps {
                echo 'Deploying to Development environment...'
                script {
                    // Example: Deploy using docker-compose
                    sh '''
                        docker-compose down || true
                        docker-compose up -d
                    '''
                }
                echo 'Deployment to Development completed'
            }
        }

        stage('Deploy to Staging') {
            when {
                branch 'staging'
            }
            steps {
                echo 'Deploying to Staging environment...'
                script {
                    // Deploy to staging server
                    sh '''
                        docker stop pollingapp-staging || true
                        docker rm pollingapp-staging || true
                        docker run -d \
                            --name pollingapp-staging \
                            -p 8081:8080 \
                            -e SPRING_PROFILES_ACTIVE=staging \
                            -e DATABASE_URL=${POSTGRES_CREDENTIALS_USR} \
                            -e DATABASE_PASSWORD=${POSTGRES_CREDENTIALS_PSW} \
                            -e JWT_SECRET=${JWT_SECRET} \
                            ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}
                    '''
                }
                echo 'Deployment to Staging completed'
            }
        }

        stage('Integration Tests') {
            when {
                anyOf {
                    branch 'staging'
                    branch 'main'
                }
            }
            steps {
                echo 'Running integration tests...'
                // Add integration test commands here
                // Example: sh 'mvn verify -Pintegration-tests'
                echo 'Integration tests completed'
            }
        }

        stage('Approval for Production') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo 'Waiting for manual approval for production deployment...'
                    input message: 'Deploy to Production?', ok: 'Deploy', submitter: 'admin'
                }
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                echo 'Deploying to Production environment...'
                script {
                    // Deploy to production server
                    sh '''
                        docker stop pollingapp-production || true
                        docker rm pollingapp-production || true
                        docker run -d \
                            --name pollingapp-production \
                            -p 8080:8080 \
                            -e SPRING_PROFILES_ACTIVE=prod \
                            -e DATABASE_URL=${POSTGRES_CREDENTIALS_USR} \
                            -e DATABASE_PASSWORD=${POSTGRES_CREDENTIALS_PSW} \
                            -e JWT_SECRET=${JWT_SECRET} \
                            --restart unless-stopped \
                            ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}
                    '''
                }
                echo 'Deployment to Production completed'
            }
        }

        stage('Health Check') {
            when {
                anyOf {
                    branch 'staging'
                    branch 'main'
                }
            }
            steps {
                echo 'Performing health check...'
                script {
                    def port = env.BRANCH_NAME == 'main' ? '8080' : '8081'
                    sh """
                        echo 'Waiting for application to start...'
                        sleep 30
                        echo 'Checking health endpoint...'
                        curl -f http://localhost:${port}/actuator/health || exit 1
                        echo 'Health check passed!'
                    """
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution completed'
            // Clean up workspace
            cleanWs()
        }

        success {
            echo 'Build and deployment successful!'
            // Send success notification
            // emailext (
            //     subject: "SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
            //     body: "Build succeeded: ${env.BUILD_URL}",
            //     to: "your-email@example.com"
            // )
        }

        failure {
            echo 'Build or deployment failed!'
            // Send failure notification
            // emailext (
            //     subject: "FAILURE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
            //     body: "Build failed: ${env.BUILD_URL}",
            //     to: "your-email@example.com"
            // )
        }

        unstable {
            echo 'Build is unstable - tests may have failed'
        }
    }
}
