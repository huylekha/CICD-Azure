#!/bin/bash

# Deploy to Local Kubernetes (Docker Desktop) Script
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

print_status "🚀 Deploying to Local Kubernetes (Docker Desktop)..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if Kubernetes context is docker-desktop
CURRENT_CONTEXT=$(kubectl config current-context)
if [[ "$CURRENT_CONTEXT" != "docker-desktop" ]]; then
    print_warning "Current context is: $CURRENT_CONTEXT"
    print_warning "Switching to docker-desktop context..."
    kubectl config use-context docker-desktop
fi

print_success "Using Kubernetes context: $(kubectl config current-context)"

# Build Docker images
print_status "Building Docker images..."

# Build PaymentService
print_status "Building PaymentService..."
docker build -t payment-service:local -f src/Services/PaymentService/Dockerfile .
print_success "PaymentService image built"

# Build NotificationService
print_status "Building NotificationService..."
docker build -t notification-service:local -f src/Services/NotificationService/Dockerfile .
print_success "NotificationService image built"

# Build Frontend
print_status "Building Frontend..."
docker build -t frontend:local -f frontend/Dockerfile .
print_success "Frontend image built"

# Create namespace
print_status "Creating namespace..."
kubectl create namespace cicd-demo --dry-run=client -o yaml | kubectl apply -f -

# Create secrets
print_status "Creating secrets..."
kubectl create secret generic payment-service-secrets \
    --from-literal=postgres-connection-string="Host=postgres;Database=microservices;Username=postgresadmin;Password=admin123;Port=5432;" \
    --from-literal=rabbitmq-connection-string="amqp://admin:admin123@rabbitmq:5672" \
    --from-literal=application-insights-connection-string="" \
    --from-literal=sendgrid-api-key="demo-key" \
    --namespace=cicd-demo \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic notification-service-secrets \
    --from-literal=postgres-connection-string="Host=postgres;Database=microservices;Username=postgresadmin;Password=admin123;Port=5432;" \
    --from-literal=rabbitmq-connection-string="amqp://admin:admin123@rabbitmq:5672" \
    --from-literal=application-insights-connection-string="" \
    --from-literal=sendgrid-api-key="demo-key" \
    --namespace=cicd-demo \
    --dry-run=client -o yaml | kubectl apply -f -

# Deploy PostgreSQL
print_status "Deploying PostgreSQL..."
kubectl apply -f k8s/postgres-deployment.yaml -n cicd-demo

# Deploy RabbitMQ
print_status "Deploying RabbitMQ..."
kubectl apply -f k8s/rabbitmq-deployment.yaml -n cicd-demo

# Wait for databases to be ready
print_status "Waiting for databases to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n cicd-demo
kubectl wait --for=condition=available --timeout=300s deployment/rabbitmq -n cicd-demo

# Deploy PaymentService
print_status "Deploying PaymentService..."
kubectl apply -f k8s/payment-service-deployment.yaml -n cicd-demo
kubectl apply -f k8s/payment-service-service.yaml -n cicd-demo

# Deploy NotificationService
print_status "Deploying NotificationService..."
kubectl apply -f k8s/notification-service-deployment.yaml -n cicd-demo
kubectl apply -f k8s/notification-service-service.yaml -n cicd-demo

# Deploy Frontend
print_status "Deploying Frontend..."
kubectl apply -f k8s/frontend-deployment.yaml -n cicd-demo
kubectl apply -f k8s/frontend-service.yaml -n cicd-demo

# Wait for services to be ready
print_status "Waiting for services to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/payment-service -n cicd-demo
kubectl wait --for=condition=available --timeout=300s deployment/notification-service -n cicd-demo
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n cicd-demo

# Get service URLs
print_status "Getting service URLs..."
FRONTEND_PORT=$(kubectl get service frontend -n cicd-demo -o jsonpath='{.spec.ports[0].nodePort}')
PAYMENT_PORT=$(kubectl get service payment-service -n cicd-demo -o jsonpath='{.spec.ports[0].nodePort}')
NOTIFICATION_PORT=$(kubectl get service notification-service -n cicd-demo -o jsonpath='{.spec.ports[0].nodePort}')
RABBITMQ_PORT=$(kubectl get service rabbitmq -n cicd-demo -o jsonpath='{.spec.ports[1].nodePort}')

print_success "🎉 Deployment completed!"
echo ""
echo "=========================================="
echo "🌐 Local Kubernetes Demo URLs:"
echo "=========================================="
echo "Frontend Dashboard: http://localhost:$FRONTEND_PORT"
echo "PaymentService API: http://localhost:$PAYMENT_PORT"
echo "NotificationService API: http://localhost:$NOTIFICATION_PORT"
echo "RabbitMQ Management: http://localhost:$RABBITMQ_PORT (admin/admin123)"
echo ""
echo "=========================================="
echo "📊 Check Status:"
echo "=========================================="
echo "kubectl get pods -n cicd-demo"
echo "kubectl get services -n cicd-demo"
echo "kubectl get deployments -n cicd-demo"
echo ""
echo "=========================================="
echo "📝 View Logs:"
echo "=========================================="
echo "kubectl logs -f deployment/frontend -n cicd-demo"
echo "kubectl logs -f deployment/payment-service -n cicd-demo"
echo "kubectl logs -f deployment/notification-service -n cicd-demo"
echo ""
echo "=========================================="
echo "🧪 Test Demo:"
echo "=========================================="
echo "1. Open http://localhost:$FRONTEND_PORT"
echo "2. Go to 'Transfer Money' page"
echo "3. Select accounts and amount"
echo "4. Click 'Transfer Money'"
echo "5. Check 'Transactions' page for results"
echo ""
echo "=========================================="
echo "🗑️  Cleanup:"
echo "=========================================="
echo "kubectl delete namespace cicd-demo"
echo ""
print_warning "💡 All services are running in local Kubernetes!"
