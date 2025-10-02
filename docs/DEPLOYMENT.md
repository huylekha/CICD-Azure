# Deployment Guide

## Prerequisites

Before deploying the microservices platform, ensure you have the following tools installed:

### Required Tools
- **Azure CLI** (v2.50.0 or later)
- **Terraform** (v1.6.0 or later)
- **.NET 8 SDK**
- **Docker** (v20.10 or later)
- **kubectl** (v1.28 or later)
- **Git**

### Azure Prerequisites
- Azure subscription with appropriate permissions
- Azure Container Registry (ACR)
- Service Principal with Contributor role

## Initial Setup

### 1. Azure Authentication

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "your-subscription-id"

# Create service principal (if not exists)
az ad sp create-for-rbac --name "cicd-azure-sp" --role Contributor --scopes /subscriptions/your-subscription-id
```

### 2. Configure GitHub Secrets

Add the following secrets to your GitHub repository:

```bash
# Azure Service Principal
AZURE_CREDENTIALS='{"clientId":"...","clientSecret":"...","subscriptionId":"...","tenantId":"..."}'

# Individual Azure credentials
AZURE_CLIENT_ID="your-client-id"
AZURE_CLIENT_SECRET="your-client-secret"
AZURE_SUBSCRIPTION_ID="your-subscription-id"
AZURE_TENANT_ID="your-tenant-id"

# SendGrid (for notifications)
SENDGRID_API_KEY="your-sendgrid-api-key"
```

### 3. Clone Repository

```bash
git clone <repository-url>
cd CICD-Azure
```

## Infrastructure Deployment

### 1. Configure Terraform

```bash
cd terraform

# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
nano terraform.tfvars
```

**Example terraform.tfvars:**
```hcl
location = "East US"
environment = "dev"
project_name = "cicd-azure"
aks_node_count = 2
aks_vm_size = "Standard_D2s_v3"
postgres_sku = "GP_Standard_D2s_v3"
postgres_storage_mb = 32768
backup_retention_days = 7
log_retention_days = 30

tags = {
  Owner = "DevOps Team"
  CostCenter = "Engineering"
  Project = "Microservices Platform"
}
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="terraform.tfvars"

# Apply infrastructure
terraform apply -var-file="terraform.tfvars"
```

### 3. Configure Azure Container Registry

```bash
# Get ACR login server
ACR_NAME=$(terraform output -raw azure_container_registry_name)

# Login to ACR
az acr login --name $ACR_NAME

# Enable admin user (for CI/CD)
az acr update -n $ACR_NAME --admin-enabled true
```

## Application Deployment

### 1. Build and Push Images

```bash
# Get ACR login server
ACR_NAME=$(terraform output -raw azure_container_registry_name)

# Build and push PaymentService
docker build -t $ACR_NAME/payment-service:latest -f src/Services/PaymentService/Dockerfile .
docker push $ACR_NAME/payment-service:latest

# Build and push NotificationService
docker build -t $ACR_NAME/notification-service:latest -f src/Services/NotificationService/Dockerfile .
docker push $ACR_NAME/notification-service:latest
```

### 2. Configure Kubernetes

```bash
# Get AKS credentials
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
AKS_CLUSTER=$(terraform output -raw aks_cluster_name)

az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --overwrite-existing

# Verify connection
kubectl get nodes
```

### 3. Create Kubernetes Secrets

```bash
# Get connection strings from Terraform outputs
POSTGRES_CONNECTION_STRING=$(terraform output -raw postgres_connection_string)
APPLICATION_INSIGHTS_CONNECTION_STRING=$(terraform output -raw application_insights_connection_string)

# Create secrets for PaymentService
kubectl create secret generic payment-service-secrets \
  --from-literal=postgres-connection-string="$POSTGRES_CONNECTION_STRING" \
  --from-literal=rabbitmq-connection-string="amqp://admin:admin123@rabbitmq:5672" \
  --from-literal=application-insights-connection-string="$APPLICATION_INSIGHTS_CONNECTION_STRING" \
  --from-literal=sendgrid-api-key="your-sendgrid-api-key"

# Create secrets for NotificationService
kubectl create secret generic notification-service-secrets \
  --from-literal=postgres-connection-string="$POSTGRES_CONNECTION_STRING" \
  --from-literal=rabbitmq-connection-string="amqp://admin:admin123@rabbitmq:5672" \
  --from-literal=application-insights-connection-string="$APPLICATION_INSIGHTS_CONNECTION_STRING" \
  --from-literal=sendgrid-api-key="your-sendgrid-api-key"
```

### 4. Deploy Services

```bash
# Deploy RabbitMQ
kubectl apply -f k8s/rabbitmq-deployment.yaml

# Wait for RabbitMQ to be ready
kubectl wait --for=condition=available --timeout=300s deployment/rabbitmq

# Deploy PaymentService
kubectl apply -f k8s/payment-service-deployment.yaml
kubectl apply -f k8s/payment-service-service.yaml

# Deploy NotificationService
kubectl apply -f k8s/notification-service-deployment.yaml
kubectl apply -f k8s/notification-service-service.yaml

# Wait for services to be ready
kubectl wait --for=condition=available --timeout=300s deployment/payment-service
kubectl wait --for=condition=available --timeout=300s deployment/notification-service
```

### 5. Configure Ingress (Optional)

```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Deploy ingress rules
kubectl apply -f k8s/payment-service-ingress.yaml
kubectl apply -f k8s/notification-service-ingress.yaml
```

## Verification

### 1. Check Service Status

```bash
# Check all deployments
kubectl get deployments

# Check all services
kubectl get services

# Check all pods
kubectl get pods

