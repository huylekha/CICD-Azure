# 🚀 Azure Deployment Guide (Student Account)

Hướng dẫn deploy CI/CD Azure Microservices lên Azure với tài khoản sinh viên.

## 📋 Prerequisites

### 1. Azure Student Account
- Đăng ký tại: https://azure.microsoft.com/free/students/
- Credit: $100 USD (miễn phí)
- Không cần thẻ tín dụng

### 2. Required Tools
```powershell
# Azure CLI
winget install Microsoft.AzureCLI

# Docker Desktop (if using Container deployment)
winget install Docker.DockerDesktop

# .NET 8 SDK
winget install Microsoft.DotNet.SDK.8

# Node.js
winget install OpenJS.NodeJS
```

## 🎯 Deployment Options

### **Option 1: Azure App Service (Recommended for Students)**
✅ **FREE tier available**  
✅ **No Docker required**  
✅ **Easy deployment**  
✅ **Good for demos**

**Cost**: $0/month (Free tier)

```powershell
# Run deployment
.\scripts\deploy-azure-simple.ps1
```

### **Option 2: Azure Container Instances**
✅ **Pay-per-second**  
✅ **Docker-based**  
✅ **Flexible**  
⚠️ **~$5-10/month**

```powershell
# Run deployment
.\scripts\deploy-azure-student.ps1
```

### **Option 3: Full AKS (Not recommended for students)**
❌ **Expensive (~$70+/month)**  
❌ **Complex setup**  
✅ **Production-grade**

## 📦 Option 1: Quick Deploy with App Service (FREE)

### Step 1: Login to Azure
```powershell
# Login
az login

# Verify account
az account show
```

### Step 2: Run Deployment Script
```powershell
# Navigate to project root
cd D:\Azure\CICD-Azure

# Run simple deployment
.\scripts\deploy-azure-simple.ps1
```

### Step 3: Wait for Deployment
- Backend deployment: ~2-3 minutes
- Frontend deployment: ~3-5 minutes
- Total time: ~5-8 minutes

### Step 4: Access Your Application
```
Frontend: https://payment-web-XXXX.azurewebsites.net
Backend API: https://payment-api-XXXX.azurewebsites.net/swagger
```

## 🐳 Option 2: Deploy with Docker (Container Instances)

### Step 1: Build Docker Images Locally
```powershell
# Build PaymentService
docker build -t payment-service:latest -f src/Services/PaymentService/Dockerfile .

# Build Frontend
docker build -t frontend:latest -f frontend/Dockerfile ./frontend

# Test locally
docker run -d -p 5001:80 payment-service:latest
docker run -d -p 3000:80 frontend:latest
```

### Step 2: Run Container Deployment
```powershell
# Deploy to Azure Container Instances
.\scripts\deploy-azure-student.ps1

# Options
.\scripts\deploy-azure-student.ps1 -ResourceGroup "my-rg" -Location "eastus"

# Skip steps
.\scripts\deploy-azure-student.ps1 -SkipBuild  # Use existing images
```

### Step 3: Monitor Deployment
```powershell
# Check container status
az container show --resource-group rg-cicd-azure-demo --name payment-service

# View logs
az container logs --resource-group rg-cicd-azure-demo --name payment-service
```

## 💰 Cost Optimization Tips

### Free/Cheap Options
1. **Azure App Service F1** - FREE
   - 1 GB RAM, 60 min/day compute
   - Perfect for demos

2. **Azure Container Instances** - $5-10/month
   - Pay per second
   - Stop when not using

3. **Azure Storage** - $0.18/GB/month
   - Only pay for what you use

4. **Azure Database** - Use local PostgreSQL or Azure Database Basic tier ($5/month)

### Cost Saving Strategies
```powershell
# Stop containers when not using
az container stop --resource-group rg-cicd-azure-demo --name payment-service
az container stop --resource-group rg-cicd-azure-demo --name frontend

# Start when needed
az container start --resource-group rg-cicd-azure-demo --name payment-service
az container start --resource-group rg-cicd-azure-demo --name frontend

# Delete everything when done
az group delete --name rg-cicd-azure-demo --yes --no-wait
```

## 🔧 Manual Deployment Steps

### Deploy Backend to App Service

#### 1. Create App Service
```powershell
# Create resource group
az group create --name rg-cicd-demo --location eastus

# Create App Service plan (Free tier)
az appservice plan create `
    --name asp-cicd-demo `
    --resource-group rg-cicd-demo `
    --sku F1 `
    --is-linux

# Create web app
az webapp create `
    --name payment-api-$(Get-Random -Maximum 9999) `
    --resource-group rg-cicd-demo `
    --plan asp-cicd-demo `
    --runtime "DOTNETCORE:8.0"
```

