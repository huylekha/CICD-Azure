#!/bin/bash

# Test Local Kubernetes Deployment Script
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

print_status "🧪 Testing Local Kubernetes Deployment..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if namespace exists
if ! kubectl get namespace cicd-demo &> /dev/null; then
    print_error "Namespace 'cicd-demo' does not exist. Please run deploy-local-k8s.sh first."
    exit 1
fi

# Get service ports
print_status "Getting service ports..."
FRONTEND_PORT=$(kubectl get service frontend -n cicd-demo -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30000")
PAYMENT_PORT=$(kubectl get service payment-service -n cicd-demo -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30001")
NOTIFICATION_PORT=$(kubectl get service notification-service -n cicd-demo -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30002")
RABBITMQ_PORT=$(kubectl get service rabbitmq -n cicd-demo -o jsonpath='{.spec.ports[1].nodePort}' 2>/dev/null || echo "30003")

print_status "Service ports:"
echo "  Frontend: $FRONTEND_PORT"
echo "  PaymentService: $PAYMENT_PORT"
echo "  NotificationService: $NOTIFICATION_PORT"
echo "  RabbitMQ: $RABBITMQ_PORT"

# Test health endpoints
print_status "Testing health endpoints..."

# Test PaymentService
print_status "Testing PaymentService health..."
if curl -f "http://localhost:$PAYMENT_PORT/health" >/dev/null 2>&1; then
    print_success "PaymentService is healthy"
else
    print_warning "PaymentService health check failed"
fi

# Test NotificationService
print_status "Testing NotificationService health..."
if curl -f "http://localhost:$NOTIFICATION_PORT/health" >/dev/null 2>&1; then
    print_success "NotificationService is healthy"
else
    print_warning "NotificationService health check failed"
fi

# Test Frontend
print_status "Testing Frontend..."
if curl -f "http://localhost:$FRONTEND_PORT" >/dev/null 2>&1; then
    print_success "Frontend is accessible"
else
    print_warning "Frontend is not accessible"
fi

# Test API endpoints
print_status "Testing API endpoints..."

# Test get accounts
print_status "Testing get accounts API..."
if curl -f "http://localhost:$PAYMENT_PORT/api/account" >/dev/null 2>&1; then
    print_success "Get accounts API is working"
else
    print_warning "Get accounts API failed"
fi

# Test get transactions
print_status "Testing get transactions API..."
if curl -f "http://localhost:$PAYMENT_PORT/api/transaction" >/dev/null 2>&1; then
    print_success "Get transactions API is working"
else
    print_warning "Get transactions API failed"
fi

# Test transfer money (mock)
print_status "Testing transfer money API..."
TRANSFER_RESPONSE=$(curl -s -X POST "http://localhost:$PAYMENT_PORT/api/payment/transfer" \
  -H "Content-Type: application/json" \
  -d '{
    "fromAccountId": "550e8400-e29b-41d4-a716-446655440001",
    "toAccountId": "550e8400-e29b-41d4-a716-446655440002",
    "amount": 100,
    "currency": "USD",
    "description": "Test transfer"
  }' 2>/dev/null || echo "failed")

if [[ "$TRANSFER_RESPONSE" != "failed" ]]; then
    print_success "Transfer money API is working"
    echo "Response: $TRANSFER_RESPONSE"
else
    print_warning "Transfer money API failed"
fi

# Check pod status
print_status "Checking pod status..."
kubectl get pods -n cicd-demo

# Check service status
print_status "Checking service status..."
kubectl get services -n cicd-demo

# Show logs for any failed pods
print_status "Checking for failed pods..."
FAILED_PODS=$(kubectl get pods -n cicd-demo --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers 2>/dev/null || true)

if [ -n "$FAILED_PODS" ]; then
    print_warning "Found failed pods:"
    echo "$FAILED_PODS"
    
    print_status "Showing logs for failed pods..."
    echo "$FAILED_PODS" | while read -r pod; do
        POD_NAME=$(echo "$pod" | awk '{print $1}')
        print_status "Logs for $POD_NAME:"
        kubectl logs "$POD_NAME" -n cicd-demo --tail=10
    done
fi

print_success "🎉 Testing completed!"
echo ""
echo "=========================================="
echo "🌐 Test Results:"
echo "=========================================="
echo "Frontend: http://localhost:$FRONTEND_PORT"
echo "PaymentService: http://localhost:$PAYMENT_PORT"
echo "NotificationService: http://localhost:$NOTIFICATION_PORT"
echo "RabbitMQ Management: http://localhost:$RABBITMQ_PORT (admin/admin123)"
echo ""
echo "=========================================="
echo "🧪 Manual Testing:"
echo "=========================================="
echo "1. Open http://localhost:$FRONTEND_PORT in browser"
echo "2. Go to 'Transfer Money' page"
echo "3. Select accounts and amount"
echo "4. Click 'Transfer Money'"
echo "5. Check 'Transactions' page for results"
echo ""
echo "=========================================="
echo "📝 View Logs:"
echo "=========================================="
echo "kubectl logs -f deployment/frontend -n cicd-demo"
echo "kubectl logs -f deployment/payment-service -n cicd-demo"
echo "kubectl logs -f deployment/notification-service -n cicd-demo"
echo ""
print_warning "💡 All services should be running in local Kubernetes!"
