"""
Security utilities for password hashing and JWT token management
"""
import os
import hashlib
import secrets
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from dotenv import load_dotenv

load_dotenv()

# JWT Configuration
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-this-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 days

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def generate_salt(length: int = 16) -> str:
    """Generate a random salt for password hashing"""
    return secrets.token_hex(length)


def hash_password(password: str, salt: str) -> str:
    """
    Hash password using SHA-256 with salt
    Hash = SHA-256(salt + password)
    """
    combined = f"{salt}{password}".encode('utf-8')
    return hashlib.sha256(combined).hexdigest()


def verify_password(plain_password: str, hashed_password: str, salt: str) -> bool:
    """Verify a password against its hash"""
    return hash_password(plain_password, salt) == hashed_password


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create a JWT access token"""
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def decode_access_token(token: str) -> Optional[dict]:
    """Decode and validate a JWT access token"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return None


def get_password_hash(password: str) -> str:
    """Hash password using bcrypt (alternative method)"""
    return pwd_context.hash(password)


def verify_password_bcrypt(plain_password: str, hashed_password: str) -> bool:
    """Verify password using bcrypt (alternative method)"""
    return pwd_context.verify(plain_password, hashed_password)
