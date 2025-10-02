#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Deploy CI/CD Azure Microservices to Azure (Student Account Optimized)

.DESCRIPTION
    This script deploys the entire stack to Azure with cost-optimized settings for student accounts.
    
.PARAMETER ResourceGroup
    Name of the Azure Resource Group (default: rg-cicd-azure-demo)
    
.PARAMETER Location
    Azure region (default: eastus)
    
.PARAMETER SkipInfrastructure
    Skip Terraform infrastructure deployment
    
.PARAMETER SkipBuild
    Skip building Docker images
    
.PARAMETER SkipDeploy
    Skip deploying to Azure
#>

param(
    [string]$ResourceGroup = "rg-cicd-azure-demo",
    [string]$Location = "eastus",
    [switch]$SkipInfrastructure,
    [switch]$SkipBuild,
    [switch]$SkipDeploy
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================="
Write-Host "🚀 Azure Deployment (Student Account)"
Write-Host "=========================================="
Write-Host ""

# Check prerequisites
Write-Host "📋 Checking prerequisites..."

# Check Azure CLI
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Azure CLI not found. Please install: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
}

# Check Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker not found. Please install Docker Desktop"
    exit 1
}

Write-Host "✅ Prerequisites check passed"
Write-Host ""

# Login to Azure
Write-Host "🔐 Checking Azure login..."
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Please login to Azure..."
    az login
    $account = az account show | ConvertFrom-Json
}

Write-Host "✅ Logged in as: $($account.user.name)"
Write-Host "✅ Subscription: $($account.name)"
Write-Host ""

# Confirm deployment
Write-Host "⚠️  Deployment Settings:"
Write-Host "  Resource Group: $ResourceGroup"
Write-Host "  Location: $Location"
Write-Host "  Subscription: $($account.name)"
Write-Host ""

$confirm = Read-Host "Continue with deployment? (y/n)"
if ($confirm -ne 'y') {
    Write-Host "Deployment cancelled"
    exit 0
}

Write-Host ""

# Step 1: Create Resource Group
if (-not $SkipInfrastructure) {
    Write-Host "=========================================="
    Write-Host "📦 Step 1: Creating Resource Group"
    Write-Host "=========================================="
    
    $rgExists = az group exists --name $ResourceGroup
    if ($rgExists -eq "false") {
        Write-Host "Creating resource group: $ResourceGroup in $Location..."
        az group create --name $ResourceGroup --location $Location
        Write-Host "✅ Resource group created"
    } else {
        Write-Host "✅ Resource group already exists"
    }
    Write-Host ""
}

# Step 2: Create Container Registry
if (-not $SkipInfrastructure) {
    Write-Host "=========================================="
    Write-Host "📦 Step 2: Creating Azure Container Registry"
    Write-Host "=========================================="
    
    $acrName = "acrcicdazure" + (Get-Random -Maximum 9999)
    
    Write-Host "Creating ACR: $acrName (Basic SKU for student account)..."
    az acr create `
        --resource-group $ResourceGroup `
        --name $acrName `
        --sku Basic `
        --admin-enabled true
    
    Write-Host "✅ ACR created: $acrName"
    
    # Get ACR credentials
    $acrServer = az acr show --name $acrName --resource-group $ResourceGroup --query "loginServer" -o tsv
    $acrUsername = az acr credential show --name $acrName --resource-group $ResourceGroup --query "username" -o tsv
    $acrPassword = az acr credential show --name $acrName --resource-group $ResourceGroup --query "passwords[0].value" -o tsv
    
    Write-Host "✅ ACR Server: $acrServer"
    Write-Host ""
}

# Step 3: Build and Push Docker Images
if (-not $SkipBuild) {
    Write-Host "=========================================="
    Write-Host "🔨 Step 3: Building Docker Images"
    Write-Host "=========================================="
    
    # Login to ACR
    Write-Host "Logging into ACR..."
    az acr login --name $acrName
    
    # Build PaymentService
    Write-Host "`n📦 Building PaymentService..."
    docker build -t "${acrServer}/payment-service:latest" -f src/Services/PaymentService/Dockerfile .
    docker push "${acrServer}/payment-service:latest"
    Write-Host "✅ PaymentService pushed"
    
    # Build Frontend
    Write-Host "`n📦 Building Frontend..."
    docker build -t "${acrServer}/frontend:latest" -f frontend/Dockerfile ./frontend
    docker push "${acrServer}/frontend:latest"
    Write-Host "✅ Frontend pushed"
    
    Write-Host ""
}

# Step 4: Create Azure Container Instances (Cost-effective for demo)
if (-not $SkipDeploy) {
    Write-Host "=========================================="
    Write-Host "🚀 Step 4: Deploying to Azure Container Instances"
    Write-Host "=========================================="
    
    # Deploy PaymentService
    Write-Host "`n📦 Deploying PaymentService..."
    az container create `
        --resource-group $ResourceGroup `
        --name payment-service `
        --image "${acrServer}/payment-service:latest" `
        --cpu 1 `
        --memory 1 `
        --registry-login-server $acrServer `
        --registry-username $acrUsername `
        --registry-password $acrPassword `
        --dns-name-label "payment-service-$(Get-Random -Maximum 9999)" `
        --ports 80 `
        --environment-variables `
            ASPNETCORE_URLS=http://+:80
    
    $paymentServiceFqdn = az container show `
        --resource-group $ResourceGroup `
        --name payment-service `
        --query "ipAddress.fqdn" -o tsv
    
    Write-Host "✅ PaymentService deployed: http://${paymentServiceFqdn}"
    
    # Deploy Frontend
    Write-Host "`n📦 Deploying Frontend..."
    az container create `
        --resource-group $ResourceGroup `
        --name frontend `
        --image "${acrServer}/frontend:latest" `
        --cpu 1 `
        --memory 1 `
        --registry-login-server $acrServer `
        --registry-username $acrUsername `
        --registry-password $acrPassword `
        --dns-name-label "frontend-$(Get-Random -Maximum 9999)" `
        --ports 80 `
        --environment-variables `
            REACT_APP_API_URL="http://${paymentServiceFqdn}"
    
    $frontendFqdn = az container show `
        --resource-group $ResourceGroup `
        --name frontend `
        --query "ipAddress.fqdn" -o tsv
    
    Write-Host "✅ Frontend deployed: http://${frontendFqdn}"
    Write-Host ""
}

# Summary
Write-Host "=========================================="
Write-Host "✅ Deployment Complete!"
Write-Host "=========================================="
Write-Host ""
Write-Host "📊 Resource Summary:"
Write-Host "  Resource Group: $ResourceGroup"
Write-Host "  Container Registry: $acrName"
Write-Host "  PaymentService: http://${paymentServiceFqdn}"
Write-Host "  Frontend: http://${frontendFqdn}"
Write-Host ""
Write-Host "🌐 Access Your Application:"
Write-Host "  Frontend UI: http://${frontendFqdn}"
Write-Host "  Swagger API: http://${paymentServiceFqdn}/swagger"
Write-Host "  API Demo: http://${paymentServiceFqdn}/api/demo/accounts"
Write-Host ""
Write-Host "💰 Cost Optimization:"
Write-Host "  - Using Azure Container Instances (pay-per-second)"
Write-Host "  - Basic SKU Container Registry"
Write-Host "  - 1 CPU / 1 GB RAM per container"
Write-Host "  - Estimated cost: ~$5-10/month"
Write-Host ""
Write-Host "🗑️  Cleanup (when done):"
Write-Host "  az group delete --name $ResourceGroup --yes --no-wait"
Write-Host ""
Write-Host "=========================================="

