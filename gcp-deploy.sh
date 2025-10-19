#!/bin/bash

###############################################################################
# GCP Deployment Script for PollingApp
# This script deploys the application to Google Cloud Platform
###############################################################################

set -e  # Exit on any error

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="pollingapp"
REGION="${GCP_REGION:-us-central1}"
ZONE="${GCP_ZONE:-us-central1-a}"
ENVIRONMENT="${ENVIRONMENT:-production}"

# Get project ID from gcloud config or environment variable
PROJECT_ID="${GCP_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}[ERROR]${NC} GCP_PROJECT_ID is not set"
    echo "Run: export GCP_PROJECT_ID=your-project-id"
    exit 1
fi

# Artifact Registry configuration
ARTIFACT_REGISTRY="${ARTIFACT_REGISTRY:-${REGION}-docker.pkg.dev/${PROJECT_ID}/pollingapp-repo}"
IMAGE_NAME="${ARTIFACT_REGISTRY}/${APP_NAME}"
VERSION="${VERSION:-latest}"

# Cloud Run configuration
CLOUD_RUN_SERVICE="${APP_NAME}"
if [ "$ENVIRONMENT" != "production" ]; then
    CLOUD_RUN_SERVICE="${APP_NAME}-${ENVIRONMENT}"
fi

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."

    # Check if gcloud is installed
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI is not installed"
        log_info "Install from: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi

    # Check if authenticated with GCP
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
        log_error "Not authenticated with GCP"
        log_info "Run: gcloud auth login"
        exit 1
    fi

    log_info "All prerequisites met ✓"
}

# Authenticate Docker with Artifact Registry
setup_docker_auth() {
    log_step "Setting up Docker authentication..."

    gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet

    log_info "Docker authentication configured ✓"
}

# Build the application
build_application() {
    log_step "Building Spring Boot application..."

    mvn clean package -DskipTests

    if [ $? -eq 0 ]; then
        log_info "Application built successfully ✓"
    else
        log_error "Application build failed"
        exit 1
    fi
}

# Build frontend
build_frontend() {
    log_step "Building React frontend..."

    cd frontend
    npm install
    npm run build
    cd ..

    log_info "Frontend built successfully ✓"
}

# Run tests
run_tests() {
    log_step "Running tests..."

    mvn test

    if [ $? -eq 0 ]; then
        log_info "Tests passed ✓"
    else
        log_error "Tests failed"
        exit 1
    fi
}

