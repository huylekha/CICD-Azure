# 🎓 Hướng Dẫn Deploy Cho Azure Student Account

## 💰 Chi Phí Dự Kiến
- **AKS Cluster**: ~$30-50/tháng (với 1 node B2s)
- **ACR Basic**: Miễn phí (500MB storage)
- **Load Balancer**: ~$18/tháng
- **Tổng cộng**: ~$50-70/tháng

> **Lưu ý**: Với Azure Student Account, bạn có thể có credit miễn phí $100-200

## 🚀 Cách 1: Deploy Nhanh (Khuyến nghị)

### Bước 1: Chuẩn bị
```bash
# Cài đặt Azure CLI
# Windows: winget install Microsoft.AzureCLI
# Mac: brew install azure-cli
# Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Clone repository
git clone <your-repo>
cd CICD-Azure
```

### Bước 2: Chạy script deploy
```bash
# Cấp quyền thực thi
chmod +x scripts/quick-deploy.sh

# Chạy deploy
./scripts/quick-deploy.sh
```

### Bước 3: Truy cập demo
- Script sẽ hiển thị URL của frontend
- Mở browser và truy cập URL đó
- Test các chức năng transfer money

## 🏗️ Cách 2: Deploy với Terraform (Chi tiết hơn)

### Bước 1: Cấu hình
```bash
cd terraform
cp terraform.tfvars.student terraform.tfvars
# Chỉnh sửa terraform.tfvars nếu cần
```

### Bước 2: Deploy infrastructure
```bash
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### Bước 3: Deploy applications
```bash
cd ..
chmod +x scripts/deploy-student.sh
./scripts/deploy-student.sh
```

## 🔧 Cấu Hình Tối Ưu Cho Student

### AKS Configuration
- **Node Count**: 1 (thay vì 2-3)
- **VM Size**: Standard_B2s (2 vCPU, 4GB RAM)
- **Auto-scaling**: Tắt để tránh chi phí phát sinh

### PostgreSQL Configuration
- **SKU**: B_Standard_B1ms (Burstable tier)
- **Storage**: 32GB (minimum)
- **Backup**: 7 ngày (thay vì 30)

### Monitoring
- **Log Retention**: 7 ngày (thay vì 30)
- **Application Insights**: Basic tier

## 📊 Kiểm Tra Chi Phí

### Xem chi phí hiện tại
```bash
# Xem cost analysis
az consumption usage list --billing-period-name "202312-1"

# Xem resource groups
az group list --query "[].{Name:name, Location:location}"
```

### Set up budget alerts
```bash
# Tạo budget alert
az consumption budget create \
    --budget-name "Student-Demo-Budget" \
    --amount 50 \
    --resource-group "cicd-demo-rg" \
    --time-grain Monthly \
    --start-date "2023-12-01" \
    --end-date "2024-12-31"
```

## 🧪 Test Demo

### 1. Truy cập Frontend
- Mở browser: `http://<frontend-ip>`
- Kiểm tra dashboard
- Test transfer money

### 2. Test API trực tiếp
```bash
# Test health endpoint
curl http://<payment-service-ip>/health

# Test transfer API
curl -X POST http://<payment-service-ip>/api/payment/transfer \
  -H "Content-Type: application/json" \
  -d '{
    "fromAccountId": "1",
    "toAccountId": "2",
    "amount": 100,
    "currency": "USD",
    "description": "Test transfer"
  }'
```

### 3. Kiểm tra logs
```bash
# Xem logs của services
kubectl logs deployment/payment-service
kubectl logs deployment/notification-service
kubectl logs deployment/frontend

# Xem real-time logs
kubectl logs -f deployment/payment-service
```

## 🗑️ Cleanup (Quan trọng!)

### Xóa tất cả resources
```bash
# Xóa resource group (xóa tất cả)
az group delete --name "cicd-demo-rg" --yes --no-wait

# Hoặc xóa từng service
kubectl delete deployment --all
kubectl delete service --all
kubectl delete secret --all
```

### Kiểm tra resources còn lại
```bash
# List tất cả resource groups
az group list --query "[].{Name:name, Location:location}"

# Xóa resource group nếu còn
az group delete --name "cicd-demo-rg" --yes
```

## 🚨 Lưu Ý Quan Trọng

### 1. **Luôn cleanup sau khi test**
- Chi phí sẽ tiếp tục phát sinh nếu không xóa resources
- Set up budget alerts để tránh chi phí bất ngờ

### 2. **Monitor chi phí thường xuyên**
```bash
# Check cost hàng ngày
az consumption usage list --billing-period-name "202312-1" --query "[].{Resource:instanceName, Cost:pretaxCost}"
```

### 3. **Sử dụng Azure Cost Management**
- Vào Azure Portal → Cost Management + Billing
- Xem cost analysis và trends
- Set up alerts khi chi phí vượt ngưỡng

## 🎯 Tips Tiết Kiệm

### 1. **Sử dụng Spot Instances**
```bash
# Tạo AKS với spot instances (rẻ hơn 60-90%)
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_NAME \
    --node-count 1 \
    --node-vm-size Standard_B2s \
    --enable-cluster-autoscaler \
    --min-count 0 \
    --max-count 1 \
    --priority Spot \
    --eviction-policy Delete
```

### 2. **Auto-shutdown**
```bash
# Tự động shutdown AKS vào buổi tối
az aks stop --resource-group $RESOURCE_GROUP --name $AKS_NAME
```

### 3. **Sử dụng Dev/Test pricing**
- Nếu có Visual Studio subscription
- Sử dụng Dev/Test pricing (rẻ hơn 50%)

## 📞 Hỗ Trợ

Nếu gặp vấn đề:
1. Check logs: `kubectl logs deployment/<service-name>`
2. Check resources: `kubectl get all`
3. Check Azure status: `az aks show --resource-group <rg> --name <aks>`
4. Restart services: `kubectl rollout restart deployment/<service-name>`

## 🎉 Kết Quả Mong Đợi

Sau khi deploy thành công, bạn sẽ có:
- ✅ Frontend dashboard với giao diện đẹp
- ✅ Payment service API hoạt động
- ✅ Notification service
- ✅ RabbitMQ message queue
- ✅ Real-time transaction monitoring
- ✅ Saga pattern với rollback functionality

**Total cost**: ~$50-70/tháng (có thể miễn phí với student credit)
