"""
FastAPI Main Application - Multi-Game Platform with Rubik Solver
Clean Architecture Implementation
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from sqlalchemy.exc import SQLAlchemyError
import uvicorn
import sys
import os

# Add app directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.config import settings
from app.core.database import init_db, engine
from app.core.exceptions import AppException
from app.core.exception_handlers import (
    app_exception_handler,
    validation_exception_handler,
    sqlalchemy_exception_handler,
    generic_exception_handler
)
from app.models import user, game  # Import models to register them

# Import routers
from app.api.endpoints import auth, rubik, game_2048, sudoku, caro, friend, message, announcement, admin

# Create FastAPI app
app = FastAPI(
    title="Multi-Game Platform API",
    description="""
    ## 🎮 Multi-Game Platform with Clean Architecture
    
    Backend API cung cấp các game:
    - **2048**: Classic number puzzle game
    - **Sudoku**: Logic-based puzzle (Easy/Medium/Hard)
    - **Caro (Gomoku)**: Five in a row game
    - **Rubik Cube Solver**: Manual color input solver using Kociemba algorithm
    
    ### Architecture
    - **Clean Architecture** với separation of concerns
    - **Repository Pattern** cho data access
    - **Service Layer** cho business logic
    - **Dependency Injection** cho loose coupling
    - **Exception Handling** với custom exceptions
    
    ### Authentication
    JWT-based authentication với:
    - User registration/login
    - Token-based access
    - Role-based authorization (User/Admin)
    - Ban/unban system
    """,
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    contact={
        "name": "Development Team",
        "email": "dev@rubikgame.com"
    },
    license_info={
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT"
    }
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register exception handlers
app.add_exception_handler(AppException, app_exception_handler)
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(SQLAlchemyError, sqlalchemy_exception_handler)
app.add_exception_handler(Exception, generic_exception_handler)


@app.on_event("startup")
async def startup_event():
    """Initialize database on startup"""
    print("🚀 Starting Multi-Game Platform API...")
    print(f"📋 Environment: {'Development' if settings.DEBUG else 'Production'}")
    init_db()
    print("✅ Database initialized successfully")


@app.get("/", tags=["Root"])
async def root():
    """Root endpoint with API information"""
    return {
        "message": "Welcome to Multi-Game Platform API",
        "version": "2.0.0",
        "architecture": "Clean Architecture",
        "games": ["2048", "Sudoku", "Caro", "Rubik Solver"],
        "features": [
            "JWT Authentication",
            "User Management",
            "Game Leaderboards",
            "Activity Logging",
            "Admin Panel"
        ],
        "endpoints": {
            "docs": "/docs",
            "health": "/health",
            "auth": "/api/auth",
            "games": "/api/games"
        }
    }


@app.get("/health", tags=["Health"])
async def health_check():
    """
    Health check endpoint
    Kiểm tra kết nối database và trạng thái service
    """
    try:
        # Test database connection
        from sqlalchemy import text
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        
        return {
            "status": "healthy",
            "version": "2.0.0",
            "database": "connected",
            "services": {
                "auth": "up",
                "games": "up",
                "rubik_solver": "up"
            }
        }
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={
                "status": "unhealthy",
                "version": "2.0.0",
                "database": "disconnected",
                "error": str(e)
            }
        )


# Include routers
app.include_router(auth.router, prefix="/api")
app.include_router(admin.router, prefix="/api")
app.include_router(rubik.router, prefix="/api")
app.include_router(friend.router, prefix="/api")
app.include_router(message.router, prefix="/api")
app.include_router(announcement.router, prefix="/api")
app.include_router(game_2048.router, prefix="/api/games")
app.include_router(sudoku.router, prefix="/api/games")
app.include_router(caro.router, prefix="/api/games")


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
    )
