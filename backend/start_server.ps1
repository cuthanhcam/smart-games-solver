# Start Backend Server Script (Windows PowerShell)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   Rubik Cube Solver - Backend Server" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to backend directory
Set-Location $PSScriptRoot

# Check if requirements are installed
Write-Host "Checking dependencies..." -ForegroundColor Yellow
try {
    python -c "import fastapi, uvicorn, kociemba" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Installing dependencies..." -ForegroundColor Yellow
        pip install -r requirements.txt
    }
} catch {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    pip install -r requirements.txt
}

# Start server
Write-Host ""
Write-Host "Starting FastAPI server at http://localhost:8000" -ForegroundColor Green
Write-Host "API Documentation: http://localhost:8000/docs" -ForegroundColor Green
Write-Host ""
Write-Host "Press CTRL+C to stop the server" -ForegroundColor Yellow
Write-Host ""

$env:PYTHONPATH = $PSScriptRoot
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
