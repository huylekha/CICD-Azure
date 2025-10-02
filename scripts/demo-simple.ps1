# Simple Demo Script - Chỉ chạy frontend với mock data
param(
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
    Write-Host "🚀 Simple Demo Script"
    Write-Host "=========================================="
    Write-Host ""
    Write-Host "This script starts a simple demo with:"
    Write-Host "• PostgreSQL database"
    Write-Host "• RabbitMQ message queue"
    Write-Host "• React frontend with mock data"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\demo-simple.ps1"
    Write-Host ""
}

function Start-SimpleDemo {
    Write-Status "🚀 Starting Simple Demo..."
    
    # Check if Docker is running
    try {
        docker info | Out-Null
    }
    catch {
        Write-Error "Docker is not running. Please start Docker first."
        exit 1
    }
    
    # Start only PostgreSQL and RabbitMQ
    Write-Status "Starting PostgreSQL and RabbitMQ..."
    docker-compose up postgres rabbitmq -d
    
    # Wait for services to be ready
    Write-Status "Waiting for services to be ready..."
    Start-Sleep -Seconds 10
    
    # Check if services are running
    $services = docker-compose ps
    if ($services -match "Up") {
        Write-Success "Dependencies are running"
    } else {
        Write-Error "Failed to start dependencies"
        exit 1
    }
    
    # Build and start frontend
    Write-Status "Building and starting frontend..."
    Set-Location frontend
    
    # Install dependencies
    npm install
    
    # Build frontend
    npm run build
    
    # Check if serve is installed
    try {
        serve --version | Out-Null
        Write-Status "Starting frontend with serve..."
        Start-Process -FilePath "serve" -ArgumentList "-s", "build", "-l", "3000" -WindowStyle Hidden
    }
    catch {
        Write-Status "Installing serve globally..."
        npm install -g serve
        Start-Process -FilePath "serve" -ArgumentList "-s", "build", "-l", "3000" -WindowStyle Hidden
    }
    
    Set-Location ..
    
    Write-Success "🎉 Simple Demo started!"
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "🌐 Demo URLs:"
    Write-Host "=========================================="
    Write-Host "Frontend: http://localhost:3000"
    Write-Host "RabbitMQ Management: http://localhost:15672 (admin/admin123)"
    Write-Host "PostgreSQL: localhost:5432 (postgresadmin/admin123)"
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "🧪 Test Demo:"
    Write-Host "=========================================="
    Write-Host "1. Open http://localhost:3000"
    Write-Host "2. Go to 'Transfer Money' page"
    Write-Host "3. Select accounts and amount"
    Write-Host "4. Click 'Transfer Money'"
    Write-Host "5. Check 'Transactions' page for results"
    Write-Host ""
    Write-Host "Note: This is a frontend-only demo with mock data"
    Write-Host "Backend services are not running"
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "🛑 Stop Demo:"
    Write-Host "=========================================="
    Write-Host "docker-compose down"
    Write-Host "taskkill /f /im node.exe"
    Write-Host ""
    Write-Warning "💡 Frontend demo is running with mock data!"
}

# Main function
function Main {
    Write-Host "=========================================="
    Write-Host "🚀 Simple Demo Script"
    Write-Host "=========================================="
    Write-Host ""
    
    if ($Help) {
        Show-Help
        exit 0
    }
    
    Start-SimpleDemo
}

# Run main function
Main
