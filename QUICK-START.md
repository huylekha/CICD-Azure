# 🚀 Quick Start Guide

## ⚡ Deploy Nhanh Nhất (5 phút)

### 1. **Clone và Setup**
```bash
git clone <your-repo>
cd CICD-Azure
chmod +x scripts/*.sh
```

### 2. **Deploy to Azure (Student Account)**
```bash
# Deploy với cấu hình tiết kiệm nhất
./scripts/quick-deploy.sh
```

### 3. **Truy cập Demo**
- Script sẽ hiển thị URL frontend
- Mở browser và test các chức năng

## 🛠️ Development Local (10 phút)

### 1. **Setup Development**
```bash
make setup
# hoặc
./scripts/setup-dev.sh
```

### 2. **Start Services**
```bash
make dev
# hoặc
docker-compose up -d postgres rabbitmq
cd frontend && npm start
cd src/Services/PaymentService && dotnet run
cd src/Services/NotificationService && dotnet run
```

### 3. **Truy cập**
- Frontend: http://localhost:3000
- PaymentService: http://localhost:5001
- NotificationService: http://localhost:5002
- RabbitMQ: http://localhost:15672 (admin/admin123)

## ☸️ Local Kubernetes (15 phút)

### 1. **Deploy to Local K8s**
```bash
# Linux/Mac
make k8s-local
# hoặc
./scripts/deploy-local-k8s.sh

# Windows PowerShell
.\scripts\deploy-local-k8s.ps1
```

### 2. **Test Deployment**
```bash
# Linux/Mac
make test-k8s-local
# hoặc
./scripts/test-local-k8s.sh

# Windows PowerShell
.\scripts\deploy-local-k8s.ps1 -Test
```

### 3. **Truy cập**
- Script sẽ hiển thị các URL với port động
- Frontend: http://localhost:30000 (hoặc port khác)
- PaymentService: http://localhost:30001 (hoặc port khác)
- NotificationService: http://localhost:30002 (hoặc port khác)
- RabbitMQ: http://localhost:30003 (hoặc port khác)

### 4. **Cleanup**
```bash
# Linux/Mac
make clean-k8s-local
# hoặc
./scripts/cleanup-local-k8s.sh

# Windows PowerShell
.\scripts\deploy-local-k8s.ps1 -Cleanup
```

## 📋 Available Commands

### Make Commands
```bash
make help          # Xem tất cả commands
make setup         # Setup development environment
make build         # Build all projects
make test          # Run all tests
make dev           # Start development environment
make deploy        # Deploy to Azure (student optimized)
make clean         # Clean up all resources
make docker        # Build Docker images
make k8s           # Deploy to Kubernetes
make k8s-local     # Deploy to Local Kubernetes
make test-k8s-local # Test Local Kubernetes
make clean-k8s-local # Cleanup Local Kubernetes
make logs          # View service logs
make status        # Check service status
```

### Script Commands
```bash
./scripts/quick-deploy.sh    # Deploy nhanh nhất
./scripts/deploy-student.sh  # Deploy với Terraform
./scripts/setup-dev.sh       # Setup development
./scripts/test-local.sh      # Test local environment
./scripts/cleanup.sh         # Clean up resources
./scripts/deploy-local-k8s.sh # Deploy to Local Kubernetes
./scripts/test-local-k8s.sh  # Test Local Kubernetes
./scripts/cleanup-local-k8s.sh # Cleanup Local Kubernetes
```

## 🎯 Demo Features

### Frontend Dashboard
- ✅ Real-time transaction monitoring
- ✅ Transfer money form
- ✅ Account management
- ✅ Transaction history
- ✅ Charts and statistics

### Backend Services
- ✅ CQRS pattern implementation
- ✅ Event-driven architecture
- ✅ Saga pattern with rollback
- ✅ RabbitMQ message queue
- ✅ PostgreSQL database
- ✅ Health checks

### Infrastructure
- ✅ Azure Kubernetes Service
- ✅ Azure Container Registry
- ✅ Load balancers
- ✅ Auto-scaling
- ✅ Monitoring

## 💰 Cost Optimization

### Student Account Setup
- **AKS**: 1 node B2s (~$30/month)
- **ACR**: Basic tier (free)
- **Load Balancer**: ~$18/month
- **Total**: ~$50/month

### Free Credits
- Azure Student: $100-200 credit
- Có thể chạy miễn phí 2-4 tháng

## 🧪 Testing

### Local Testing
```bash
make test-local
# hoặc
./scripts/test-local.sh
```

### API Testing
```bash
# Health check
curl http://localhost:5001/health

# Transfer money
curl -X POST http://localhost:5001/api/payment/transfer \
  -H "Content-Type: application/json" \
  -d '{
    "fromAccountId": "550e8400-e29b-41d4-a716-446655440001",
    "toAccountId": "550e8400-e29b-41d4-a716-446655440002",
    "amount": 100,
    "currency": "USD",
    "description": "Test transfer"
  }'
```

## 🗑️ Cleanup

### Local Cleanup
```bash
docker-compose down -v
docker system prune -f
```

### Azure Cleanup
```bash
make clean
# hoặc
./scripts/cleanup.sh
```

## 🆘 Troubleshooting

### Common Issues

1. **Docker not running**
   ```bash
   # Start Docker Desktop
   # Check: docker info
   ```

2. **Port conflicts**
   ```bash
   # Check ports: netstat -an | grep :5001
   # Kill process: lsof -ti:5001 | xargs kill
   ```

3. **Azure login issues**
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

4. **Kubernetes connection issues**
   ```bash
   az aks get-credentials --resource-group <rg> --name <aks>
   kubectl get nodes
   ```

### Get Help
- Check logs: `make logs`
- Check status: `make status`
- View documentation: `docs/` folder

## 🎉 Success!

Sau khi deploy thành công, bạn sẽ có:
- ✅ Modern React dashboard
- ✅ Microservices architecture
- ✅ Event-driven communication
- ✅ Saga pattern implementation
- ✅ Real-time monitoring
- ✅ Production-ready infrastructure

**Total time**: 5-10 phút để có một hệ thống hoàn chỉnh!
