#!/bin/bash

# Development Setup Script - Setup môi trường development
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "🚀 Setting up development environment..."

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v docker &> /dev/null; then
        missing_tools+=("Docker")
    fi
    
    if ! command -v dotnet &> /dev/null; then
        missing_tools+=(".NET 8 SDK")
    fi
    
    if ! command -v node &> /dev/null; then
        missing_tools+=("Node.js")
    fi
    
    if ! command -v npm &> /dev/null; then
        missing_tools+=("npm")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools:"
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        echo ""
        echo "Please install the missing tools and run this script again."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Setup environment files
setup_environment() {
    print_status "Setting up environment files..."
    
    # Frontend environment
    if [ ! -f "frontend/.env" ]; then
        cp frontend/env.example frontend/.env
        print_success "Created frontend/.env"
    fi
    
    # Terraform variables
    if [ ! -f "terraform/terraform.tfvars" ]; then
        cp terraform/terraform.tfvars.example terraform/terraform.tfvars
        print_success "Created terraform/terraform.tfvars"
    fi
    
    print_success "Environment files setup completed"
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Frontend dependencies
    print_status "Installing frontend dependencies..."
    cd frontend
    npm install
    cd ..
    
    # .NET dependencies
    print_status "Restoring .NET dependencies..."
    dotnet restore
    
    print_success "Dependencies installed"
}

# Build projects
build_projects() {
    print_status "Building projects..."
    
    # Build .NET projects
    print_status "Building .NET projects..."
    dotnet build --configuration Release
    
    # Build frontend
    print_status "Building frontend..."
    cd frontend
    npm run build
    cd ..
    
    print_success "Projects built successfully"
}

# Start development services
start_services() {
    print_status "Starting development services..."
    
    # Start dependencies (PostgreSQL, RabbitMQ)
    print_status "Starting PostgreSQL and RabbitMQ..."
    docker-compose up postgres rabbitmq -d
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 10
    
    # Check if services are running
    if docker-compose ps | grep -q "Up"; then
        print_success "Dependencies are running"
    else
        print_error "Failed to start dependencies"
        exit 1
    fi
}

# Run tests
run_tests() {
    print_status "Running tests..."
    
    # Run .NET tests
    print_status "Running .NET tests..."
    dotnet test --configuration Release --verbosity normal
    
    # Run frontend tests
    print_status "Running frontend tests..."
    cd frontend
    npm test -- --watchAll=false
    cd ..
    
    print_success "Tests completed"
}

# Show development URLs
show_urls() {
    print_success "🎉 Development environment setup completed!"
    echo ""
    echo "=========================================="
    echo "🌐 Development URLs:"
    echo "=========================================="
    echo "Frontend: http://localhost:3000 (npm start)"
    echo "PaymentService: http://localhost:5001 (dotnet run)"
    echo "NotificationService: http://localhost:5002 (dotnet run)"
    echo "RabbitMQ Management: http://localhost:15672 (admin/admin123)"
    echo "PostgreSQL: localhost:5432 (postgresadmin/admin123)"
    echo ""
    echo "=========================================="
    echo "🛠️  Development Commands:"
    echo "=========================================="
    echo "Start Frontend:"
    echo "  cd frontend && npm start"
    echo ""
    echo "Start PaymentService:"
    echo "  cd src/Services/PaymentService && dotnet run"
    echo ""
    echo "Start NotificationService:"
    echo "  cd src/Services/NotificationService && dotnet run"
    echo ""
    echo "Start all services with Docker:"
    echo "  docker-compose up"
    echo ""
    echo "Run tests:"
    echo "  dotnet test"
    echo "  cd frontend && npm test"
    echo ""
    echo "Stop services:"
    echo "  docker-compose down"
    echo ""
    print_warning "💡 Make sure to start the backend services before the frontend!"
}

# Main setup process
main() {
    echo "=========================================="
    echo "🚀 CI/CD Azure Development Setup"
    echo "=========================================="
    echo ""
    
    check_prerequisites
    setup_environment
    install_dependencies
    build_projects
    start_services
    run_tests
    show_urls
}

# Run main function
main "$@"
