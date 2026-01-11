"""
Application configuration
"""
from pydantic_settings import BaseSettings
from typing import List, Union
from pydantic import field_validator


class Settings(BaseSettings):
    # App Settings
    PROJECT_NAME: str = "Multi-Game Platform API"
    VERSION: str = "2.0.0"
    DEBUG: bool = True
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # Database
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/smart_game_db"
    
    # Security
    SECRET_KEY: str = "your-secret-key-change-this-in-production-2024"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # CORS Settings
    ALLOWED_ORIGINS: Union[List[str], str] = ["*"]
    
    @field_validator('ALLOWED_ORIGINS', mode='before')
    @classmethod
    def parse_cors(cls, v):
        if isinstance(v, str):
            if v == "*":
                return ["*"]
            return [origin.strip() for origin in v.split(',')]
        return v
    
    # Upload Settings
    MAX_UPLOAD_SIZE: int = 10 * 1024 * 1024  # 10MB
    ALLOWED_IMAGE_EXTENSIONS: List[str] = [".jpg", ".jpeg", ".png"]
    
    # Cube Settings
    CUBE_SIZE: int = 3
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
