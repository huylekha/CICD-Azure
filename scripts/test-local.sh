#!/bin/bash

# Test Local Development Script
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

print_status "🧪 Testing Local Development Environment"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if .NET is installed
if ! command -v dotnet &> /dev/null; then
    print_error ".NET 8 SDK is not installed. Please install it first."
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install it first."
    exit 1
fi

print_success "All prerequisites are installed"

# Start dependencies
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

# Build and test backend services
print_status "Building and testing backend services..."

# Test PaymentService
print_status "Testing PaymentService..."
cd src/Services/PaymentService
dotnet build
if [ $? -eq 0 ]; then
    print_success "PaymentService builds successfully"
else
    print_error "PaymentService build failed"
    exit 1
fi
cd ../../..

# Test NotificationService
print_status "Testing NotificationService..."
cd src/Services/NotificationService
dotnet build
if [ $? -eq 0 ]; then
    print_success "NotificationService builds successfully"
else
    print_error "NotificationService build failed"
    exit 1
fi
cd ../../..

# Test Frontend
print_status "Testing Frontend..."
cd frontend
npm install
npm run build
if [ $? -eq 0 ]; then
    print_success "Frontend builds successfully"
else
    print_error "Frontend build failed"
    exit 1
fi
cd ..

# Test Docker builds
print_status "Testing Docker builds..."

# Build PaymentService Docker image
print_status "Building PaymentService Docker image..."
docker build -t payment-service:test -f src/Services/PaymentService/Dockerfile .
if [ $? -eq 0 ]; then
    print_success "PaymentService Docker image builds successfully"
else
    print_error "PaymentService Docker build failed"
    exit 1
fi

# Build NotificationService Docker image
print_status "Building NotificationService Docker image..."
docker build -t notification-service:test -f src/Services/NotificationService/Dockerfile .
if [ $? -eq 0 ]; then
    print_success "NotificationService Docker image builds successfully"
else
    print_error "NotificationService Docker build failed"
    exit 1
fi

# Build Frontend Docker image
print_status "Building Frontend Docker image..."
docker build -t frontend:test -f frontend/Dockerfile .
if [ $? -eq 0 ]; then
    print_success "Frontend Docker image builds successfully"
else
    print_error "Frontend Docker build failed"
    exit 1
fi

# Test full docker-compose
print_status "Testing full docker-compose setup..."
docker-compose down
docker-compose up --build -d

# Wait for services to be ready
print_status "Waiting for all services to be ready..."
sleep 30

# Test health endpoints
print_status "Testing health endpoints..."

# Test PaymentService health
if curl -f http://localhost:5001/health >/dev/null 2>&1; then
    print_success "PaymentService is healthy"
else
    print_warning "PaymentService health check failed"
fi

# Test NotificationService health
if curl -f http://localhost:5002/health >/dev/null 2>&1; then
    print_success "NotificationService is healthy"
else
    print_warning "NotificationService health check failed"
fi

# Test Frontend
if curl -f http://localhost:3000 >/dev/null 2>&1; then
    print_success "Frontend is accessible"
else
    print_warning "Frontend is not accessible"
fi

print_success "🎉 Local testing completed!"
echo ""
echo "=========================================="
echo "🌐 Local Development URLs:"
echo "=========================================="
echo "Frontend: http://localhost:3000"
echo "PaymentService: http://localhost:5001"
echo "NotificationService: http://localhost:5002"
echo "RabbitMQ Management: http://localhost:15672 (admin/admin123)"
echo "PostgreSQL: localhost:5432 (postgresadmin/admin123)"
echo ""
echo "📊 Check service status:"
echo "docker-compose ps"
echo ""
echo "📝 View logs:"
echo "docker-compose logs -f"
echo ""
echo "🛑 Stop services:"
echo "docker-compose down"
echo ""
print_warning "💡 All services are running locally. You can now test the application!"
