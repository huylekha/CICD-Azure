# CI/CD Azure Microservices Platform

A comprehensive CI/CD solution for Azure with microservices architecture using ASP.NET Core, CQRS, Event-Driven patterns, and Saga orchestration.

## 🏗️ Architecture Overview

This project implements a modern microservices architecture with the following components:

### Infrastructure (Terraform)
- **Azure Kubernetes Service (AKS)** - Container orchestration
- **Azure PostgreSQL Flexible Server** - Database
- **Azure Storage Account** - File storage and logs
- **Azure Key Vault** - Secrets management
- **Azure Application Insights** - Monitoring and telemetry
- **Virtual Network & Subnets** - Network isolation

### Microservices
- **PaymentService** - Handles money transfers with CQRS pattern
- **NotificationService** - Manages email/SMS notifications

### Patterns Implemented
- **CQRS (Command Query Responsibility Segregation)** - Separate read/write models
- **Event-Driven Architecture** - Services communicate via RabbitMQ events
- **Saga Pattern (Choreography)** - Distributed transaction management with rollback
- **Domain-Driven Design** - Rich domain models and business logic

## 🌐 Azure Deployment (Student Account)

### Quick Deploy to Azure (FREE)

**Option 1: Azure App Service (Recommended - FREE tier)**
```powershell
# Login to Azure
az login

# Run simple deployment script
.\scripts\deploy-azure-simple.ps1

# Access your app (URLs will be displayed after deployment)
# Frontend: https://payment-web-XXXX.azurewebsites.net
# Backend: https://payment-api-XXXX.azurewebsites.net/swagger
```

**Option 2: Azure Container Instances (~$5-10/month)**
```powershell
# Build and deploy with Docker
.\scripts\deploy-azure-student.ps1
```

**Full Guide**: See [Azure Deployment Guide](docs/AZURE-DEPLOYMENT-GUIDE.md)

## 🚀 Quick Start

### Prerequisites
- Azure CLI
- Terraform >= 1.6.0
- .NET 8 SDK
- Docker & Docker Compose
- kubectl

### 1. Infrastructure Setup

```bash
# Clone the repository
git clone <repository-url>
cd CICD-Azure

# Configure Azure credentials
az login
az account set --subscription "your-subscription-id"

# Initialize Terraform
cd terraform
terraform init

# Create terraform.tfvars file
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Plan and apply infrastructure
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### 2. Local Development

```bash
# Start dependencies (PostgreSQL, RabbitMQ)
docker-compose up postgres rabbitmq -d

# Run PaymentService
cd src/Services/PaymentService
dotnet run

# Run NotificationService (in another terminal)
cd src/Services/NotificationService
dotnet run
```

### 3. Docker Development

```bash
# Build and run all services
docker-compose up --build
```

## 📋 API Endpoints

### PaymentService
- `POST /api/payment/transfer` - Transfer money between accounts
- `POST /api/payment/rollback` - Rollback a transaction
- `GET /api/payment/account/{id}` - Get account details
- `GET /api/payment/transaction/{id}` - Get transaction details
- `GET /api/payment/account/{id}/transactions` - Get account transactions

### NotificationService
- `GET /health` - Health check endpoint

## 🔄 Event Flow Example

### Money Transfer Saga

1. **User initiates transfer** → `TransferMoneyCommand`
2. **PaymentService processes**:
   - Validates accounts and balance
   - Debits from account
   - Publishes `MoneyDebited` event
   - Credits to account
   - Publishes `MoneyCredited` event
   - Publishes `TransferCompleted` event

3. **NotificationService receives** `TransferCompleted`:
   - Creates notification request
   - Sends email/SMS to user
   - Publishes `NotificationSent` event

4. **Rollback scenario** (if notification fails):
   - NotificationService publishes `TransferRollbackRequested`
   - PaymentService receives rollback request
   - Reverses the transaction
   - Publishes `TransferRollbackCompleted`

## 🛠️ CI/CD Pipeline

The GitHub Actions pipeline includes:

1. **Terraform Plan** (on PR) - Infrastructure validation
2. **Build & Test** - .NET build and unit tests
3. **Terraform Apply** (on main) - Deploy infrastructure
4. **Build & Push Images** - Docker images to Azure Container Registry
5. **Deploy to AKS** - Kubernetes deployment
6. **Security Scan** - Container vulnerability scanning
7. **Cleanup** - Remove old container images

### Required GitHub Secrets

```bash
AZURE_CREDENTIALS='{"clientId":"...","clientSecret":"...","subscriptionId":"...","tenantId":"..."}'
AZURE_CLIENT_ID="your-client-id"
AZURE_CLIENT_SECRET="your-client-secret"
AZURE_SUBSCRIPTION_ID="your-subscription-id"
AZURE_TENANT_ID="your-tenant-id"
```

## 🔧 Configuration

### Environment Variables

#### PaymentService & NotificationService
- `ConnectionStrings__DefaultConnection` - PostgreSQL connection string
- `ConnectionStrings__RabbitMQ` - RabbitMQ connection string
- `ConnectionStrings__ApplicationInsights` - Application Insights connection string
- `SendGrid__ApiKey` - SendGrid API key for email notifications
- `SendGrid__FromEmail` - From email address

### Azure Key Vault Integration

Secrets are automatically stored in Azure Key Vault:
- `postgres-connection-string`
- `postgres-password`
- `application-insights-key`
- `storage-connection-string`

## 📊 Monitoring & Observability

- **Application Insights** - Application performance monitoring
- **Serilog** - Structured logging
- **Health Checks** - Service health monitoring
- **Kubernetes Metrics** - Container and pod metrics

## 🧪 Testing

```bash
# Run unit tests
dotnet test

# Run with coverage
dotnet test --collect:"XPlat Code Coverage"

# Integration tests (requires running services)
dotnet test --filter Category=Integration
```

## 🔒 Security

- **Container Security** - Non-root users, minimal base images
- **Network Security** - VNet isolation, NSG rules
- **Secrets Management** - Azure Key Vault integration
- **Vulnerability Scanning** - Trivy security scanning in CI/CD

## 📈 Scaling

### Horizontal Scaling
- AKS auto-scaling based on CPU/memory metrics
- Multiple replicas for each service
- Load balancer distribution

### Database Scaling
- PostgreSQL Flexible Server with auto-scaling
- Connection pooling
- Read replicas (can be added)

## 🚨 Troubleshooting

### Common Issues

1. **Database Connection Issues**
   ```bash
   # Check PostgreSQL connectivity
   kubectl exec -it deployment/payment-service -- curl -f http://localhost/health
   ```

2. **RabbitMQ Connection Issues**
   ```bash
   # Check RabbitMQ status
   kubectl logs deployment/rabbitmq
   ```

3. **Service Discovery Issues**
   ```bash
   # Check service endpoints
   kubectl get services
   kubectl get endpoints
   ```

### Logs

```bash
# View service logs
kubectl logs deployment/payment-service -f
kubectl logs deployment/notification-service -f

# View all logs
kubectl logs -l app=payment-service --all-containers=true
```

## 📚 Additional Resources

- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [MassTransit Documentation](https://masstransit.io/)
- [MediatR Documentation](https://github.com/jbogard/MediatR)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.