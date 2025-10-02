# CI/CD Azure Microservices Platform Setup Script (PowerShell)
# This script sets up the development environment and deploys the infrastructure

param(
    [switch]$CheckOnly,
    [switch]$LocalOnly,
    [switch]$InfraOnly,
    [switch]$K8sOnly,
    [switch]$Help
)

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Red
}

# Function to check if command exists
function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-Status "Checking prerequisites..."
    
    $missingTools = @()
    
    if (-not (Test-Command "az")) {
        $missingTools += "Azure CLI"
    }
    
    if (-not (Test-Command "terraform")) {
        $missingTools += "Terraform"
    }
    
    if (-not (Test-Command "dotnet")) {
        $missingTools += ".NET 8 SDK"
    }
    
    if (-not (Test-Command "docker")) {
        $missingTools += "Docker"
    }
    
    if (-not (Test-Command "kubectl")) {
        $missingTools += "kubectl"
    }
    
    if ($missingTools.Count -gt 0) {
        Write-Error "Missing required tools:"
        foreach ($tool in $missingTools) {
            Write-Host "  - $tool"
        }
        Write-Host ""
        Write-Host "Please install the missing tools and run this script again."
        exit 1
    }
    
    Write-Success "All prerequisites are installed"
}

# Function to setup Azure authentication
function Set-AzureAuth {
    Write-Status "Setting up Azure authentication..."
    
    # Check if already logged in
    try {
        $account = az account show 2>$null | ConvertFrom-Json
        if ($account) {
            Write-Success "Already logged in to Azure"
            return
        }
    }
    catch {
        # Not logged in, continue
    }
    
    Write-Warning "Please log in to Azure..."
    az login
    
    # Get subscription ID
    try {
        $subscriptionId = az account show --query id -o tsv
        if (-not $subscriptionId) {
            Write-Error "Failed to get Azure subscription ID"
            exit 1
        }
        Write-Success "Azure authentication completed. Subscription ID: $subscriptionId"
    }
    catch {
        Write-Error "Failed to authenticate with Azure"
        exit 1
    }
}

# Function to setup Terraform
function Set-Terraform {
    Write-Status "Setting up Terraform..."
    
    Set-Location terraform
    
    # Check if terraform.tfvars exists
    if (-not (Test-Path "terraform.tfvars")) {
        Write-Warning "terraform.tfvars not found. Creating from example..."
        Copy-Item "terraform.tfvars.example" "terraform.tfvars"
        
        Write-Warning "Please edit terraform.tfvars with your configuration before proceeding."
        Write-Warning "Press Enter to continue after editing..."
        Read-Host
    }
    
    # Initialize Terraform
    terraform init
    
    Write-Success "Terraform setup completed"
    Set-Location ..
}

# Function to deploy infrastructure
function Deploy-Infrastructure {
    Write-Status "Deploying infrastructure..."
    
    Set-Location terraform
    
    # Plan deployment
    Write-Status "Planning Terraform deployment..."
    terraform plan -var-file="terraform.tfvars"
    
    # Ask for confirmation
    $response = Read-Host "Do you want to apply the Terraform plan? (y/N)"
    if ($response -match "^[Yy]$") {
        terraform apply -var-file="terraform.tfvars" -auto-approve
        Write-Success "Infrastructure deployed successfully"
    }
    else {
        Write-Warning "Infrastructure deployment skipped"
    }
    
    Set-Location ..
}

# Function to setup local development
function Set-LocalDev {
    Write-Status "Setting up local development environment..."
    
    # Start dependencies
    Write-Status "Starting PostgreSQL and RabbitMQ..."
    docker-compose up postgres rabbitmq -d
    
    # Wait for services to be ready
    Write-Status "Waiting for services to be ready..."
    Start-Sleep -Seconds 10
    
    # Check if services are running
    $services = docker-compose ps
    if ($services -match "Up") {
        Write-Success "Local development environment is ready"
    }
    else {
        Write-Error "Failed to start local development environment"
        exit 1
    }
}

# Function to build and test applications
function Build-Test {
    Write-Status "Building and testing applications..."
    
    # Restore dependencies
    dotnet restore
    
    # Build applications
    dotnet build --configuration Release
    
    # Run tests
    dotnet test --configuration Release --verbosity normal
    
    Write-Success "Build and test completed"
}

# Function to setup Kubernetes
function Set-Kubernetes {
    Write-Status "Setting up Kubernetes..."
    
    # Get AKS credentials
    Set-Location terraform
    $resourceGroup = terraform output -raw resource_group_name
    $aksCluster = terraform output -raw aks_cluster_name
    Set-Location ..
    
    if (-not $resourceGroup -or -not $aksCluster) {
        Write-Error "Failed to get AKS cluster information from Terraform"
        exit 1
    }
    
    # Get AKS credentials
    az aks get-credentials --resource-group $resourceGroup --name $aksCluster --overwrite-existing
    
    # Verify connection
    try {
        kubectl get nodes | Out-Null
        Write-Success "Kubernetes setup completed"
    }
    catch {
        Write-Error "Failed to connect to AKS cluster"
        exit 1
    }
}