#### 2. Build and Deploy Backend
```powershell
# Build
cd src/Services/PaymentService
dotnet publish -c Release -o ./publish

# Create deployment package
Compress-Archive -Path ./publish/* -DestinationPath ../../../backend.zip -Force

# Deploy
az webapp deployment source config-zip `
    --name payment-api-XXXX `
    --resource-group rg-cicd-demo `
    --src backend.zip
```

### Deploy Frontend to App Service

#### 1. Create Web App for Frontend
```powershell
# Create web app
az webapp create `
    --name payment-web-$(Get-Random -Maximum 9999) `
    --resource-group rg-cicd-demo `
    --plan asp-cicd-demo `
    --runtime "NODE:18-lts"

# Configure environment
az webapp config appsettings set `
    --name payment-web-XXXX `
    --resource-group rg-cicd-demo `
    --settings REACT_APP_API_URL=https://payment-api-XXXX.azurewebsites.net
```

#### 2. Build and Deploy Frontend
```powershell
# Build
cd frontend
npm install
npm run build

# Create deployment package
Compress-Archive -Path ./build/* -DestinationPath ../frontend.zip -Force

# Deploy
az webapp deployment source config-zip `
    --name payment-web-XXXX `
    --resource-group rg-cicd-demo `
    --src frontend.zip
```

## 📊 Monitoring and Troubleshooting

### View Application Logs
```powershell
# Backend logs
az webapp log tail --name payment-api-XXXX --resource-group rg-cicd-demo

# Frontend logs
az webapp log tail --name payment-web-XXXX --resource-group rg-cicd-demo

# Container logs
az container logs --resource-group rg-cicd-azure-demo --name payment-service
```

### Check Application Status
```powershell
# App Service
az webapp show --name payment-api-XXXX --resource-group rg-cicd-demo --query "state"

# Container Instances
az container show --resource-group rg-cicd-azure-demo --name payment-service --query "containers[0].instanceView.currentState.state"
```

### Common Issues

#### Issue 1: App not starting
```powershell
# Check logs
az webapp log tail --name payment-api-XXXX --resource-group rg-cicd-demo

# Restart app
az webapp restart --name payment-api-XXXX --resource-group rg-cicd-demo
```

#### Issue 2: Out of memory (Free tier)
- Solution: Upgrade to Basic tier (B1) for $13/month
```powershell
az appservice plan update --name asp-cicd-demo --resource-group rg-cicd-demo --sku B1
```

#### Issue 3: 403 Forbidden
- Enable CORS in backend
- Check firewall rules

## 🧹 Cleanup

### Delete All Resources
```powershell
# Delete resource group (removes everything)
az group delete --name rg-cicd-demo --yes --no-wait

# Verify deletion
az group exists --name rg-cicd-demo
```

### Selective Cleanup
```powershell
# Delete specific app
az webapp delete --name payment-api-XXXX --resource-group rg-cicd-demo

# Delete container
az container delete --resource-group rg-cicd-azure-demo --name payment-service --yes
```

## 📈 Scaling Options

### App Service Scaling
```powershell
# Scale up (more powerful)
az appservice plan update --name asp-cicd-demo --resource-group rg-cicd-demo --sku B2

# Scale out (more instances)
az appservice plan update --name asp-cicd-demo --resource-group rg-cicd-demo --number-of-workers 2
```

### Container Instances Scaling
```powershell
# Update container resources
az container create `
    --resource-group rg-cicd-azure-demo `
    --name payment-service `
    --image payment-service:latest `
    --cpu 2 `
    --memory 2
```

## 🔐 Security Best Practices

1. **Use Azure Key Vault** for secrets
2. **Enable HTTPS** (automatic with App Service)
3. **Configure CORS** properly
4. **Use Managed Identity** for authentication
5. **Enable Application Insights** for monitoring

## 📚 Additional Resources

- [Azure for Students](https://azure.microsoft.com/free/students/)
- [Azure App Service Docs](https://docs.microsoft.com/azure/app-service/)
- [Azure Container Instances Docs](https://docs.microsoft.com/azure/container-instances/)
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)

## 💡 Tips for Student Account

1. **Monitor your credit**: Check Azure portal regularly
2. **Use Free tier** whenever possible
3. **Delete resources** when not using
4. **Set up budget alerts** in Azure portal
5. **Use Azure Cost Management** to track spending

## 🆘 Get Help

- Azure Support: https://azure.microsoft.com/support/
- Student Support: https://aka.ms/azureforstudents/support
- GitHub Issues: https://github.com/your-repo/issues

