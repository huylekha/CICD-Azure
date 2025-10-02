# Windows PowerShell Setup Script
# CI/CD Azure Microservices Platform

param(
    [switch]$QuickDeploy,
    [switch]$DevSetup,
    [switch]$Cleanup,
    [switch]$Help
)

# Colors
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"

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

function Show-Help {
    Write-Host "=========================================="
    Write-Host "🚀 CI/CD Azure Microservices Platform"
    Write-Host "=========================================="
    Write-Host ""
    Write-Host "Available commands:"
    Write-Host "  -QuickDeploy  - Deploy to Azure (student optimized)"
    Write-Host "  -DevSetup    - Setup development environment"
    Write-Host "  -Cleanup     - Clean up all resources"
    Write-Host "  -Help        - Show this help"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\setup-windows.ps1 -QuickDeploy"
    Write-Host "  .\setup-windows.ps1 -DevSetup"
    Write-Host "  .\setup-windows.ps1 -Cleanup"
}

function Test-Prerequisites {
    Write-Status "Checking prerequisites..."
    
    $missingTools = @()
    
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        $missingTools += "Azure CLI"
    }
    
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        $missingTools += "Docker"
    }
    
    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
        $missingTools += ".NET 8 SDK"
    }
    
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        $missingTools += "Node.js"
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