# Function to deploy to Kubernetes
function Deploy-Kubernetes {
    Write-Status "Deploying to Kubernetes..."
    
    # Create secrets
    Write-Status "Creating Kubernetes secrets..."
    
    Set-Location terraform
    $postgresConnectionString = terraform output -raw postgres_connection_string
    $applicationInsightsConnectionString = terraform output -raw application_insights_connection_string
    Set-Location ..
    
    # Create secrets for PaymentService
    kubectl create secret generic payment-service-secrets `
        --from-literal=postgres-connection-string="$postgresConnectionString" `
        --from-literal=rabbitmq-connection-string="amqp://admin:admin123@rabbitmq:5672" `
        --from-literal=application-insights-connection-string="$applicationInsightsConnectionString" `
        --from-literal=sendgrid-api-key="your-sendgrid-api-key" `
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create secrets for NotificationService
    kubectl create secret generic notification-service-secrets `
        --from-literal=postgres-connection-string="$postgresConnectionString" `
        --from-literal=rabbitmq-connection-string="amqp://admin:admin123@rabbitmq:5672" `
        --from-literal=application-insights-connection-string="$applicationInsightsConnectionString" `
        --from-literal=sendgrid-api-key="your-sendgrid-api-key" `
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy services
    Write-Status "Deploying services..."
    
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
    
    Write-Success "Services deployed to Kubernetes"
}

# Function to verify deployment
function Test-Deployment {
    Write-Status "Verifying deployment..."
    
    # Check deployments
    kubectl get deployments
    
    # Check services
    kubectl get services
    
    # Check pods
    kubectl get pods
    
    # Test health endpoints
    try {
        $paymentServiceIp = kubectl get service payment-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
        if ($paymentServiceIp) {
            Write-Status "Testing PaymentService health endpoint..."
            try {
                Invoke-WebRequest -Uri "http://$paymentServiceIp/health" -UseBasicParsing | Out-Null
                Write-Success "PaymentService is healthy"
            }
            catch {
                Write-Warning "PaymentService health check failed"
            }
        }
    }
    catch {
        Write-Warning "Could not get PaymentService IP"
    }
    
    try {
        $notificationServiceIp = kubectl get service notification-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
        if ($notificationServiceIp) {
            Write-Status "Testing NotificationService health endpoint..."
            try {
                Invoke-WebRequest -Uri "http://$notificationServiceIp/health" -UseBasicParsing | Out-Null
                Write-Success "NotificationService is healthy"
            }
            catch {
                Write-Warning "NotificationService health check failed"
            }
        }
    }
    catch {
        Write-Warning "Could not get NotificationService IP"
    }
    
    Write-Success "Deployment verification completed"
}

# Function to show usage
function Show-Usage {
    Write-Host "Usage: .\setup.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -CheckOnly     Only check prerequisites"
    Write-Host "  -LocalOnly     Only setup local development"
    Write-Host "  -InfraOnly     Only deploy infrastructure"
    Write-Host "  -K8sOnly       Only deploy to Kubernetes"
    Write-Host "  -Help          Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\setup.ps1                    # Full setup"
    Write-Host "  .\setup.ps1 -CheckOnly         # Check prerequisites only"
    Write-Host "  .\setup.ps1 -LocalOnly         # Setup local development only"
    Write-Host "  .\setup.ps1 -InfraOnly         # Deploy infrastructure only"
    Write-Host "  .\setup.ps1 -K8sOnly           # Deploy to Kubernetes only"
}

# Main function
function Main {
    Write-Host "=========================================="
    Write-Host "CI/CD Azure Microservices Platform Setup"
    Write-Host "=========================================="
    Write-Host ""
    
    # Show help if requested
    if ($Help) {
        Show-Usage
        exit 0
    }
    
    # Execute based on options
    if ($CheckOnly) {
        Test-Prerequisites
        exit 0
    }
    
    if ($LocalOnly) {
        Test-Prerequisites
        Set-LocalDev
        Build-Test
        exit 0
    }
    
    if ($InfraOnly) {
        Test-Prerequisites
        Set-AzureAuth
        Set-Terraform
        Deploy-Infrastructure
        exit 0
    }
    
    if ($K8sOnly) {
        Test-Prerequisites
        Set-AzureAuth
        Set-Kubernetes
        Deploy-Kubernetes
        Test-Deployment
        exit 0
    }
    
    # Full setup
    Test-Prerequisites
    Set-AzureAuth
    Set-Terraform
    Deploy-Infrastructure
    Set-LocalDev
    Build-Test
    Set-Kubernetes
    Deploy-Kubernetes
    Test-Deployment
    
    Write-Success "Setup completed successfully!"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Configure SendGrid API key in Kubernetes secrets"
    Write-Host "2. Update DNS records to point to the load balancer IPs"
    Write-Host "3. Configure GitHub secrets for CI/CD pipeline"
    Write-Host "4. Test the API endpoints"
    Write-Host ""
    Write-Host "For more information, see the documentation in the docs/ folder."
}

# Run main function
Main