# Check ingress
kubectl get ingress
```

### 2. Test Services

```bash
# Get service IPs
PAYMENT_SERVICE_IP=$(kubectl get service payment-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
NOTIFICATION_SERVICE_IP=$(kubectl get service notification-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test health endpoints
curl -f http://$PAYMENT_SERVICE_IP/health
curl -f http://$NOTIFICATION_SERVICE_IP/health
```

### 3. View Logs

```bash
# View PaymentService logs
kubectl logs deployment/payment-service -f

# View NotificationService logs
kubectl logs deployment/notification-service -f

# View RabbitMQ logs
kubectl logs deployment/rabbitmq -f
```

## CI/CD Pipeline Deployment

### 1. Configure GitHub Actions

The CI/CD pipeline is automatically triggered on:
- **Pull Requests**: Runs tests and Terraform plan
- **Main Branch Push**: Full deployment pipeline

### 2. Pipeline Stages

1. **Terraform Plan** (PR only)
2. **Build & Test**
3. **Terraform Apply** (main branch)
4. **Build & Push Images**
5. **Deploy to AKS**
6. **Security Scan**
7. **Cleanup**

### 3. Monitor Pipeline

- Go to GitHub Actions tab in your repository
- Monitor pipeline execution
- Check logs for any failures
- Verify deployments in Azure

## Environment-Specific Deployments

### Development Environment

```bash
# Use development configuration
export ENVIRONMENT=dev
export LOCATION="East US"

# Deploy with development settings
terraform apply -var="environment=$ENVIRONMENT" -var="location=$LOCATION"
```

### Staging Environment

```bash
# Use staging configuration
export ENVIRONMENT=staging
export LOCATION="East US"

# Deploy with staging settings
terraform apply -var="environment=$ENVIRONMENT" -var="location=$LOCATION"
```

### Production Environment

```bash
# Use production configuration
export ENVIRONMENT=prod
export LOCATION="East US"

# Deploy with production settings
terraform apply -var="environment=$ENVIRONMENT" -var="location=$LOCATION"
```

## Scaling

### Horizontal Pod Autoscaling

```bash
# Create HPA for PaymentService
kubectl autoscale deployment payment-service --cpu-percent=70 --min=2 --max=10

# Create HPA for NotificationService
kubectl autoscale deployment notification-service --cpu-percent=70 --min=2 --max=10

# Check HPA status
kubectl get hpa
```

### Cluster Autoscaling

```bash
# Enable cluster autoscaling
az aks update --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --enable-cluster-autoscaler --min-count 1 --max-count 10
```

## Monitoring Setup

### 1. Application Insights

```bash
# Get Application Insights connection string
APPLICATION_INSIGHTS_CONNECTION_STRING=$(terraform output -raw application_insights_connection_string)

# Update secrets with Application Insights
kubectl create secret generic application-insights-secret \
  --from-literal=connection-string="$APPLICATION_INSIGHTS_CONNECTION_STRING" \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 2. Log Analytics

```bash
# Get Log Analytics workspace ID
LOG_ANALYTICS_WORKSPACE_ID=$(terraform output -raw log_analytics_workspace_id)

# Enable container insights
az aks enable-addons --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --addons monitoring --workspace-resource-id $LOG_ANALYTICS_WORKSPACE_ID
```

## Troubleshooting

### Common Issues

#### 1. Pod Startup Issues

```bash
# Check pod status
kubectl describe pod <pod-name>

# Check pod logs
kubectl logs <pod-name> --previous

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

#### 2. Service Connection Issues

```bash
# Check service endpoints
kubectl get endpoints

# Test service connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup payment-service
```

#### 3. Database Connection Issues

```bash
# Check database connectivity
kubectl exec -it deployment/payment-service -- curl -f http://localhost/health

# Check database logs
kubectl logs deployment/postgres
```

#### 4. RabbitMQ Issues

```bash
# Check RabbitMQ status
kubectl exec -it deployment/rabbitmq -- rabbitmq-diagnostics ping

# Check RabbitMQ management UI
kubectl port-forward deployment/rabbitmq 15672:15672
# Open http://localhost:15672 in browser
```

### Rollback Procedures

#### 1. Rollback Application

```bash
# Rollback to previous version
kubectl rollout undo deployment/payment-service
kubectl rollout undo deployment/notification-service

# Check rollout status
kubectl rollout status deployment/payment-service
kubectl rollout status deployment/notification-service
```

#### 2. Rollback Infrastructure

```bash
# Rollback Terraform changes
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars" -target=resource.to.rollback
```

## Cleanup

### 1. Delete Kubernetes Resources

```bash
# Delete deployments
kubectl delete deployment payment-service notification-service rabbitmq

# Delete services
kubectl delete service payment-service notification-service rabbitmq

# Delete secrets
kubectl delete secret payment-service-secrets notification-service-secrets
```

### 2. Delete Infrastructure

```bash
# Destroy Terraform resources
terraform destroy -var-file="terraform.tfvars"
```

### 3. Cleanup Container Registry

```bash
# Delete container images
az acr repository delete --name $ACR_NAME --image payment-service:latest --yes
az acr repository delete --name $ACR_NAME --image notification-service:latest --yes
```

## Best Practices

### 1. Security
- Use Azure Key Vault for secrets
- Enable RBAC in Kubernetes
- Use non-root containers
- Regular security scanning

### 2. Monitoring
- Set up proper alerting
- Monitor resource usage
- Track application metrics
- Regular log analysis

### 3. Backup
- Regular database backups
- Infrastructure as Code
- Container image backups
- Configuration backups

### 4. Updates
- Regular dependency updates
- Security patch management
- Gradual rollout strategies
- Rollback procedures

