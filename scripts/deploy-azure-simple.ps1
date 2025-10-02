#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Simple Azure deployment using Azure App Service (Student Account)
    
.DESCRIPTION
    Deploys backend and frontend to Azure App Service with Free/Basic tier
#>

param(
    [string]$ResourceGroup = "rg-cicd-demo",
    [string]$Location = "eastus",
    [string]$AppServicePlan = "asp-cicd-demo"
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================="
Write-Host "🚀 Simple Azure Deployment (App Service)"
Write-Host "=========================================="
Write-Host ""

# Check Azure CLI
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Azure CLI not found"
    exit 1
}

# Login check
Write-Host "🔐 Checking Azure login..."
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    az login
    $account = az account show | ConvertFrom-Json
}

Write-Host "✅ Logged in: $($account.user.name)"
Write-Host ""

# Create Resource Group
Write-Host "📦 Creating Resource Group..."
az group create --name $ResourceGroup --location $Location --output none
Write-Host "✅ Resource Group: $ResourceGroup"
Write-Host ""

# Create App Service Plan (Free tier)
Write-Host "📦 Creating App Service Plan (Free tier)..."
az appservice plan create `
    --name $AppServicePlan `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku F1 `
    --is-linux `
    --output none

Write-Host "✅ App Service Plan: $AppServicePlan"
Write-Host ""

# Create Web App for Backend
Write-Host "📦 Creating Web App for Backend..."
$backendAppName = "payment-api-$(Get-Random -Maximum 9999)"

az webapp create `
    --name $backendAppName `
    --resource-group $ResourceGroup `
    --plan $AppServicePlan `
    --runtime "DOTNETCORE:8.0" `
    --output none

# Configure backend
az webapp config appsettings set `
    --name $backendAppName `
    --resource-group $ResourceGroup `
    --settings `
        ASPNETCORE_ENVIRONMENT=Production `
        WEBSITES_PORT=80 `
    --output none

$backendUrl = "https://${backendAppName}.azurewebsites.net"
Write-Host "✅ Backend: $backendUrl"
Write-Host ""

# Create Web App for Frontend
Write-Host "📦 Creating Web App for Frontend..."
$frontendAppName = "payment-web-$(Get-Random -Maximum 9999)"

az webapp create `
    --name $frontendAppName `
    --resource-group $ResourceGroup `
    --plan $AppServicePlan `
    --runtime "NODE:18-lts" `
    --output none

# Configure frontend
az webapp config appsettings set `
    --name $frontendAppName `
    --resource-group $ResourceGroup `
    --settings `
        REACT_APP_API_URL=$backendUrl `
        WEBSITE_NODE_DEFAULT_VERSION="18-lts" `
    --output none

$frontendUrl = "https://${frontendAppName}.azurewebsites.net"
Write-Host "✅ Frontend: $frontendUrl"
Write-Host ""

# Deploy Backend
Write-Host "🚀 Deploying Backend..."
Push-Location src/Services/PaymentService
dotnet publish -c Release -o ./publish
Compress-Archive -Path ./publish/* -DestinationPath ../../../backend.zip -Force
Pop-Location

az webapp deployment source config-zip `
    --name $backendAppName `
    --resource-group $ResourceGroup `
    --src backend.zip `
    --output none

Remove-Item backend.zip -Force
Write-Host "✅ Backend deployed"
Write-Host ""

# Deploy Frontend
Write-Host "🚀 Deploying Frontend..."
Push-Location frontend
npm install
npm run build
Compress-Archive -Path ./build/* -DestinationPath ../frontend.zip -Force
Pop-Location

az webapp deployment source config-zip `
    --name $frontendAppName `
    --resource-group $ResourceGroup `
    --src frontend.zip `
    --output none

Remove-Item frontend.zip -Force
Write-Host "✅ Frontend deployed"
Write-Host ""

# Summary
Write-Host "=========================================="
Write-Host "✅ Deployment Complete!"
Write-Host "=========================================="
Write-Host ""
Write-Host "🌐 Your Application:"
Write-Host "  Frontend: $frontendUrl"
Write-Host "  Backend API: $backendUrl/swagger"
Write-Host "  Demo API: $backendUrl/api/demo/accounts"
Write-Host ""
Write-Host "💰 Cost: FREE (F1 tier)"
Write-Host ""
Write-Host "🗑️  Cleanup:"
Write-Host "  az group delete --name $ResourceGroup --yes --no-wait"
Write-Host ""
Write-Host "=========================================="

