# Smart Games Solver - Backend Quick Start Script
# Windows PowerShell Script

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Smart Games Solver - Backend Server  " -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to backend directory
$backendPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $backendPath

# Check if virtual environment exists
if (-not (Test-Path "venv")) {
    Write-Host "❌ Virtual environment not found!" -ForegroundColor Red
    Write-Host "Please run: python -m venv venv" -ForegroundColor Yellow
    exit 1
}

# Activate virtual environment
Write-Host "🔧 Activating virtual environment..." -ForegroundColor Yellow
& .\venv\Scripts\Activate.ps1

# Check if .env exists
if (-not (Test-Path ".env")) {
    Write-Host "⚠️  .env file not found! Copying from .env.example..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    Write-Host "✅ Created .env file. Please update DATABASE_URL if needed." -ForegroundColor Green
}

# Check PostgreSQL connection
Write-Host "🔍 Checking PostgreSQL connection..." -ForegroundColor Yellow
try {
    $null = Get-Service | Where-Object {$_.Name -like "*postgres*" -and $_.Status -eq "Running"}
    Write-Host "✅ PostgreSQL service is running!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  PostgreSQL service not detected. Please make sure it's running." -ForegroundColor Yellow
}

# Start backend server
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🚀 Starting Backend Server..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📡 API Documentation: http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host "🏥 Health Check: http://localhost:8000/health" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Run uvicorn
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
