# Deploy to Local Kubernetes (Docker Desktop) - PowerShell Script
param(
    [switch]$Test,
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
    Write-Host "🚀 Local Kubernetes Deployment Script"
    Write-Host "=========================================="
    Write-Host ""
    Write-Host "Available commands:"
    Write-Host "  (no params) - Deploy to local Kubernetes"
    Write-Host "  -Test       - Test the deployment"
    Write-Host "  -Cleanup    - Clean up the deployment"
    Write-Host "  -Help       - Show this help"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\deploy-local-k8s.ps1"
    Write-Host "  .\deploy-local-k8s.ps1 -Test"
    Write-Host "  .\deploy-local-k8s.ps1 -Cleanup"
}

function Test-Prerequisites {
    Write-Status "Checking prerequisites..."
    
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Error "kubectl is not installed. Please install kubectl first."
        exit 1
    }
    
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker is not installed. Please install Docker first."
        exit 1
    }
    
    # Check if Docker is running
    try {
        docker info | Out-Null
    }
    catch {
        Write-Error "Docker is not running. Please start Docker first."
        exit 1
    }
    
    # Check Kubernetes context
    $currentContext = kubectl config current-context
    if ($currentContext -ne "docker-desktop") {
        Write-Warning "Current context is: $currentContext"
        Write-Warning "Switching to docker-desktop context..."
        kubectl config use-context docker-desktop
    }
    
    Write-Success "Using Kubernetes context: $(kubectl config current-context)"
}

function Start-Deployment {
    Write-Status "🚀 Starting Local Kubernetes Deployment..."
    
    # Check prerequisites
    Test-Prerequisites
    
    # Build Docker images
    Write-Status "Building Docker images..."
    
    # Build PaymentService
    Write-Status "Building PaymentService..."
    docker build -t payment-service:local -f src/Services/PaymentService/Dockerfile .
    Write-Success "PaymentService image built"
    
    # Build NotificationService
    Write-Status "Building NotificationService..."
    docker build -t notification-service:local -f src/Services/NotificationService/Dockerfile .
    Write-Success "NotificationService image built"
    
    # Build Frontend
    Write-Status "Building Frontend..."
    docker build -t frontend:local -f frontend/Dockerfile .
    Write-Success "Frontend image built"
    
    # Create namespace
    Write-Status "Creating namespace..."
    kubectl create namespace cicd-demo --dry-run=client -o yaml | kubectl apply -f -
    
    # Create secrets
    Write-Status "Creating secrets..."
    kubectl create secret generic payment-service-secrets `
        --from-literal=postgres-connection-string="Host=postgres;Database=microservices;Username=postgresadmin;Password=admin123;Port=5432;" `
        --from-literal=rabbitmq-connection-string="amqp://admin:admin123@rabbitmq:5672" `
        --from-literal=application-insights-connection-string="" `
        --from-literal=sendgrid-api-key="demo-key" `
        --namespace=cicd-demo `
        --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl create secret generic notification-service-secrets `
        --from-literal=postgres-connection-string="Host=postgres;Database=microservices;Username=postgresadmin;Password=admin123;Port=5432;" `
        --from-literal=rabbitmq-connection-string="amqp://admin:admin123@rabbitmq:5672" `
        --from-literal=application-insights-connection-string="" `
        --from-literal=sendgrid-api-key="demo-key" `
        --namespace=cicd-demo `
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy PostgreSQL
    Write-Status "Deploying PostgreSQL..."
    kubectl apply -f k8s/postgres-deployment.yaml -n cicd-demo
    
    # Deploy RabbitMQ
    Write-Status "Deploying RabbitMQ..."
    kubectl apply -f k8s/rabbitmq-deployment.yaml -n cicd-demo
    
    # Wait for databases to be ready
    Write-Status "Waiting for databases to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/postgres -n cicd-demo
    kubectl wait --for=condition=available --timeout=300s deployment/rabbitmq -n cicd-demo
    
    # Deploy PaymentService
    Write-Status "Deploying PaymentService..."
    kubectl apply -f k8s/payment-service-deployment.yaml -n cicd-demo
    
    # Deploy NotificationService
    Write-Status "Deploying NotificationService..."
    kubectl apply -f k8s/notification-service-deployment.yaml -n cicd-demo
    
    # Deploy Frontend
    Write-Status "Deploying Frontend..."
    kubectl apply -f k8s/frontend-deployment.yaml -n cicd-demo
    
    # Wait for services to be ready
    Write-Status "Waiting for services to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/payment-service -n cicd-demo
    kubectl wait --for=condition=available --timeout=300s deployment/notification-service -n cicd-demo
    kubectl wait --for=condition=available --timeout=300s deployment/frontend -n cicd-demo
    
    # Get service URLs
    Write-Status "Getting service URLs..."
    $frontendPort = kubectl get service frontend -n cicd-demo -o jsonpath='{.spec.ports[0].nodePort}'
    $paymentPort = kubectl get service payment-service -n cicd-demo -o jsonpath='{.spec.ports[0].nodePort}'
    $notificationPort = kubectl get service notification-service -n cicd-demo -o jsonpath='{.spec.ports[0].nodePort}'
    $rabbitmqPort = kubectl get service rabbitmq -n cicd-demo -o jsonpath='{.spec.ports[1].nodePort}'
    
    Write-Success "🎉 Deployment completed!"
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "🌐 Local Kubernetes Demo URLs:"
    Write-Host "=========================================="
    Write-Host "Frontend Dashboard: http://localhost:$frontendPort"
    Write-Host "PaymentService API: http://localhost:$paymentPort"
    Write-Host "NotificationService API: http://localhost:$notificationPort"
    Write-Host "RabbitMQ Management: http://localhost:$rabbitmqPort (admin/admin123)"
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "📊 Check Status:"
    Write-Host "=========================================="
    Write-Host "kubectl get pods -n cicd-demo"
    Write-Host "kubectl get services -n cicd-demo"
    Write-Host "kubectl get deployments -n cicd-demo"
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "🧪 Test Demo:"
    Write-Host "=========================================="
    Write-Host "1. Open http://localhost:$frontendPort"
    Write-Host "2. Go to 'Transfer Money' page"
    Write-Host "3. Select accounts and amount"
    Write-Host "4. Click 'Transfer Money'"
    Write-Host "5. Check 'Transactions' page for results"
    Write-Host ""
    Write-Warning "💡 All services are running in local Kubernetes!"
}

