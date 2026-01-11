"""
FastAPI Dependencies
Dependency Injection cho authentication và authorization
"""
from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from ..core.database import get_db
from ..core.security import decode_access_token
from ..core.exceptions import InvalidTokenError, PermissionDeniedError, UserBannedError
from ..models.user import User
from ..services.auth_service import auth_service
from datetime import datetime

# Security scheme
security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """
    Dependency để lấy current user từ JWT token
    
    Sử dụng:
        @router.get("/profile")
        async def get_profile(current_user: User = Depends(get_current_user)):
            return current_user
    """
    token = credentials.credentials
    
    # Decode token
    payload = decode_access_token(token)
    if payload is None:
        raise InvalidTokenError("Invalid or expired token")
    
    # Get user_id from payload
    user_id = payload.get("user_id")
    if user_id is None:
        raise InvalidTokenError("Invalid token payload")
    
    # Get user from database
    try:
        user = auth_service.get_current_user(db, user_id)
    except Exception as e:
        raise InvalidTokenError(str(e))
    
    # Check if user is banned
    if user.is_banned and user.banned_until:
        if datetime.utcnow() < user.banned_until:
            remaining = user.banned_until - datetime.utcnow()
            minutes = int(remaining.total_seconds() / 60)
            raise UserBannedError(
                f"User is banned. Remaining time: {minutes} minutes. "
                f"Reason: {user.ban_reason or 'No reason provided'}"
            )
    
    return user


async def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """
    Dependency để lấy current active user (không bị ban)
    
    Sử dụng:
        @router.post("/play")
        async def play_game(user: User = Depends(get_current_active_user)):
            # User is active and not banned
            pass
    """
    if current_user.is_banned:
        raise UserBannedError("User is banned")
    
    return current_user


async def get_current_admin_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """
    Dependency để verify user là admin
    
    Sử dụng:
        @router.delete("/users/{user_id}")
        async def delete_user(
            user_id: int,
            admin: User = Depends(get_current_admin_user)
        ):
            # Only admins can access this
            pass
    """
    if not current_user.is_admin:
        raise PermissionDeniedError("Admin access required")
    
    return current_user


async def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(HTTPBearer(auto_error=False)),
    db: Session = Depends(get_db)
) -> Optional[User]:
    """
    Dependency để lấy user (optional)
    Không throw exception nếu không có token
    
    Sử dụng cho public endpoints có thể access bởi guest hoặc authenticated user
    
    Sử dụng:
        @router.get("/leaderboard")
        async def get_leaderboard(user: Optional[User] = Depends(get_optional_user)):
            # Works for both authenticated and guest users
            pass
    """
    if credentials is None:
        return None
    
    try:
        token = credentials.credentials
        payload = decode_access_token(token)
        
        if payload is None:
            return None
        
        user_id = payload.get("user_id")
        if user_id is None:
            return None
        
        user = auth_service.get_current_user(db, user_id)
        return user
    except Exception:
        return None


class RateLimiter:
    """
    Rate limiter dependency
    Giới hạn số lượng requests trong một khoảng thời gian
    """
    
    def __init__(self, max_requests: int, window_seconds: int):
        """
        Args:
            max_requests: Số requests tối đa
            window_seconds: Khoảng thời gian (giây)
        """
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.requests = {}  # {user_id: [(timestamp, count)]}
    
    async def __call__(
        self,
        current_user: User = Depends(get_current_user)
    ):
        """Check rate limit cho user"""
        now = datetime.utcnow()
        user_id = current_user.id
        
        # Clean old requests
        if user_id in self.requests:
            self.requests[user_id] = [
                (ts, count) for ts, count in self.requests[user_id]
                if (now - ts).total_seconds() < self.window_seconds
            ]
        else:
            self.requests[user_id] = []
        
        # Count requests in window
        total_requests = sum(count for _, count in self.requests[user_id])
        
        if total_requests >= self.max_requests:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Rate limit exceeded. Max {self.max_requests} requests per {self.window_seconds} seconds"
            )
        
        # Add current request
        self.requests[user_id].append((now, 1))