function Start-QuickDeploy {
    Write-Status "🚀 Starting quick deploy to Azure..."
    
    # Check Azure login
    try {
        $account = az account show 2>$null | ConvertFrom-Json
        if (-not $account) {
            Write-Warning "Please log in to Azure..."
            az login
        }
    }
    catch {
        Write-Error "Failed to authenticate with Azure"
        exit 1
    }
    
    # Set variables
    $resourceGroup = "cicd-demo-rg"
    $location = "eastus"
    $acrName = "cicddemo$(Get-Date -Format 'yyyyMMddHHmm')"
    $aksName = "cicd-demo-aks"
    
    Write-Status "Resource Group: $resourceGroup"
    Write-Status "ACR: $acrName"
    Write-Status "AKS: $aksName"
    
    # Create resource group
    Write-Status "Creating resource group..."
    az group create --name $resourceGroup --location $location
    
    # Create ACR
    Write-Status "Creating Container Registry..."
    az acr create --resource-group $resourceGroup --name $acrName --sku Basic --admin-enabled true
    
    # Create AKS
    Write-Status "Creating AKS cluster..."
    az aks create --resource-group $resourceGroup --name $aksName --node-count 1 --node-vm-size Standard_B2s --generate-ssh-keys --attach-acr $acrName
    
    # Get credentials
    Write-Status "Getting AKS credentials..."
    az aks get-credentials --resource-group $resourceGroup --name $aksName --overwrite-existing
    
    # Login to ACR
    Write-Status "Logging in to ACR..."
    az acr login --name $acrName
    
    # Build and push images
    Write-Status "Building and pushing images..."
    
    # PaymentService
    docker build -t "$acrName.azurecr.io/payment-service:latest" -f src/Services/PaymentService/Dockerfile .
    docker push "$acrName.azurecr.io/payment-service:latest"
    
    # NotificationService
    docker build -t "$acrName.azurecr.io/notification-service:latest" -f src/Services/NotificationService/Dockerfile .
    docker push "$acrName.azurecr.io/notification-service:latest"
    
    # Frontend
    docker build -t "$acrName.azurecr.io/frontend:latest" -f frontend/Dockerfile .
    docker push "$acrName.azurecr.io/frontend:latest"
    
    # Update deployment files
    Write-Status "Updating deployment files..."
    (Get-Content k8s/*.yaml) -replace 'cicdazure.azurecr.io', "$acrName.azurecr.io" | Set-Content k8s/*.yaml
    
    # Deploy to Kubernetes
    Write-Status "Deploying to Kubernetes..."
    
    # Create secrets
    kubectl create secret generic payment-service-secrets --from-literal=postgres-connection-string="Host=localhost;Database=microservices;Username=postgres;Password=admin123;Port=5432;" --from-literal=rabbitmq-connection-string="amqp://admin:admin123@rabbitmq:5672" --from-literal=application-insights-connection-string="" --from-literal=sendgrid-api-key="demo-key" --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl create secret generic notification-service-secrets --from-literal=postgres-connection-string="Host=localhost;Database=microservices;Username=postgres;Password=admin123;Port=5432;" --from-literal=rabbitmq-connection-string="amqp://admin:admin123@rabbitmq:5672" --from-literal=application-insights-connection-string="" --from-literal=sendgrid-api-key="demo-key" --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy services
    kubectl apply -f k8s/rabbitmq-deployment.yaml
    kubectl apply -f k8s/payment-service-deployment.yaml
    kubectl apply -f k8s/payment-service-service.yaml
    kubectl apply -f k8s/notification-service-deployment.yaml
    kubectl apply -f k8s/notification-service-service.yaml
    kubectl apply -f k8s/frontend-deployment.yaml
    kubectl apply -f k8s/frontend-service.yaml
    
    # Wait for services
    Write-Status "Waiting for services to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/rabbitmq
    kubectl wait --for=condition=available --timeout=300s deployment/payment-service
    kubectl wait --for=condition=available --timeout=300s deployment/notification-service
    kubectl wait --for=condition=available --timeout=300s deployment/frontend
    
    # Get service URLs
    Write-Status "Getting service URLs..."
    $frontendIp = kubectl get service frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    $paymentIp = kubectl get service payment-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    
    Write-Success "🎉 Deployment completed!"
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "🌐 Your Demo URLs:"
    Write-Host "=========================================="
    Write-Host "Frontend Dashboard: http://$frontendIp"
    Write-Host "Payment API: http://$paymentIp"
    Write-Host ""
    Write-Host "📊 Check status:"
    Write-Host "kubectl get services"
    Write-Host "kubectl get pods"
    Write-Host ""
    Write-Host "🗑️  To cleanup (delete everything):"
    Write-Host "az group delete --name $resourceGroup --yes --no-wait"
    Write-Host ""
    Write-Warning "💡 This setup costs ~$5-10/month for student account"
}

function Start-DevSetup {
    Write-Status "🛠️ Setting up development environment..."
    
    # Check prerequisites
    Test-Prerequisites
    
    # Setup environment files
    if (-not (Test-Path "frontend/.env")) {
        Copy-Item "frontend/env.example" "frontend/.env"
        Write-Success "Created frontend/.env"
    }
    
    if (-not (Test-Path "terraform/terraform.tfvars")) {
        Copy-Item "terraform/terraform.tfvars.example" "terraform/terraform.tfvars"
        Write-Success "Created terraform/terraform.tfvars"
    }
    
    # Install dependencies
    Write-Status "Installing dependencies..."
    dotnet restore
    Set-Location frontend
    npm install
    Set-Location ..
    
    # Build projects
    Write-Status "Building projects..."
    dotnet build --configuration Release
    Set-Location frontend
    npm run build
    Set-Location ..
    
    # Start dependencies
    Write-Status "Starting dependencies..."
    docker-compose up postgres rabbitmq -d
    
    # Wait for services
    Start-Sleep -Seconds 10
    
    Write-Success "🎉 Development environment setup completed!"
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "🌐 Development URLs:"
    Write-Host "=========================================="
    Write-Host "Frontend: http://localhost:3000 (npm start)"
    Write-Host "PaymentService: http://localhost:5001 (dotnet run)"
    Write-Host "NotificationService: http://localhost:5002 (dotnet run)"
    Write-Host "RabbitMQ Management: http://localhost:15672 (admin/admin123)"
    Write-Host "PostgreSQL: localhost:5432 (postgresadmin/admin123)"
    Write-Host ""
    Write-Host "🛠️  Development Commands:"
    Write-Host "Start Frontend: cd frontend && npm start"
    Write-Host "Start PaymentService: cd src/Services/PaymentService && dotnet run"
    Write-Host "Start NotificationService: cd src/Services/NotificationService && dotnet run"
    Write-Host "Start all services: docker-compose up"
    Write-Host ""
    Write-Warning "💡 Make sure to start the backend services before the frontend!"
}

function Start-Cleanup {
    Write-Status "🧹 Starting cleanup process..."
    
    # Ask for confirmation
    Write-Warning "This will delete ALL resources and data. Are you sure? (y/N)"
    $response = Read-Host
    if ($response -notmatch "^[Yy]$") {
        Write-Status "Cleanup cancelled."
        exit 0
    }
    
    # Cleanup local resources
    Write-Status "Cleaning up local resources..."
    if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
        docker-compose down -v
        Write-Success "Docker services stopped"
    }
    
    # Remove docker images
    Write-Status "Removing docker images..."
    docker rmi $(docker images -q --filter "reference=*payment-service*") 2>$null
    docker rmi $(docker images -q --filter "reference=*notification-service*") 2>$null
    docker rmi $(docker images -q --filter "reference=*frontend*") 2>$null
    docker rmi $(docker images -q --filter "reference=*cicd*") 2>$null
    docker system prune -f
    
    # Cleanup Azure resources
    Write-Status "Cleaning up Azure resources..."
    if (Get-Command az -ErrorAction SilentlyContinue) {
        try {
            $account = az account show 2>$null | ConvertFrom-Json
            if ($account) {
                $resourceGroups = @("cicd-azure-dev-rg", "cicd-azure-student-rg", "cicd-demo-rg", "cicd-azure-rg")
                foreach ($rg in $resourceGroups) {
                    if (az group exists --name $rg --output tsv | Select-String "true") {
                        Write-Status "Deleting resource group: $rg"
                        az group delete --name $rg --yes --no-wait
                        Write-Success "Resource group $rg deletion initiated"
                    }
                }
            }
        }
        catch {
            Write-Warning "Could not cleanup Azure resources"
        }
    }
    
    # Cleanup Kubernetes resources
    Write-Status "Cleaning up Kubernetes resources..."
    if (Get-Command kubectl -ErrorAction SilentlyContinue) {
        kubectl delete deployment --all --ignore-not-found=true
        kubectl delete service --all --ignore-not-found=true
        kubectl delete secret --all --ignore-not-found=true
        kubectl delete configmap --all --ignore-not-found=true
        kubectl delete ingress --all --ignore-not-found=true
        Write-Success "Kubernetes resources cleaned up"
    }
    
    Write-Success "🎉 Cleanup completed!"
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "✅ Cleanup Summary:"
    Write-Host "=========================================="
    Write-Host "• Local Docker containers and images removed"
    Write-Host "• Kubernetes resources deleted"
    Write-Host "• Azure resource groups deleted"
    Write-Host ""
    Write-Warning "💡 Remember to check your Azure portal to ensure all resources are deleted"
    Write-Warning "💡 Monitor your Azure billing to confirm no unexpected charges"
}

# Main function
function Main {
    Write-Host "=========================================="
    Write-Host "🚀 CI/CD Azure Microservices Platform"
    Write-Host "=========================================="
    Write-Host ""
    
    if ($Help) {
        Show-Help
        exit 0
    }
    
    if ($QuickDeploy) {
        Start-QuickDeploy
    }
    elseif ($DevSetup) {
        Start-DevSetup
    }
    elseif ($Cleanup) {
        Start-Cleanup
    }
    else {
        Show-Help
    }
}

# Run main function
Main