function Start-Test {
    Write-Status "🧪 Testing Local Kubernetes Deployment..."
    
    # Check if namespace exists
    if (-not (kubectl get namespace cicd-demo -ErrorAction SilentlyContinue)) {
        Write-Error "Namespace 'cicd-demo' does not exist. Please run deployment first."
        exit 1
    }
    
    # Get service ports
    Write-Status "Getting service ports..."
    $frontendPort = kubectl get service frontend -n cicd-demo -o jsonpath='{.spec.ports[0].nodePort}' 2>$null
    $paymentPort = kubectl get service payment-service -n cicd-demo -o jsonpath='{.spec.ports[0].nodePort}' 2>$null
    $notificationPort = kubectl get service notification-service -n cicd-demo -o jsonpath='{.spec.ports[0].nodePort}' 2>$null
    $rabbitmqPort = kubectl get service rabbitmq -n cicd-demo -o jsonpath='{.spec.ports[1].nodePort}' 2>$null
    
    Write-Host "Service ports:"
    Write-Host "  Frontend: $frontendPort"
    Write-Host "  PaymentService: $paymentPort"
    Write-Host "  NotificationService: $notificationPort"
    Write-Host "  RabbitMQ: $rabbitmqPort"
    
    # Test health endpoints
    Write-Status "Testing health endpoints..."
    
    # Test PaymentService
    Write-Status "Testing PaymentService health..."
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$paymentPort/health" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Success "PaymentService is healthy"
        }
    }
    catch {
        Write-Warning "PaymentService health check failed"
    }
    
    # Test NotificationService
    Write-Status "Testing NotificationService health..."
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$notificationPort/health" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Success "NotificationService is healthy"
        }
    }
    catch {
        Write-Warning "NotificationService health check failed"
    }
    
    # Test Frontend
    Write-Status "Testing Frontend..."
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$frontendPort" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Success "Frontend is accessible"
        }
    }
    catch {
        Write-Warning "Frontend is not accessible"
    }
    
    # Check pod status
    Write-Status "Checking pod status..."
    kubectl get pods -n cicd-demo
    
    # Check service status
    Write-Status "Checking service status..."
    kubectl get services -n cicd-demo
    
    Write-Success "🎉 Testing completed!"
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "🌐 Test Results:"
    Write-Host "=========================================="
    Write-Host "Frontend: http://localhost:$frontendPort"
    Write-Host "PaymentService: http://localhost:$paymentPort"
    Write-Host "NotificationService: http://localhost:$notificationPort"
    Write-Host "RabbitMQ Management: http://localhost:$rabbitmqPort (admin/admin123)"
    Write-Host ""
    Write-Warning "💡 All services should be running in local Kubernetes!"
}

function Start-Cleanup {
    Write-Status "🧹 Cleaning up Local Kubernetes Deployment..."
    
    # Ask for confirmation
    Write-Warning "This will delete all resources in the 'cicd-demo' namespace. Are you sure? (y/N)"
    $response = Read-Host
    if ($response -notmatch "^[Yy]$") {
        Write-Status "Cleanup cancelled."
        exit 0
    }
    
    # Delete namespace
    Write-Status "Deleting namespace 'cicd-demo'..."
    kubectl delete namespace cicd-demo --ignore-not-found=true
    
    # Wait for namespace to be deleted
    Write-Status "Waiting for namespace to be deleted..."
    while (kubectl get namespace cicd-demo -ErrorAction SilentlyContinue) {
        Write-Status "Waiting for namespace deletion..."
        Start-Sleep -Seconds 2
    }
    
    # Clean up Docker images
    Write-Status "Cleaning up Docker images..."
    docker rmi payment-service:local 2>$null
    docker rmi notification-service:local 2>$null
    docker rmi frontend:local 2>$null
    
    # Clean up Docker system
    Write-Status "Cleaning up Docker system..."
    docker system prune -f
    
    Write-Success "🎉 Local Kubernetes cleanup completed!"
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "✅ Cleanup Summary:"
    Write-Host "=========================================="
    Write-Host "• Namespace 'cicd-demo' deleted"
    Write-Host "• All pods, services, and deployments removed"
    Write-Host "• Docker images cleaned up"
    Write-Host "• Docker system pruned"
    Write-Host ""
    Write-Warning "💡 All local Kubernetes resources have been cleaned up!"
}

# Main function
function Main {
    Write-Host "=========================================="
    Write-Host "🚀 Local Kubernetes Deployment Script"
    Write-Host "=========================================="
    Write-Host ""
    
    if ($Help) {
        Show-Help
        exit 0
    }
    
    if ($Test) {
        Start-Test
    }
    elseif ($Cleanup) {
        Start-Cleanup
    }
    else {
        Start-Deployment
    }
}

# Run main function
Main
