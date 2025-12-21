@echo off
REM Start Backend Server Script (Windows CMD)

echo =========================================
echo    Rubik Cube Solver - Backend Server
echo =========================================
echo.

REM Navigate to backend directory
cd /d %~dp0

REM Check and install dependencies
echo Checking dependencies...
python -c "import fastapi, uvicorn, kociemba" 2>nul
if errorlevel 1 (
    echo Installing dependencies...
    pip install -r requirements.txt
)

REM Start server
echo.
echo Starting FastAPI server at http://localhost:8000
echo API Documentation: http://localhost:8000/docs
echo.
echo Press CTRL+C to stop the server
echo.

set PYTHONPATH=%~dp0
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
