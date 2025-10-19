#!/bin/bash

###############################################################################
# Deployment Script for PollingApp
# This script can be used by Jenkins or run manually for deployment
###############################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="pollingapp"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-your-dockerhub-username}"
ENVIRONMENT="${ENVIRONMENT:-development}"
VERSION="${VERSION:-latest}"

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

# Check if required tools are installed
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    log_info "All prerequisites met."
}

# Build the application
build_application() {
    log_info "Building Spring Boot application..."

    mvn clean package -DskipTests

    if [ $? -eq 0 ]; then
        log_info "Application built successfully"
    else
        log_error "Application build failed"
        exit 1
    fi
}

# Build Docker image
build_docker_image() {
    log_info "Building Docker image: ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION}"

    docker build -t ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION} .
    docker tag ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION} ${DOCKER_REGISTRY}/${APP_NAME}:latest

    if [ $? -eq 0 ]; then
        log_info "Docker image built successfully"
    else
        log_error "Docker image build failed"
        exit 1
    fi
}

# Push Docker image to registry
push_docker_image() {
    log_info "Pushing Docker image to registry..."

    docker push ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION}
    docker push ${DOCKER_REGISTRY}/${APP_NAME}:latest

    if [ $? -eq 0 ]; then
        log_info "Docker image pushed successfully"
    else
        log_error "Docker image push failed"
        exit 1
    fi
}

# Deploy to development environment
deploy_development() {
    log_info "Deploying to Development environment..."

    # Stop and remove existing container
    docker stop ${APP_NAME}-dev 2>/dev/null || true
    docker rm ${APP_NAME}-dev 2>/dev/null || true

    # Run new container
    docker run -d \
        --name ${APP_NAME}-dev \
        -p 8080:8080 \
        -e SPRING_PROFILES_ACTIVE=dev \
        -e DATABASE_URL=${DATABASE_URL:-jdbc:postgresql://localhost:5432/pollingdb} \
        -e DATABASE_USERNAME=${DATABASE_USERNAME:-postgres} \
        -e DATABASE_PASSWORD=${DATABASE_PASSWORD:-postgres} \
        -e JWT_SECRET=${JWT_SECRET} \
        --restart unless-stopped \
        ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION}

    log_info "Deployment to Development completed"
}

# Deploy to staging environment
deploy_staging() {
    log_info "Deploying to Staging environment..."

    # Stop and remove existing container
    docker stop ${APP_NAME}-staging 2>/dev/null || true
    docker rm ${APP_NAME}-staging 2>/dev/null || true

    # Run new container
    docker run -d \
        --name ${APP_NAME}-staging \
        -p 8081:8080 \
        -e SPRING_PROFILES_ACTIVE=staging \
        -e DATABASE_URL=${DATABASE_URL} \
        -e DATABASE_USERNAME=${DATABASE_USERNAME} \
        -e DATABASE_PASSWORD=${DATABASE_PASSWORD} \
        -e JWT_SECRET=${JWT_SECRET} \
        --restart unless-stopped \
        ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION}

    log_info "Deployment to Staging completed"
}

# Deploy to production environment
deploy_production() {
    log_info "Deploying to Production environment..."

    # Confirm production deployment
    read -p "Are you sure you want to deploy to PRODUCTION? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        log_warn "Production deployment cancelled"
        exit 0
    fi

    # Stop and remove existing container
    docker stop ${APP_NAME}-prod 2>/dev/null || true
    docker rm ${APP_NAME}-prod 2>/dev/null || true

    # Run new container
    docker run -d \
        --name ${APP_NAME}-prod \
        -p 8080:8080 \
        -e SPRING_PROFILES_ACTIVE=prod \
        -e DATABASE_URL=${DATABASE_URL} \
        -e DATABASE_USERNAME=${DATABASE_USERNAME} \
        -e DATABASE_PASSWORD=${DATABASE_PASSWORD} \
        -e JWT_SECRET=${JWT_SECRET} \
        --restart unless-stopped \
        ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION}

    log_info "Deployment to Production completed"
}

# Health check
health_check() {
    log_info "Performing health check..."

    local port=${1:-8080}
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        log_info "Health check attempt $attempt/$max_attempts..."

        if curl -f http://localhost:${port}/actuator/health > /dev/null 2>&1; then
            log_info "Application is healthy!"
            return 0
        fi

        sleep 2
        attempt=$((attempt + 1))
    done

    log_error "Health check failed after $max_attempts attempts"
    return 1
}

# Rollback deployment
rollback() {
    log_warn "Rolling back deployment..."

    local container_name="${APP_NAME}-${ENVIRONMENT}"

    # Stop current container
    docker stop ${container_name} 2>/dev/null || true
    docker rm ${container_name} 2>/dev/null || true

    # Start previous version
    docker run -d \
        --name ${container_name} \
        -p 8080:8080 \
        -e SPRING_PROFILES_ACTIVE=${ENVIRONMENT} \
        -e DATABASE_URL=${DATABASE_URL} \
        -e DATABASE_USERNAME=${DATABASE_USERNAME} \
        -e DATABASE_PASSWORD=${DATABASE_PASSWORD} \
        -e JWT_SECRET=${JWT_SECRET} \
        --restart unless-stopped \
        ${DOCKER_REGISTRY}/${APP_NAME}:previous

    log_info "Rollback completed"
}

# Main execution
main() {
    log_info "Starting deployment process for environment: ${ENVIRONMENT}"

    check_prerequisites

    case "${1:-deploy}" in
        build)
            build_application
            build_docker_image
            ;;
        push)
            push_docker_image
            ;;
        deploy)
            case "${ENVIRONMENT}" in
                development|dev)
                    deploy_development
                    health_check 8080
                    ;;
                staging)
                    deploy_staging
                    health_check 8081
                    ;;
                production|prod)
                    deploy_production
                    health_check 8080
                    ;;
                *)
                    log_error "Unknown environment: ${ENVIRONMENT}"
                    exit 1
                    ;;
            esac
            ;;
        rollback)
            rollback
            ;;
        full)
            build_application
            build_docker_image
            push_docker_image

            case "${ENVIRONMENT}" in
                development|dev)
                    deploy_development
                    health_check 8080
                    ;;
                staging)
                    deploy_staging
                    health_check 8081
                    ;;
                production|prod)
                    deploy_production
                    health_check 8080
                    ;;
            esac
            ;;
        *)
            echo "Usage: $0 {build|push|deploy|rollback|full}"
            echo ""
            echo "Options:"
            echo "  build      - Build application and Docker image"
            echo "  push       - Push Docker image to registry"
            echo "  deploy     - Deploy to specified environment"
            echo "  rollback   - Rollback to previous version"
            echo "  full       - Build, push, and deploy"
            echo ""
            echo "Environment variables:"
            echo "  ENVIRONMENT        - Target environment (development/staging/production)"
            echo "  VERSION           - Application version (default: latest)"
            echo "  DOCKER_REGISTRY   - Docker registry username"
            echo "  DATABASE_URL      - Database connection URL"
            echo "  DATABASE_USERNAME - Database username"
            echo "  DATABASE_PASSWORD - Database password"
            echo "  JWT_SECRET        - JWT secret key"
            exit 1
            ;;
    esac

    log_info "Deployment process completed successfully!"
}

# Execute main function
main "$@"
