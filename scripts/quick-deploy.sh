#!/bin/bash

# Quick Deploy Script - Chỉ dùng AKS + ACR (TIẾT KIỆM NHẤT)
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# Variables
RESOURCE_GROUP="cicd-demo-rg"
LOCATION="eastus"
ACR_NAME="cicddemo$(date +%s | tail -c 6)"
AKS_NAME="cicd-demo-aks"

print_status "🚀 Quick Deploy - Student Account Optimized"
print_status "Resource Group: $RESOURCE_GROUP"
print_status "ACR: $ACR_NAME"
print_status "AKS: $AKS_NAME"

# Login to Azure
print_status "Logging in to Azure..."
az login

# Create resource group
print_status "Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create ACR (Basic tier - free)
print_status "Creating Container Registry..."
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $ACR_NAME \
    --sku Basic \
    --admin-enabled true

# Create AKS (minimal config)
print_status "Creating AKS cluster..."
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_NAME \
    --node-count 1 \
    --node-vm-size Standard_B2s \
    --generate-ssh-keys \
    --attach-acr $ACR_NAME

# Get credentials
print_status "Getting AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --overwrite-existing

# Login to ACR
print_status "Logging in to ACR..."
az acr login --name $ACR_NAME

# Build and push images
print_status "Building images..."

# PaymentService
docker build -t $ACR_NAME.azurecr.io/payment-service:latest -f src/Services/PaymentService/Dockerfile .
docker push $ACR_NAME.azurecr.io/payment-service:latest

# NotificationService  
docker build -t $ACR_NAME.azurecr.io/notification-service:latest -f src/Services/NotificationService/Dockerfile .
docker push $ACR_NAME.azurecr.io/notification-service:latest

# Frontend
docker build -t $ACR_NAME.azurecr.io/frontend:latest -f frontend/Dockerfile .
docker push $ACR_NAME.azurecr.io/frontend:latest

# Update deployment files
print_status "Updating deployment files..."
sed -i "s|cicdazure.azurecr.io|$ACR_NAME.azurecr.io|g" k8s/*.yaml

# Deploy to Kubernetes
print_status "Deploying to Kubernetes..."

# Create secrets
kubectl create secret generic payment-service-secrets \
    --from-literal=postgres-connection-string="Host=localhost;Database=microservices;Username=postgres;Password=admin123;Port=5432;" \
    --from-literal=rabbitmq-connection-string="amqp://admin:admin123@rabbitmq:5672" \
    --from-literal=application-insights-connection-string="" \
    --from-literal=sendgrid-api-key="demo-key" \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic notification-service-secrets \
    --from-literal=postgres-connection-string="Host=localhost;Database=microservices;Username=postgres;Password=admin123;Port=5432;" \
    --from-literal=rabbitmq-connection-string="amqp://admin:admin123@rabbitmq:5672" \
    --from-literal=application-insights-connection-string="" \
    --from-literal=sendgrid-api-key="demo-key" \
    --dry-run=client -o yaml | kubectl apply -f -

# Deploy services
kubectl apply -f k8s/rabbitmq-deployment.yaml
kubectl apply -f k8s/payment-service-deployment.yaml
kubectl apply -f k8s/payment-service-service.yaml
kubectl apply -f k8s/notification-service-deployment.yaml
kubectl apply -f k8s/notification-service-service.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml

# Wait for services
print_status "Waiting for services to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/rabbitmq
kubectl wait --for=condition=available --timeout=300s deployment/payment-service
kubectl wait --for=condition=available --timeout=300s deployment/notification-service
kubectl wait --for=condition=available --timeout=300s deployment/frontend

# Get service URLs
print_status "Getting service URLs..."
FRONTEND_IP=$(kubectl get service frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")
PAYMENT_IP=$(kubectl get service payment-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")

print_success "🎉 Deployment completed!"
echo ""
echo "=========================================="
echo "🌐 Your Demo URLs:"
echo "=========================================="
echo "Frontend Dashboard: http://$FRONTEND_IP"
echo "Payment API: http://$PAYMENT_IP"
echo ""
echo "📊 Check status:"
echo "kubectl get services"
echo "kubectl get pods"
echo ""
echo "🗑️  To cleanup (delete everything):"
echo "az group delete --name $RESOURCE_GROUP --yes --no-wait"
echo ""
print_warning "💡 This setup costs ~$5-10/month for student account"
