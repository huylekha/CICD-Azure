#!/usr/bin/env pwsh
# Comprehensive test script for all services

$ErrorActionPreference = "Continue"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "        Service Test Suite" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$testsPassed = 0
$testsFailed = 0

# Test Backend
Write-Host "[TEST 1] Backend Service (PaymentService)" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "http://localhost:5001/api/demo/health" -TimeoutSec 5
    Write-Host "  Health Endpoint:" -NoNewline
    Write-Host " PASSED" -ForegroundColor Green
    $testsPassed++
} catch {
    Write-Host "  Health Endpoint:" -NoNewline
    Write-Host " FAILED - Backend not running?" -ForegroundColor Red
    $testsFailed++
}

try {
    $accounts = Invoke-RestMethod -Uri "http://localhost:5001/api/demo/accounts" -TimeoutSec 5
    Write-Host "  Demo Accounts:" -NoNewline
    Write-Host " PASSED ($($accounts.Count) accounts)" -ForegroundColor Green
    $testsPassed++
} catch {
    Write-Host "  Demo Accounts:" -NoNewline
    Write-Host " FAILED" -ForegroundColor Red
    $testsFailed++
}

try {
    $transactions = Invoke-RestMethod -Uri "http://localhost:5001/api/demo/transactions" -TimeoutSec 5
    Write-Host "  Demo Transactions:" -NoNewline
    Write-Host " PASSED ($($transactions.Count) transactions)" -ForegroundColor Green
    $testsPassed++
} catch {
    Write-Host "  Demo Transactions:" -NoNewline
    Write-Host " FAILED" -ForegroundColor Red
    $testsFailed++
}

try {
    $body = @{
        fromAccountId = [Guid]::NewGuid().ToString()
        toAccountId = [Guid]::NewGuid().ToString()
        amount = 100
        currency = "USD"
    } | ConvertTo-Json
    
    $result = Invoke-RestMethod -Uri "http://localhost:5001/api/demo/transfer" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 10
    Write-Host "  Transfer API:" -NoNewline
    if ($result.success) {
        Write-Host " PASSED" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "  Transfer API:" -NoNewline
    Write-Host " FAILED" -ForegroundColor Red
    $testsFailed++
}

try {
    $response = Invoke-WebRequest -Uri "http://localhost:5001/swagger/index.html" -TimeoutSec 5 -UseBasicParsing
    Write-Host "  Swagger UI:" -NoNewline
    if ($response.StatusCode -eq 200) {
        Write-Host " PASSED" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "  Swagger UI:" -NoNewline
    Write-Host " FAILED" -ForegroundColor Red
    $testsFailed++
}

Write-Host ""

# Test Frontend
Write-Host "[TEST 2] Frontend Service (React)" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5 -UseBasicParsing
    Write-Host "  Frontend Root:" -NoNewline
    if ($response.StatusCode -eq 200) {
        Write-Host " PASSED" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "  Frontend Root:" -NoNewline
    Write-Host " FAILED - Frontend not running?" -ForegroundColor Red
    $testsFailed++
}

Write-Host ""

# Test Infrastructure
Write-Host "[TEST 3] Infrastructure Services" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri "http://localhost:15672" -TimeoutSec 5 -UseBasicParsing
    Write-Host "  RabbitMQ Management:" -NoNewline
    if ($response.StatusCode -eq 200) {
        Write-Host " PASSED" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "  RabbitMQ Management:" -NoNewline
    Write-Host " FAILED - RabbitMQ not running?" -ForegroundColor Red
    $testsFailed++
}

try {
    docker exec cicd-azure-postgres psql -U postgresadmin -d postgres -c "SELECT 1" 2>&1 | Out-Null
    Write-Host "  PostgreSQL:" -NoNewline
    if ($LASTEXITCODE -eq 0) {
        Write-Host " PASSED" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "  PostgreSQL:" -NoNewline
    Write-Host " FAILED - PostgreSQL not running?" -ForegroundColor Red
    $testsFailed++
}

Write-Host ""

# Summary
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "           Test Summary" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Tests Passed:  " -NoNewline
Write-Host "$testsPassed" -ForegroundColor Green
Write-Host "Tests Failed:  " -NoNewline
Write-Host "$testsFailed" -ForegroundColor Red
Write-Host "Total Tests:   $($testsPassed + $testsFailed)"
Write-Host ""

$successRate = if (($testsPassed + $testsFailed) -gt 0) { 
    [math]::Round(($testsPassed / ($testsPassed + $testsFailed)) * 100, 2) 
} else { 
    0 
}

Write-Host "Success Rate:  " -NoNewline
if ($successRate -ge 80) {
    Write-Host "$successRate%" -ForegroundColor Green
} elseif ($successRate -ge 60) {
    Write-Host "$successRate%" -ForegroundColor Yellow
} else {
    Write-Host "$successRate%" -ForegroundColor Red
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

if ($testsFailed -gt 0) {
    Write-Host "To start missing services:" -ForegroundColor Yellow
    Write-Host "  Backend:  cd src/Services/PaymentService && dotnet run --urls http://localhost:5001"
    Write-Host "  Frontend: cd frontend && npm start"
    Write-Host "  Docker:   docker-compose -f docker-compose.dev.yml up -d"
    Write-Host ""
}

if ($testsFailed -eq 0) {
    Write-Host "All services are running correctly!" -ForegroundColor Green
    exit 0
} else {
    exit 1
}