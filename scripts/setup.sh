#!/bin/bash

# CI/CD Azure Microservices Platform Setup Script
# This script sets up the development environment and deploys the infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command_exists az; then
        missing_tools+=("Azure CLI")
    fi
    
    if ! command_exists terraform; then
        missing_tools+=("Terraform")
    fi
    
    if ! command_exists dotnet; then
        missing_tools+=(".NET 8 SDK")
    fi
    
    if ! command_exists docker; then
        missing_tools+=("Docker")
    fi
    
    if ! command_exists kubectl; then
        missing_tools+=("kubectl")
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

# Function to setup Azure authentication
setup_azure_auth() {
    print_status "Setting up Azure authentication..."
    
    # Check if already logged in
    if az account show >/dev/null 2>&1; then
        print_success "Already logged in to Azure"
        return
    fi
    
    print_warning "Please log in to Azure..."
    az login
    
    # Get subscription ID
    local subscription_id
    subscription_id=$(az account show --query id -o tsv)
    
    if [ -z "$subscription_id" ]; then
        print_error "Failed to get Azure subscription ID"
        exit 1
    fi
    
    print_success "Azure authentication completed. Subscription ID: $subscription_id"
}

# Function to setup Terraform
setup_terraform() {
    print_status "Setting up Terraform..."
    
    cd terraform
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Creating from example..."
        cp terraform.tfvars.example terraform.tfvars
        
        print_warning "Please edit terraform.tfvars with your configuration before proceeding."
        print_warning "Press Enter to continue after editing..."
        read -r
    fi
    
    # Initialize Terraform
    terraform init
    
    print_success "Terraform setup completed"
    cd ..
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure..."
    
    cd terraform
    
    # Plan deployment
    print_status "Planning Terraform deployment..."
    terraform plan -var-file="terraform.tfvars"
    
    # Ask for confirmation
    print_warning "Do you want to apply the Terraform plan? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        terraform apply -var-file="terraform.tfvars" -auto-approve
        print_success "Infrastructure deployed successfully"
    else
        print_warning "Infrastructure deployment skipped"
    fi
    
    cd ..
}

# Function to setup local development
setup_local_dev() {
    print_status "Setting up local development environment..."
    
    # Start dependencies
    print_status "Starting PostgreSQL and RabbitMQ..."
    docker-compose up postgres rabbitmq -d
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 10
    
    # Check if services are running
    if docker-compose ps | grep -q "Up"; then
        print_success "Local development environment is ready"
    else
        print_error "Failed to start local development environment"
        exit 1
    fi
}

# Function to build and test applications
build_and_test() {
    print_status "Building and testing applications..."
    
    # Restore dependencies
    dotnet restore
    
    # Build applications
    dotnet build --configuration Release
    
    # Run tests
    dotnet test --configuration Release --verbosity normal
    
    print_success "Build and test completed"
}

# Function to setup Kubernetes
setup_kubernetes() {
    print_status "Setting up Kubernetes..."
    
    # Get AKS credentials
    local resource_group
    local aks_cluster
    
    resource_group=$(cd terraform && terraform output -raw resource_group_name)
    aks_cluster=$(cd terraform && terraform output -raw aks_cluster_name)
    
    if [ -z "$resource_group" ] || [ -z "$aks_cluster" ]; then
        print_error "Failed to get AKS cluster information from Terraform"
        exit 1
    fi
    
    # Get AKS credentials
    az aks get-credentials --resource-group "$resource_group" --name "$aks_cluster" --overwrite-existing
    
    # Verify connection
    if kubectl get nodes >/dev/null 2>&1; then
        print_success "Kubernetes setup completed"
    else
        print_error "Failed to connect to AKS cluster"
        exit 1
    fi
}

