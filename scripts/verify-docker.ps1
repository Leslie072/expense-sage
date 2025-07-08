# Docker verification script for Windows
Write-Host "🐳 Verifying Docker Installation..." -ForegroundColor Green

# Check Docker version
Write-Host "`n1. Checking Docker version..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker installed: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker not found. Please install Docker Desktop." -ForegroundColor Red
    exit 1
}

# Check Docker Compose version
Write-Host "`n2. Checking Docker Compose version..." -ForegroundColor Yellow
try {
    $composeVersion = docker-compose --version
    Write-Host "✅ Docker Compose available: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker Compose not found." -ForegroundColor Red
    exit 1
}

# Check if Docker daemon is running
Write-Host "`n3. Checking Docker daemon..." -ForegroundColor Yellow
try {
    docker ps | Out-Null
    Write-Host "✅ Docker daemon is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker daemon not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Test Docker with hello-world
Write-Host "`n4. Testing Docker with hello-world..." -ForegroundColor Yellow
try {
    docker run --rm hello-world | Out-Null
    Write-Host "✅ Docker is working correctly" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker test failed" -ForegroundColor Red
    exit 1
}

Write-Host "`n🎉 Docker is ready! You can now run the deployment." -ForegroundColor Green
Write-Host "Next step: Run './scripts/deploy.sh' or 'docker-compose up -d'" -ForegroundColor Cyan
