# CI/CD Azure Microservices Platform Makefile
# Sử dụng: make <command>

.PHONY: help setup build test deploy clean dev

# Default target
help:
	@echo "=========================================="
	@echo "🚀 CI/CD Azure Microservices Platform"
	@echo "=========================================="
	@echo ""
	@echo "Available commands:"
	@echo "  setup     - Setup development environment"
	@echo "  build     - Build all projects"
	@echo "  test      - Run all tests"
	@echo "  dev       - Start development environment"
	@echo "  deploy    - Deploy to Azure (student optimized)"
	@echo "  deploy-full - Deploy with full infrastructure"
	@echo "  clean     - Clean up all resources"
	@echo "  docker    - Build Docker images"
	@echo "  k8s       - Deploy to Kubernetes"
	@echo "  logs      - View service logs"
	@echo "  status    - Check service status"
	@echo ""

# Setup development environment
setup:
	@echo "🚀 Setting up development environment..."
	chmod +x scripts/*.sh
	./scripts/setup-dev.sh

# Build all projects
build:
	@echo "🔨 Building all projects..."
	dotnet build --configuration Release
	cd frontend && npm run build

# Run all tests
test:
	@echo "🧪 Running all tests..."
	dotnet test --configuration Release --verbosity normal
	cd frontend && npm test -- --watchAll=false

# Start development environment
dev:
	@echo "🚀 Starting development environment..."
	docker-compose up -d postgres rabbitmq
	@echo "✅ Dependencies started. Now run:"
	@echo "   Frontend: cd frontend && npm start"
	@echo "   PaymentService: cd src/Services/PaymentService && dotnet run"
	@echo "   NotificationService: cd src/Services/NotificationService && dotnet run"

# Deploy to Azure (student optimized)
deploy:
	@echo "🚀 Deploying to Azure (student optimized)..."
	chmod +x scripts/quick-deploy.sh
	./scripts/quick-deploy.sh

# Deploy with full infrastructure
deploy-full:
	@echo "🚀 Deploying with full infrastructure..."
	chmod +x scripts/deploy-student.sh
	./scripts/deploy-student.sh

# Clean up all resources
clean:
	@echo "🧹 Cleaning up all resources..."
	chmod +x scripts/cleanup.sh
	./scripts/cleanup.sh

# Build Docker images
docker:
	@echo "🐳 Building Docker images..."
	docker build -t payment-service:latest -f src/Services/PaymentService/Dockerfile .
	docker build -t notification-service:latest -f src/Services/NotificationService/Dockerfile .
	docker build -t frontend:latest -f frontend/Dockerfile .

# Deploy to Kubernetes
k8s:
	@echo "☸️  Deploying to Kubernetes..."
	kubectl apply -f k8s/

# Deploy to Local Kubernetes (Docker Desktop)
k8s-local:
	@echo "☸️  Deploying to Local Kubernetes..."
	chmod +x scripts/deploy-local-k8s.sh
	./scripts/deploy-local-k8s.sh

# Test Local Kubernetes
test-k8s-local:
	@echo "🧪 Testing Local Kubernetes..."
	chmod +x scripts/test-local-k8s.sh
	./scripts/test-local-k8s.sh

# Cleanup Local Kubernetes
clean-k8s-local:
	@echo "🧹 Cleaning up Local Kubernetes..."
	chmod +x scripts/cleanup-local-k8s.sh
	./scripts/cleanup-local-k8s.sh

# View service logs
logs:
	@echo "📝 Viewing service logs..."
	@echo "Docker Compose logs:"
	docker-compose logs -f
	@echo ""
	@echo "Kubernetes logs:"
	kubectl logs -f deployment/payment-service
	kubectl logs -f deployment/notification-service
	kubectl logs -f deployment/frontend

# Check service status
status:
	@echo "📊 Checking service status..."
	@echo "Docker Compose services:"
	docker-compose ps
	@echo ""
	@echo "Kubernetes services:"
	kubectl get services
	kubectl get pods

# Test local environment
test-local:
	@echo "🧪 Testing local environment..."
	chmod +x scripts/test-local.sh
	./scripts/test-local.sh

# Install dependencies
install:
	@echo "📦 Installing dependencies..."
	dotnet restore
	cd frontend && npm install

# Format code
format:
	@echo "🎨 Formatting code..."
	dotnet format
	cd frontend && npm run lint:fix

# Security scan
security:
	@echo "🔒 Running security scan..."
	dotnet list package --vulnerable
	cd frontend && npm audit

# Database migration
migrate:
	@echo "🗄️  Running database migrations..."
	cd src/Services/PaymentService && dotnet ef database update
	cd src/Services/NotificationService && dotnet ef database update

# Generate API documentation
docs:
	@echo "📚 Generating API documentation..."
	cd src/Services/PaymentService && dotnet run -- --generate-docs
	cd src/Services/NotificationService && dotnet run -- --generate-docs

# Performance test
perf-test:
	@echo "⚡ Running performance tests..."
	cd src/Services/PaymentService && dotnet run -- --perf-test
	cd src/Services/NotificationService && dotnet run -- --perf-test

# Backup data
backup:
	@echo "💾 Creating backup..."
	docker exec postgres pg_dump -U postgresadmin microservices > backup_$(shell date +%Y%m%d_%H%M%S).sql

# Restore data
restore:
	@echo "🔄 Restoring data..."
	@read -p "Enter backup file name: " file; \
	docker exec -i postgres psql -U postgresadmin microservices < $$file

# Monitor resources
monitor:
	@echo "📊 Monitoring resources..."
	@echo "Docker stats:"
	docker stats --no-stream
	@echo ""
	@echo "Kubernetes resource usage:"
	kubectl top nodes
	kubectl top pods

# Quick start (setup + dev)
quick-start: setup dev
	@echo "🎉 Quick start completed!"
	@echo "Open http://localhost:3000 in your browser"

# Full deployment (build + test + deploy)
full-deploy: build test deploy
	@echo "🎉 Full deployment completed!"

# Development cycle (build + test + dev)
dev-cycle: build test dev
	@echo "🎉 Development cycle completed!"
