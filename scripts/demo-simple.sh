#!/bin/bash

# Simple Demo Script - Chỉ chạy frontend với mock data
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

print_status "🚀 Starting Simple Demo..."

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Start only PostgreSQL and RabbitMQ
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

# Build and start frontend
print_status "Building and starting frontend..."
cd frontend
npm install
npm run build

# Start frontend with serve
if command -v serve &> /dev/null; then
    print_status "Starting frontend with serve..."
    serve -s build -l 3000 &
    FRONTEND_PID=$!
else
    print_status "Installing serve globally..."
    npm install -g serve
    serve -s build -l 3000 &
    FRONTEND_PID=$!
fi

cd ..

print_success "🎉 Simple Demo started!"
echo ""
echo "=========================================="
echo "🌐 Demo URLs:"
echo "=========================================="
echo "Frontend: http://localhost:3000"
echo "RabbitMQ Management: http://localhost:15672 (admin/admin123)"
echo "PostgreSQL: localhost:5432 (postgresadmin/admin123)"
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
echo "Note: This is a frontend-only demo with mock data"
echo "Backend services are not running"
echo ""
echo "=========================================="
echo "🛑 Stop Demo:"
echo "=========================================="
echo "kill $FRONTEND_PID"
echo "docker-compose down"
echo ""
print_warning "💡 Frontend demo is running with mock data!"