# Build Docker image
build_docker_image() {
    log_step "Building Docker image: ${IMAGE_NAME}:${VERSION}"

    docker build \
        -t ${IMAGE_NAME}:${VERSION} \
        -t ${IMAGE_NAME}:latest \
        --build-arg JAR_FILE=target/*.jar \
        .

    if [ $? -eq 0 ]; then
        log_info "Docker image built successfully ✓"
        docker images | grep ${APP_NAME} | head -n 2
    else
        log_error "Docker image build failed"
        exit 1
    fi
}

# Push Docker image to Artifact Registry
push_docker_image() {
    log_step "Pushing Docker image to Artifact Registry..."

    docker push ${IMAGE_NAME}:${VERSION}
    docker push ${IMAGE_NAME}:latest

    if [ $? -eq 0 ]; then
        log_info "Docker image pushed successfully ✓"
    else
        log_error "Docker image push failed"
        exit 1
    fi
}

# Deploy to Cloud Run
deploy_cloud_run() {
    log_step "Deploying to Cloud Run (${ENVIRONMENT})..."

    # Set resource limits based on environment
    if [ "$ENVIRONMENT" = "production" ]; then
        MEMORY="1Gi"
        CPU="2"
        MIN_INSTANCES="1"
        MAX_INSTANCES="10"
    else
        MEMORY="512Mi"
        CPU="1"
        MIN_INSTANCES="0"
        MAX_INSTANCES="3"
    fi

    # Get environment variables
    if [ -z "$DATABASE_PASSWORD" ]; then
        log_error "DATABASE_PASSWORD is not set"
        exit 1
    fi

    if [ -z "$JWT_SECRET" ]; then
        log_error "JWT_SECRET is not set"
        exit 1
    fi

    if [ -z "$CLOUD_SQL_INSTANCE" ]; then
        log_error "CLOUD_SQL_INSTANCE is not set (format: project:region:instance)"
        exit 1
    fi

    # Deploy to Cloud Run
    gcloud run deploy ${CLOUD_RUN_SERVICE} \
        --image=${IMAGE_NAME}:${VERSION} \
        --platform=managed \
        --region=${REGION} \
        --allow-unauthenticated \
        --port=8080 \
        --memory=${MEMORY} \
        --cpu=${CPU} \
        --min-instances=${MIN_INSTANCES} \
        --max-instances=${MAX_INSTANCES} \
        --set-env-vars="SPRING_PROFILES_ACTIVE=prod" \
        --set-env-vars="DATABASE_NAME=${DATABASE_NAME:-pollingdb}" \
        --set-env-vars="DATABASE_USER=${DATABASE_USER:-pollingapp_user}" \
        --set-env-vars="DATABASE_PASSWORD=${DATABASE_PASSWORD}" \
        --set-env-vars="JWT_SECRET=${JWT_SECRET}" \
        --set-env-vars="CLOUD_SQL_INSTANCE_CONNECTION_NAME=${CLOUD_SQL_INSTANCE}" \
        --add-cloudsql-instances=${CLOUD_SQL_INSTANCE} \
        --timeout=300 \
        --quiet

    if [ $? -eq 0 ]; then
        log_info "Deployment completed ✓"
    else
        log_error "Deployment failed"
        exit 1
    fi
}

# Get service URL
get_service_url() {
    log_step "Getting service URL..."

    SERVICE_URL=$(gcloud run services describe ${CLOUD_RUN_SERVICE} \
        --region=${REGION} \
        --format='value(status.url)')

    echo ""
    log_info "Service URL: ${SERVICE_URL}"
    echo ""
}

# Health check
health_check() {
    log_step "Running health check..."

    SERVICE_URL=$(gcloud run services describe ${CLOUD_RUN_SERVICE} \
        --region=${REGION} \
        --format='value(status.url)')

    # Wait for service to be ready
    log_info "Waiting for service to be ready..."
    sleep 20

    # Check health endpoint
    HEALTH_RESPONSE=$(curl -s ${SERVICE_URL}/actuator/health)
    HEALTH_STATUS=$(echo $HEALTH_RESPONSE | grep -o '"status":"UP"')

    if [ -n "$HEALTH_STATUS" ]; then
        log_info "Health check passed ✓"
        echo "Response: $HEALTH_RESPONSE"
    else
        log_error "Health check failed"
        echo "Response: $HEALTH_RESPONSE"
        exit 1
    fi
}

# View logs
view_logs() {
    log_step "Fetching recent logs..."

    gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=${CLOUD_RUN_SERVICE}" \
        --limit=50 \
        --format=json

    log_info "To stream logs in real-time, run:"
    echo "gcloud logging tail \"resource.type=cloud_run_revision AND resource.labels.service_name=${CLOUD_RUN_SERVICE}\""
}

# Rollback to previous version
rollback() {
    log_step "Rolling back deployment..."

    # Get current revisions
    REVISIONS=$(gcloud run revisions list \
        --service=${CLOUD_RUN_SERVICE} \
        --region=${REGION} \
        --format='value(name)' \
        --limit=5)

    echo "Available revisions:"
    echo "$REVISIONS"

    # Get the second revision (previous version)
    PREVIOUS_REVISION=$(echo "$REVISIONS" | sed -n '2p')

    if [ -z "$PREVIOUS_REVISION" ]; then
        log_error "No previous revision found"
        exit 1
    fi

    log_info "Rolling back to: $PREVIOUS_REVISION"

    # Update traffic to previous revision
    gcloud run services update-traffic ${CLOUD_RUN_SERVICE} \
        --region=${REGION} \
        --to-revisions=${PREVIOUS_REVISION}=100

    log_info "Rollback completed ✓"
}

# Setup database
setup_database() {
    log_step "Setting up Cloud SQL database..."

    DB_INSTANCE="${CLOUD_SQL_INSTANCE_NAME:-pollingapp-db}"
    DB_PASSWORD="${DATABASE_PASSWORD}"

    if [ -z "$DB_PASSWORD" ]; then
        log_error "DATABASE_PASSWORD is not set"
        exit 1
    fi

    # Create Cloud SQL instance (if not exists)
    if ! gcloud sql instances describe ${DB_INSTANCE} &> /dev/null; then
        log_info "Creating Cloud SQL instance..."

        gcloud sql instances create ${DB_INSTANCE} \
            --database-version=POSTGRES_14 \
            --tier=db-f1-micro \
            --region=${REGION} \
            --root-password=${DB_PASSWORD}

        log_info "Cloud SQL instance created ✓"
    else
        log_info "Cloud SQL instance already exists ✓"
    fi

    # Create database
    if ! gcloud sql databases describe pollingdb --instance=${DB_INSTANCE} &> /dev/null; then
        log_info "Creating database..."

        gcloud sql databases create pollingdb \
            --instance=${DB_INSTANCE}

        log_info "Database created ✓"
    else
        log_info "Database already exists ✓"
    fi

    # Create user
    log_info "Creating database user..."
    gcloud sql users create pollingapp_user \
        --instance=${DB_INSTANCE} \
        --password=${DB_PASSWORD} || log_info "User may already exist"

    log_info "Database setup completed ✓"
}

# Display help
show_help() {
    cat << EOF
GCP Deployment Script for PollingApp

Usage: $0 [COMMAND] [OPTIONS]

Commands:
  build         Build application and Docker image
  push          Push Docker image to Artifact Registry
  deploy        Deploy to Cloud Run
  full          Build, push, and deploy (complete deployment)
  rollback      Rollback to previous version
  logs          View application logs
  health        Run health check
  setup-db      Set up Cloud SQL database
  url           Get service URL
  help          Show this help message

Environment Variables:
  GCP_PROJECT_ID              GCP project ID (required)
  ENVIRONMENT                 Environment (production/staging/development)
  GCP_REGION                  GCP region (default: us-central1)
  DATABASE_PASSWORD           Database password (required for deployment)
  JWT_SECRET                  JWT secret key (required for deployment)
  CLOUD_SQL_INSTANCE          Cloud SQL instance connection name (format: project:region:instance)
  VERSION                     Docker image version tag (default: latest)

Examples:
  # Full deployment
  export GCP_PROJECT_ID=pollingapp-prod-123456
  export DATABASE_PASSWORD=your-db-password
  export JWT_SECRET=your-jwt-secret
  export CLOUD_SQL_INSTANCE=pollingapp-prod-123456:us-central1:pollingapp-db
  $0 full

  # Deploy to staging
  export ENVIRONMENT=staging
  $0 deploy

  # Rollback deployment
  $0 rollback

  # View logs
  $0 logs

EOF
}

# Main execution
main() {
    case "${1:-help}" in
        build)
            check_prerequisites
            build_application
            build_frontend
            build_docker_image
            ;;
        push)
            check_prerequisites
            setup_docker_auth
            push_docker_image
            ;;
        deploy)
            check_prerequisites
            setup_docker_auth
            deploy_cloud_run
            get_service_url
            health_check
            ;;
        full)
            check_prerequisites
            run_tests
            build_application
            build_frontend
            build_docker_image
            setup_docker_auth
            push_docker_image
            deploy_cloud_run
            get_service_url
            health_check
            ;;
        rollback)
            check_prerequisites
            rollback
            health_check
            ;;
        logs)
            check_prerequisites
            view_logs
            ;;
        health)
            check_prerequisites
            health_check
            ;;
        setup-db)
            check_prerequisites
            setup_database
            ;;
        url)
            check_prerequisites
            get_service_url
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac

    echo ""
    log_info "Operation completed successfully! ✓"
}

# Execute main function
main "$@"
