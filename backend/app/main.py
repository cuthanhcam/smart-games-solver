import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.endpoints import detection, solver

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Backend API for Rubik's Cube Solver",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(detection.router, prefix="/api", tags=["detection"])
app.include_router(solver.router, prefix="/api", tags=["solver"])


@app.get("/")
async def root():
    return {
        "message": "Rubik Cube Solver API",
        "version": settings.VERSION,
        "docs": "/docs",
    }


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
    )
