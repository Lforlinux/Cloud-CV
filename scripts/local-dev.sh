#!/bin/bash
# Cloud CV - Local Development Script
# SRE/DevOps Engineer Portfolio

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$PROJECT_ROOT/docker"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

# Default values
SERVICE="all"
DETACH=false
BUILD=false
CLEAN=false

# Functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Start Cloud CV local development environment

OPTIONS:
    -s, --service SERVICE    Service to start (frontend, dev-server, monitoring, all)
    -d, --detach            Run in detached mode
    -b, --build             Build images before starting
    -c, --clean             Clean up containers and volumes
    -h, --help              Show this help message

SERVICES:
    frontend               Nginx-based frontend server
    dev-server             Node.js development server
    monitoring             Prometheus and Grafana
    localstack             LocalStack AWS emulation
    all                    All services (default)

EXAMPLES:
    $0                                          # Start all services
    $0 --service frontend --detach             # Start only frontend in background
    $0 --service monitoring --build            # Start monitoring with build
    $0 --clean                                 # Clean up everything

EOF
}

check_dependencies() {
    log "Checking dependencies..."
    
    local deps=("docker" "docker-compose")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        error "Missing dependencies: ${missing[*]}"
    fi
    
    success "All dependencies found"
}

cleanup_containers() {
    log "Cleaning up containers and volumes..."
    
    cd "$DOCKER_DIR"
    
    # Stop and remove containers
    docker-compose down --remove-orphans
    
    # Remove volumes if clean flag is set
    if [ "$CLEAN" = true ]; then
        docker-compose down -v --remove-orphans
        docker system prune -f
    fi
    
    success "Cleanup completed"
}

build_images() {
    if [ "$BUILD" = false ]; then
        return
    fi
    
    log "Building Docker images..."
    
    cd "$DOCKER_DIR"
    
    # Build frontend image
    docker-compose build frontend
    
    success "Images built successfully"
}

start_services() {
    log "Starting services..."
    
    cd "$DOCKER_DIR"
    
    local compose_cmd="docker-compose"
    local services=""
    
    # Determine services to start
    case "$SERVICE" in
        frontend)
            services="frontend"
            ;;
        dev-server)
            services="dev-server"
            ;;
        monitoring)
            services="prometheus grafana"
            ;;
        localstack)
            services="localstack localstack-init"
            ;;
        all)
            services="frontend localstack localstack-init"
            ;;
        *)
            error "Unknown service: $SERVICE"
            ;;
    esac
    
    # Add detach flag
    if [ "$DETACH" = true ]; then
        compose_cmd="$compose_cmd -d"
    fi
    
    # Start services
    if [ -n "$services" ]; then
        $compose_cmd up $services
    else
        $compose_cmd up
    fi
    
    success "Services started successfully"
}

show_urls() {
    log "Service URLs:"
    echo "  Frontend:     http://localhost:4000"
    echo "  Dev Server:   http://localhost:3000"
    echo "  Prometheus:   http://localhost:9090"
    echo "  Grafana:      http://localhost:3001 (admin/admin)"
    echo "  LocalStack:  http://localhost:4566"
    echo "  S3 Website:  http://localhost:4566/cloud-cv-local/index.html"
    echo ""
    echo "LocalStack AWS Services:"
    echo "  S3:           aws --endpoint-url=http://localhost:4566 s3 ls"
    echo "  DynamoDB:     aws --endpoint-url=http://localhost:4566 dynamodb list-tables"
    echo "  Lambda:       aws --endpoint-url=http://localhost:4566 lambda list-functions"
    echo "  API Gateway:  aws --endpoint-url=http://localhost:4566 apigateway get-rest-apis"
}

run_health_checks() {
    log "Running health checks..."
    
    # Check frontend
    if curl -f -s http://localhost:4000/health > /dev/null 2>&1; then
        success "Frontend is healthy"
    else
        warning "Frontend health check failed"
    fi
    
    # Check dev server
    if curl -f -s http://localhost:3000 > /dev/null 2>&1; then
        success "Dev server is healthy"
    else
        warning "Dev server health check failed"
    fi
    
    # Check LocalStack
    if curl -f -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
        success "LocalStack is healthy"
    else
        warning "LocalStack health check failed"
    fi
    
    # Check Prometheus
    if curl -f -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
        success "Prometheus is healthy"
    else
        warning "Prometheus health check failed"
    fi
    
    # Check Grafana
    if curl -f -s http://localhost:3001/api/health > /dev/null 2>&1; then
        success "Grafana is healthy"
    else
        warning "Grafana health check failed"
    fi
}

setup_development_environment() {
    log "Setting up development environment..."
    
    # Create .env file if it doesn't exist
    if [ ! -f "$PROJECT_ROOT/.env" ]; then
        cat > "$PROJECT_ROOT/.env" << EOF
# Cloud CV Development Environment
NODE_ENV=development
API_URL=http://localhost:9000
AWS_REGION=us-east-1
ENVIRONMENT=development
EOF
        success "Created .env file"
    fi
    
    # Create necessary directories
    mkdir -p "$PROJECT_ROOT/logs"
    mkdir -p "$PROJECT_ROOT/data"
    
    success "Development environment setup completed"
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--service)
                SERVICE="$2"
                shift 2
                ;;
            -d|--detach)
                DETACH=true
                shift
                ;;
            -b|--build)
                BUILD=true
                shift
                ;;
            -c|--clean)
                CLEAN=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
    
    log "Starting Cloud CV local development environment..."
    log "Service: $SERVICE"
    log "Detach: $DETACH"
    log "Build: $BUILD"
    log "Clean: $CLEAN"
    
    # Run setup steps
    check_dependencies
    setup_development_environment
    
    # Cleanup if requested
    if [ "$CLEAN" = true ]; then
        cleanup_containers
        exit 0
    fi
    
    # Build and start services
    build_images
    start_services
    
    # Show URLs and run health checks
    show_urls
    run_health_checks
    
    success "Local development environment is ready!"
    
    if [ "$DETACH" = false ]; then
        log "Press Ctrl+C to stop all services"
        # Wait for interrupt
        trap 'log "Stopping services..."; cleanup_containers; exit 0' INT
        while true; do
            sleep 1
        done
    fi
}

# Run main function
main "$@"
