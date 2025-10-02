#!/bin/bash

# Cleanup Script - Xóa tất cả resources để tránh chi phí
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

print_status "🧹 Starting cleanup process..."

# Function to cleanup local resources
cleanup_local() {
    print_status "Cleaning up local resources..."
    
    # Stop and remove docker containers
    if command -v docker-compose &> /dev/null; then
        print_status "Stopping docker-compose services..."
        docker-compose down -v
        print_success "Docker services stopped"
    fi
    
    # Remove docker images
    print_status "Removing docker images..."
    docker rmi $(docker images -q --filter "reference=*payment-service*") 2>/dev/null || true
    docker rmi $(docker images -q --filter "reference=*notification-service*") 2>/dev/null || true
    docker rmi $(docker images -q --filter "reference=*frontend*") 2>/dev/null || true
    docker rmi $(docker images -q --filter "reference=*cicd*") 2>/dev/null || true
    
    # Clean up docker system
    docker system prune -f
    
    print_success "Local cleanup completed"
}

# Function to cleanup Azure resources
cleanup_azure() {
    print_status "Cleaning up Azure resources..."
    
    # Check if logged in to Azure
    if ! az account show &> /dev/null; then
        print_warning "Not logged in to Azure. Skipping Azure cleanup."
        return
    fi
    
    # List resource groups that might contain our resources
    RESOURCE_GROUPS=(
        "cicd-azure-dev-rg"
        "cicd-azure-student-rg"
        "cicd-demo-rg"
        "cicd-azure-rg"
    )
    
    for rg in "${RESOURCE_GROUPS[@]}"; do
        if az group exists --name "$rg" --output tsv | grep -q "true"; then
            print_status "Deleting resource group: $rg"
            az group delete --name "$rg" --yes --no-wait
            print_success "Resource group $rg deletion initiated"
        else
            print_status "Resource group $rg does not exist"
        fi
    done
    
    # Clean up any remaining ACR repositories
    print_status "Cleaning up ACR repositories..."
    ACR_NAMES=$(az acr list --query "[?contains(name, 'cicd')].name" -o tsv 2>/dev/null || true)
    
    if [ -n "$ACR_NAMES" ]; then
        for acr in $ACR_NAMES; do
            print_status "Deleting ACR: $acr"
            az acr delete --name "$acr" --yes 2>/dev/null || true
        done
    fi
    
    print_success "Azure cleanup completed"
}

# Function to cleanup Kubernetes resources
cleanup_kubernetes() {
    print_status "Cleaning up Kubernetes resources..."
    
    if command -v kubectl &> /dev/null; then
        # Delete all deployments
        kubectl delete deployment --all --ignore-not-found=true
        kubectl delete service --all --ignore-not-found=true
        kubectl delete secret --all --ignore-not-found=true
        kubectl delete configmap --all --ignore-not-found=true
        kubectl delete ingress --all --ignore-not-found=true
        
        print_success "Kubernetes resources cleaned up"
    else
        print_warning "kubectl not found. Skipping Kubernetes cleanup."
    fi
}

# Function to show cost summary
show_cost_summary() {
    print_status "Checking current Azure costs..."
    
    if az account show &> /dev/null; then
        # Get current month's usage
        CURRENT_MONTH=$(date +%Y-%m)
        
        print_status "Current month usage for $CURRENT_MONTH:"
        az consumption usage list \
            --billing-period-name "$CURRENT_MONTH-1" \
            --query "[].{Resource:instanceName, Cost:pretaxCost, Currency:currency}" \
            --output table 2>/dev/null || print_warning "Could not retrieve cost information"
    fi
}

# Main cleanup process
main() {
    echo "=========================================="
    echo "🧹 CI/CD Azure Cleanup Script"
    echo "=========================================="
    echo ""
    
    # Ask for confirmation
    print_warning "This will delete ALL resources and data. Are you sure? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_status "Cleanup cancelled."
        exit 0
    fi
    
    # Cleanup local resources
    cleanup_local
    
    # Cleanup Kubernetes resources
    cleanup_kubernetes
    
    # Cleanup Azure resources
    cleanup_azure
    
    # Show cost summary
    show_cost_summary
    
    print_success "🎉 Cleanup completed!"
    echo ""
    echo "=========================================="
    echo "✅ Cleanup Summary:"
    echo "=========================================="
    echo "• Local Docker containers and images removed"
    echo "• Kubernetes resources deleted"
    echo "• Azure resource groups deleted"
    echo "• ACR repositories deleted"
    echo ""
    print_warning "💡 Remember to check your Azure portal to ensure all resources are deleted"
    print_warning "💡 Monitor your Azure billing to confirm no unexpected charges"
}

# Run main function
main "$@"
