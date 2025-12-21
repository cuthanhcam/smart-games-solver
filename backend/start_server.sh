#!/bin/bash

# Start Backend Server Script

echo "========================================="
echo "   Rubik Cube Solver - Backend Server"
echo "========================================="
echo ""

# Navigate to backend directory
cd "$(dirname "$0")"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Start server
echo ""
echo "Starting FastAPI server at http://localhost:8000"
echo "API Documentation: http://localhost:8000/docs"
echo ""
echo "Press CTRL+C to stop the server"
echo ""

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
