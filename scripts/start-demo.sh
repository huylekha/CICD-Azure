#!/bin/bash

# Demo Script - Start Backend và Frontend để test
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

print_status "🚀 Starting Demo Environment..."

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

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

# Build projects
print_status "Building projects..."
dotnet build --configuration Release

# Build frontend
print_status "Building frontend..."
cd frontend
npm install
npm run build
cd ..

print_success "🎉 Demo environment ready!"
echo ""
echo "=========================================="
echo "🌐 Demo URLs:"
echo "=========================================="
echo "Frontend: http://localhost:3000"
echo "PaymentService: http://localhost:5001"
echo "NotificationService: http://localhost:5002"
echo "RabbitMQ Management: http://localhost:15672 (admin/admin123)"
echo "PostgreSQL: localhost:5432 (postgresadmin/admin123)"
echo ""
echo "=========================================="
echo "🛠️  Start Services:"
echo "=========================================="
echo "1. Start PaymentService:"
echo "   cd src/Services/PaymentService && dotnet run"
echo ""
echo "2. Start NotificationService (in another terminal):"
echo "   cd src/Services/NotificationService && dotnet run"
echo ""
echo "3. Start Frontend (in another terminal):"
echo "   cd frontend && npm start"
echo ""
echo "=========================================="
echo "🧪 Test Demo:"
echo "=========================================="
echo "1. Open http://localhost:3000"
echo "2. Go to 'Transfer Money' page"
echo "3. Select accounts and amount"
echo "4. Click 'Transfer Money'"
echo "5. Check 'Transactions' page for results"
echo ""
print_warning "💡 Make sure to start all services before testing!"
