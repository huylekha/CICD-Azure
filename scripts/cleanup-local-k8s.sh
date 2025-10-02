#!/bin/bash

# Cleanup Local Kubernetes Deployment Script
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

print_status "🧹 Cleaning up Local Kubernetes Deployment..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Ask for confirmation
print_warning "This will delete all resources in the 'cicd-demo' namespace. Are you sure? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    print_status "Cleanup cancelled."
    exit 0
fi

# Delete namespace (this will delete all resources in the namespace)
print_status "Deleting namespace 'cicd-demo'..."
kubectl delete namespace cicd-demo --ignore-not-found=true

# Wait for namespace to be deleted
print_status "Waiting for namespace to be deleted..."
while kubectl get namespace cicd-demo &> /dev/null; do
    print_status "Waiting for namespace deletion..."
    sleep 2
done

# Clean up Docker images
print_status "Cleaning up Docker images..."
docker rmi payment-service:local 2>/dev/null || true
docker rmi notification-service:local 2>/dev/null || true
docker rmi frontend:local 2>/dev/null || true

# Clean up Docker system
print_status "Cleaning up Docker system..."
docker system prune -f

print_success "🎉 Local Kubernetes cleanup completed!"
echo ""
echo "=========================================="
echo "✅ Cleanup Summary:"
echo "=========================================="
echo "• Namespace 'cicd-demo' deleted"
echo "• All pods, services, and deployments removed"
echo "• Docker images cleaned up"
echo "• Docker system pruned"
echo ""
print_warning "💡 All local Kubernetes resources have been cleaned up!"
