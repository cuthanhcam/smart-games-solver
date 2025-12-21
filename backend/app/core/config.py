from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    # App Settings
    PROJECT_NAME: str = "Rubik Cube Solver API"
    VERSION: str = "1.0.0"
    DEBUG: bool = True
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # CORS Settings
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8080",
    ]
    
    # Upload Settings
    MAX_UPLOAD_SIZE: int = 10 * 1024 * 1024  # 10MB
    ALLOWED_IMAGE_EXTENSIONS: List[str] = [".jpg", ".jpeg", ".png"]
    
    # Cube Settings
    CUBE_SIZE: int = 3
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
