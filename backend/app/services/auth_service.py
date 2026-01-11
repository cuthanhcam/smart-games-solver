"""
Authentication Service
Business logic cho authentication và user management
"""
from typing import Optional
from datetime import datetime, timedelta
from sqlalchemy.orm import Session

from ..core.security import (
    generate_salt,
    hash_password,
    verify_password,
    create_access_token
)
from ..models.user import User
from ..models.schemas import UserRegisterRequest, UserLoginRequest, TokenResponse, UserResponse
from ..repositories.user_repository import user_repository
from ..core.exceptions import (
    AuthenticationError,
    UserAlreadyExistsError,
    UserNotFoundError,
    UserBannedError
)


class AuthService:
    """
    Service layer cho authentication
    Chứa toàn bộ business logic, tách biệt khỏi data access và HTTP layer
    """
    
    def __init__(self):
        self.user_repo = user_repository
    
    def register_user(
        self, 
        db: Session, 
        request: UserRegisterRequest
    ) -> TokenResponse:
        """
        Đăng ký user mới
        
        Business Rules:
        - Username và email phải unique
        - Password được hash với salt ngẫu nhiên
        - User mới không phải admin
        - Tự động login sau khi đăng ký
        """
        # Check if username exists
        if self.user_repo.check_username_exists(db, request.username):
            raise UserAlreadyExistsError(f"Username '{request.username}' đã tồn tại")
        
        # Check if email exists
        if self.user_repo.check_email_exists(db, request.email):
            raise UserAlreadyExistsError(f"Email '{request.email}' đã tồn tại")
        
        # Generate salt and hash password
        salt = generate_salt()
        password_hash = hash_password(request.password, salt)
        
        # Create user
        user = User(
            username=request.username.strip(),
            email=request.email.strip(),
            password_hash=password_hash,
            salt=salt,
            is_admin=False,
            is_banned=False
        )
        
        db.add(user)
        db.commit()
        db.refresh(user)
        
        # Create access token
        access_token = create_access_token(
            data={"user_id": user.id, "username": user.username}
        )
        
        return TokenResponse(
            access_token=access_token,
            token_type="bearer",
            user=UserResponse.from_orm(user)
        )
    
    def login_user(
        self, 
        db: Session, 
        request: UserLoginRequest
    ) -> TokenResponse:
        """
        Đăng nhập user
        
        Business Rules:
        - Tìm user theo username hoặc email
        - Verify password
        - Check ban status
        - Tự động unban nếu hết thời gian
        """
        # Find user by username or email
        user = self.user_repo.get_by_username_or_email(
            db, 
            request.username_or_email.strip()
        )
        
        if not user:
            raise UserNotFoundError("Tài khoản không tồn tại")
        
        # Verify password
        if not verify_password(request.password, user.password_hash, user.salt):
            raise AuthenticationError("Mật khẩu không đúng")
        
        # Check ban status
        if user.is_banned and user.banned_until:
            now = datetime.utcnow()
            
            if now < user.banned_until:
                # User is still banned
                remaining = user.banned_until - now
                time_str = self._format_remaining_time(remaining)
                
                raise UserBannedError(
                    f"Tài khoản đã bị cấm trong vòng {time_str}. "
                    f"Lý do: {user.ban_reason or 'Không có lý do'}"
                )
            else:
                # Ban period expired, unban automatically
                user.is_banned = False
                user.banned_until = None
                user.ban_reason = None
                db.commit()
        
        # Create access token
        access_token = create_access_token(
            data={"user_id": user.id, "username": user.username}
        )
        
        return TokenResponse(
            access_token=access_token,
            token_type="bearer",
            user=UserResponse.from_orm(user)
        )
    
    def get_current_user(
        self, 
        db: Session, 
        user_id: int
    ) -> User:
        """
        Lấy thông tin user hiện tại
        
        Business Rules:
        - Tự động unban nếu hết thời gian
        """
        user = self.user_repo.get_by_id(db, user_id)
        
        if not user:
            raise UserNotFoundError("User không tồn tại")
        
        # Check and auto-unban if needed
        if user.is_banned and user.banned_until:
            now = datetime.utcnow()
            if now >= user.banned_until:
                user.is_banned = False
                user.banned_until = None
                user.ban_reason = None
                db.commit()
        
        return user
    
    def ban_user(
        self,
        db: Session,
        admin_id: int,
        user_id: int,
        duration_minutes: int,
        reason: str
    ) -> User:
        """
        Ban user (chỉ admin)
        
        Business Rules:
        - Chỉ admin mới có thể ban
        - Không thể ban chính mình
        - Không thể ban admin khác
        """
        # Get admin user
        admin = self.user_repo.get_by_id(db, admin_id)
        if not admin or not admin.is_admin:
            raise AuthenticationError("Chỉ admin mới có quyền ban user")
        
        # Get target user
        user = self.user_repo.get_by_id(db, user_id)
        if not user:
            raise UserNotFoundError("User không tồn tại")
        
        # Cannot ban yourself
        if admin_id == user_id:
            raise AuthenticationError("Không thể ban chính mình")
        
        # Cannot ban other admins
        if user.is_admin:
            raise AuthenticationError("Không thể ban admin khác")
        
        # Ban user
        user.is_banned = True
        user.banned_until = datetime.utcnow() + timedelta(minutes=duration_minutes)
        user.ban_reason = reason
        
        db.commit()
        db.refresh(user)
        
        return user
    
    def unban_user(
        self,
        db: Session,
        admin_id: int,
        user_id: int
    ) -> User:
        """
        Unban user (chỉ admin)
        """
        # Get admin user
        admin = self.user_repo.get_by_id(db, admin_id)
        if not admin or not admin.is_admin:
            raise AuthenticationError("Chỉ admin mới có quyền unban user")
        
        # Get target user
        user = self.user_repo.get_by_id(db, user_id)
        if not user:
            raise UserNotFoundError("User không tồn tại")
        
        # Unban user
        user.is_banned = False
        user.banned_until = None
        user.ban_reason = None
        
        db.commit()
        db.refresh(user)
        
        return user
    
    def delete_user(
        self,
        db: Session,
        admin_id: int,
        user_id: int
    ) -> bool:
        """
        Xóa user (chỉ admin)
        
        Business Rules:
        - Chỉ admin mới có quyền xóa
        - Không thể xóa chính mình
        """
        # Get admin user
        admin = self.user_repo.get_by_id(db, admin_id)
        if not admin or not admin.is_admin:
            raise AuthenticationError("Chỉ admin mới có quyền xóa user")
        
        # Cannot delete yourself
        if admin_id == user_id:
            raise AuthenticationError("Không thể xóa chính mình")
        
        # Delete user
        return self.user_repo.delete(db, user_id)
    
    @staticmethod
    def _format_remaining_time(delta: timedelta) -> str:
        """Format timedelta thành chuỗi dễ đọc"""
        total_seconds = int(delta.total_seconds())
        
        if total_seconds < 60:
            return f"{total_seconds} giây"
        elif total_seconds < 3600:
            minutes = total_seconds // 60
            return f"{minutes} phút"
        else:
            hours = total_seconds // 3600
            return f"{hours} giờ"


# Singleton instance
auth_service = AuthService()
