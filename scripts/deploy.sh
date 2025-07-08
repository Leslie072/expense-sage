#!/bin/bash

# Production deployment script for Expense Sage
set -e

echo "🚀 Starting Expense Sage Production Deployment..."

# Configuration
PROJECT_NAME="expense-sage"
DOCKER_COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env.production"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
    if [ ! -f "$ENV_FILE" ]; then
        log_warn "Environment file $ENV_FILE not found, creating from template..."
        cp .env.production.example .env.production
        log_warn "Please edit .env.production with your configuration"
    fi
    
    log_info "Prerequisites check completed"
}

# Create necessary directories
setup_directories() {
    log_info "Setting up directories..."
    
    mkdir -p data
    mkdir -p docker/backup
    mkdir -p docker/ssl
    mkdir -p logs
    
    # Set proper permissions
    chmod 755 data
    chmod 755 docker/backup
    chmod 700 docker/ssl
    
    log_info "Directories setup completed"
}

# Generate SSL certificates (self-signed for development)
setup_ssl() {
    log_info "Setting up SSL certificates..."
    
    if [ ! -f "docker/ssl/cert.pem" ]; then
        log_warn "SSL certificates not found, generating self-signed certificates..."
        
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout docker/ssl/private.key \
            -out docker/ssl/cert.pem \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
        
        chmod 600 docker/ssl/private.key
        chmod 644 docker/ssl/cert.pem
        
        log_warn "Self-signed certificates generated. Replace with proper certificates for production."
    fi
    
    log_info "SSL setup completed"
}

# Build and start services
deploy_services() {
    log_info "Building and starting services..."
    
    # Load environment variables
    export $(cat $ENV_FILE | grep -v '^#' | xargs)
    
    # Build images
    docker-compose -f $DOCKER_COMPOSE_FILE build --no-cache
    
    # Start services
    docker-compose -f $DOCKER_COMPOSE_FILE up -d
    
    log_info "Services started successfully"
}

# Health check
health_check() {
    log_info "Performing health check..."
    
    # Wait for services to start
    sleep 30
    
    # Check if web service is responding
    if curl -f http://localhost/health > /dev/null 2>&1; then
        log_info "✅ Web service is healthy"
    else
        log_error "❌ Web service health check failed"
        docker-compose logs expense-sage-web
        exit 1
    fi
    
    # Check if database is accessible
    if docker-compose exec -T expense-sage-db sqlite3 /data/expense_sage.db "SELECT 1;" > /dev/null 2>&1; then
        log_info "✅ Database is accessible"
    else
        log_error "❌ Database health check failed"
        exit 1
    fi
    
    log_info "Health check completed successfully"
}

# Backup existing data
backup_data() {
    if [ -f "data/expense_sage.db" ]; then
        log_info "Creating backup of existing data..."
        
        timestamp=$(date +%Y%m%d_%H%M%S)
        cp data/expense_sage.db "docker/backup/expense_sage_backup_${timestamp}.db"
        
        log_info "Backup created: expense_sage_backup_${timestamp}.db"
    fi
}

# Show deployment information
show_info() {
    log_info "🎉 Deployment completed successfully!"
    echo ""
    echo "📋 Service Information:"
    echo "  Web Application: http://localhost"
    echo "  Health Check: http://localhost/health"
    echo "  Admin Panel: http://localhost/admin"
    echo ""
    echo "🐳 Docker Commands:"
    echo "  View logs: docker-compose logs -f"
    echo "  Stop services: docker-compose down"
    echo "  Restart services: docker-compose restart"
    echo ""
    echo "📊 Monitoring:"
    echo "  Prometheus (if enabled): http://localhost:9090"
    echo ""
    echo "💾 Data Location:"
    echo "  Database: ./data/expense_sage.db"
    echo "  Backups: ./docker/backup/"
    echo ""
}

# Main deployment process
main() {
    log_info "Starting deployment process..."
    
    check_prerequisites
    setup_directories
    setup_ssl
    backup_data
    deploy_services
    health_check
    show_info
    
    log_info "🚀 Expense Sage is now running in production mode!"
}

# Run main function
main "$@"
