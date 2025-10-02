#!/bin/bash

# Deploy Script for Azure Student Account - TIẾT KIỆM TỐI ĐA
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    print_warning "Not logged in to Azure. Please log in..."
    az login
fi

# Get subscription info
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

print_status "Using subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# Check if this is a student subscription
if [[ "$SUBSCRIPTION_NAME" == *"Student"* ]] || [[ "$SUBSCRIPTION_NAME" == *"student"* ]]; then
    print_success "Student subscription detected! Using cost-optimized configuration."
else
    print_warning "This doesn't appear to be a student subscription. Costs may be higher."
fi

# Set variables for student deployment
RESOURCE_GROUP="cicd-azure-student-rg"
LOCATION="eastus"
ACR_NAME="cicdazurestudent$(date +%s | tail -c 6)"  # Unique name
AKS_NAME="cicd-azure-student-aks"

print_status "Resource Group: $RESOURCE_GROUP"
print_status "Location: $LOCATION"
print_status "ACR Name: $ACR_NAME"
print_status "AKS Name: $AKS_NAME"

# Create resource group
print_status "Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create ACR (Container Registry) - Free tier
print_status "Creating Azure Container Registry..."
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $ACR_NAME \
    --sku Basic \
    --admin-enabled true

# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query loginServer -o tsv)
print_success "ACR created: $ACR_LOGIN_SERVER"

# Create AKS cluster with minimal configuration
print_status "Creating AKS cluster (this may take 10-15 minutes)..."
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_NAME \
    --node-count 1 \
    --node-vm-size Standard_B2s \
    --enable-addons monitoring \
    --generate-ssh-keys \
    --attach-acr $ACR_NAME

# Get AKS credentials
print_status "Getting AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --overwrite-existing

# Verify cluster
print_status "Verifying AKS cluster..."
kubectl get nodes

# Build and push images
print_status "Building and pushing Docker images..."

# Login to ACR
az acr login --name $ACR_NAME

# Build and push PaymentService
print_status "Building PaymentService..."
docker build -t $ACR_LOGIN_SERVER/payment-service:latest -f src/Services/PaymentService/Dockerfile .
docker push $ACR_LOGIN_SERVER/payment-service:latest

# Build and push NotificationService
print_status "Building NotificationService..."
docker build -t $ACR_LOGIN_SERVER/notification-service:latest -f src/Services/NotificationService/Dockerfile .
docker push $ACR_LOGIN_SERVER/notification-service:latest

# Build and push Frontend
print_status "Building Frontend..."
docker build -t $ACR_LOGIN_SERVER/frontend:latest -f frontend/Dockerfile .
docker push $ACR_LOGIN_SERVER/frontend:latest

# Create Kubernetes secrets
print_status "Creating Kubernetes secrets..."
kubectl create secret generic payment-service-secrets \
    --from-literal=postgres-connection-string="Host=localhost;Database=microservices;Username=postgres;Password=admin123;Port=5432;" \
    --from-literal=rabbitmq-connection-string="amqp://admin:admin123@rabbitmq:5672" \
    --from-literal=application-insights-connection-string="" \
    --from-literal=sendgrid-api-key="your-sendgrid-api-key" \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic notification-service-secrets \
    --from-literal=postgres-connection-string="Host=localhost;Database=microservices;Username=postgres;Password=admin123;Port=5432;" \
    --from-literal=rabbitmq-connection-string="amqp://admin:admin123@rabbitmq:5672" \
    --from-literal=application-insights-connection-string="" \
    --from-literal=sendgrid-api-key="your-sendgrid-api-key" \
    --dry-run=client -o yaml | kubectl apply -f -

# Deploy services
print_status "Deploying services to AKS..."

# Update image references in deployment files
sed -i "s|cicdazure.azurecr.io|$ACR_LOGIN_SERVER|g" k8s/*.yaml

# Deploy RabbitMQ
kubectl apply -f k8s/rabbitmq-deployment.yaml

# Wait for RabbitMQ
print_status "Waiting for RabbitMQ to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/rabbitmq

# Deploy PaymentService
kubectl apply -f k8s/payment-service-deployment.yaml
kubectl apply -f k8s/payment-service-service.yaml

# Deploy NotificationService
kubectl apply -f k8s/notification-service-deployment.yaml
kubectl apply -f k8s/notification-service-service.yaml

# Deploy Frontend
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml

# Wait for services
print_status "Waiting for services to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/payment-service
kubectl wait --for=condition=available --timeout=300s deployment/notification-service
kubectl wait --for=condition=available --timeout=300s deployment/frontend

# Get service URLs
print_status "Getting service URLs..."
PAYMENT_SERVICE_IP=$(kubectl get service payment-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")
NOTIFICATION_SERVICE_IP=$(kubectl get service notification-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")
FRONTEND_IP=$(kubectl get service frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")

print_success "Deployment completed!"
echo ""
echo "=========================================="
echo "🎉 DEPLOYMENT SUCCESSFUL!"
echo "=========================================="
echo ""
echo "Service URLs:"
echo "Frontend: http://$FRONTEND_IP"
echo "Payment Service: http://$PAYMENT_SERVICE_IP"
echo "Notification Service: http://$NOTIFICATION_SERVICE_IP"
echo ""
echo "To check service status:"
echo "kubectl get services"
echo "kubectl get pods"
echo ""
echo "To view logs:"
echo "kubectl logs deployment/payment-service"
echo "kubectl logs deployment/notification-service"
echo "kubectl logs deployment/frontend"
echo ""
echo "To delete everything (when done testing):"
echo "az group delete --name $RESOURCE_GROUP --yes --no-wait"
echo ""
print_warning "Remember to delete resources when done to avoid charges!"