# Function to deploy to Kubernetes
deploy_to_kubernetes() {
    print_status "Deploying to Kubernetes..."
    
    # Create secrets
    print_status "Creating Kubernetes secrets..."
    
    local postgres_connection_string
    local application_insights_connection_string
    
    postgres_connection_string=$(cd terraform && terraform output -raw postgres_connection_string)
    application_insights_connection_string=$(cd terraform && terraform output -raw application_insights_connection_string)
    
    # Create secrets for PaymentService
    kubectl create secret generic payment-service-secrets \
        --from-literal=postgres-connection-string="$postgres_connection_string" \
        --from-literal=rabbitmq-connection-string="amqp://admin:admin123@rabbitmq:5672" \
        --from-literal=application-insights-connection-string="$application_insights_connection_string" \
        --from-literal=sendgrid-api-key="your-sendgrid-api-key" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create secrets for NotificationService
    kubectl create secret generic notification-service-secrets \
        --from-literal=postgres-connection-string="$postgres_connection_string" \
        --from-literal=rabbitmq-connection-string="amqp://admin:admin123@rabbitmq:5672" \
        --from-literal=application-insights-connection-string="$application_insights_connection_string" \
        --from-literal=sendgrid-api-key="your-sendgrid-api-key" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy services
    print_status "Deploying services..."
    
    # Deploy RabbitMQ
    kubectl apply -f k8s/rabbitmq-deployment.yaml
    
    # Wait for RabbitMQ
    kubectl wait --for=condition=available --timeout=300s deployment/rabbitmq
    
    # Deploy PaymentService
    kubectl apply -f k8s/payment-service-deployment.yaml
    kubectl apply -f k8s/payment-service-service.yaml
    
    # Deploy NotificationService
    kubectl apply -f k8s/notification-service-deployment.yaml
    kubectl apply -f k8s/notification-service-service.yaml
    
    # Wait for services
    kubectl wait --for=condition=available --timeout=300s deployment/payment-service
    kubectl wait --for=condition=available --timeout=300s deployment/notification-service
    
    print_success "Services deployed to Kubernetes"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check deployments
    kubectl get deployments
    
    # Check services
    kubectl get services
    
    # Check pods
    kubectl get pods
    
    # Test health endpoints
    local payment_service_ip
    local notification_service_ip
    
    payment_service_ip=$(kubectl get service payment-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    notification_service_ip=$(kubectl get service notification-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -n "$payment_service_ip" ]; then
        print_status "Testing PaymentService health endpoint..."
        if curl -f "http://$payment_service_ip/health" >/dev/null 2>&1; then
            print_success "PaymentService is healthy"
        else
            print_warning "PaymentService health check failed"
        fi
    fi
    
    if [ -n "$notification_service_ip" ]; then
        print_status "Testing NotificationService health endpoint..."
        if curl -f "http://$notification_service_ip/health" >/dev/null 2>&1; then
            print_success "NotificationService is healthy"
        else
            print_warning "NotificationService health check failed"
        fi
    fi
    
    print_success "Deployment verification completed"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --check-only     Only check prerequisites"
    echo "  --local-only     Only setup local development"
    echo "  --infra-only     Only deploy infrastructure"
    echo "  --k8s-only       Only deploy to Kubernetes"
    echo "  --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Full setup"
    echo "  $0 --check-only       # Check prerequisites only"
    echo "  $0 --local-only       # Setup local development only"
    echo "  $0 --infra-only       # Deploy infrastructure only"
    echo "  $0 --k8s-only         # Deploy to Kubernetes only"
}

# Main function
main() {
    echo "=========================================="
    echo "CI/CD Azure Microservices Platform Setup"
    echo "=========================================="
    echo ""
    
    # Parse command line arguments
    local check_only=false
    local local_only=false
    local infra_only=false
    local k8s_only=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --check-only)
                check_only=true
                shift
                ;;
            --local-only)
                local_only=true
                shift
                ;;
            --infra-only)
                infra_only=true
                shift
                ;;
            --k8s-only)
                k8s_only=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Execute based on options
    if [ "$check_only" = true ]; then
        check_prerequisites
        exit 0
    fi
    
    if [ "$local_only" = true ]; then
        check_prerequisites
        setup_local_dev
        build_and_test
        exit 0
    fi
    
    if [ "$infra_only" = true ]; then
        check_prerequisites
        setup_azure_auth
        setup_terraform
        deploy_infrastructure
        exit 0
    fi
    
    if [ "$k8s_only" = true ]; then
        check_prerequisites
        setup_azure_auth
        setup_kubernetes
        deploy_to_kubernetes
        verify_deployment
        exit 0
    fi
    
    # Full setup
    check_prerequisites
    setup_azure_auth
    setup_terraform
    deploy_infrastructure
    setup_local_dev
    build_and_test
    setup_kubernetes
    deploy_to_kubernetes
    verify_deployment
    
    print_success "Setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Configure SendGrid API key in Kubernetes secrets"
    echo "2. Update DNS records to point to the load balancer IPs"
    echo "3. Configure GitHub secrets for CI/CD pipeline"
    echo "4. Test the API endpoints"
    echo ""
    echo "For more information, see the documentation in the docs/ folder."
}

# Run main function
main "$@"

