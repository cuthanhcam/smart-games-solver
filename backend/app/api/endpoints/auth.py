"""
Authentication Endpoints
Xử lý đăng ký, đăng nhập, đăng xuất
"""
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from ...core.database import get_db
from ...core.dependencies import (
    get_current_user,
    get_current_admin_user
)
from ...models.user import User
from ...models.schemas import (
    UserRegisterRequest,
    UserLoginRequest,
    TokenResponse,
    UserResponse
)
from ...services.auth_service import auth_service
from ...models.game import UserActivityLog

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Đăng ký tài khoản mới",
    description="""
    Đăng ký user mới với username, email và password.
    
    **Business Rules:**
    - Username phải unique và >= 3 ký tự
    - Email phải unique và hợp lệ
    - Password >= 6 ký tự
    - Tự động login sau khi đăng ký thành công
    """
)
async def register(
    request: UserRegisterRequest,
    db: Session = Depends(get_db)
):
    """
    Endpoint đăng ký user mới
    
    Returns:
        TokenResponse: JWT token và thông tin user
    """
    # Gọi service layer để xử lý business logic
    token_response = auth_service.register_user(db, request)
    
    # Log activity
    activity_log = UserActivityLog(
        user_id=token_response.user.id,
        activity_type="register",
        activity_data={"ip": "unknown"}
    )
    db.add(activity_log)
    db.commit()
    
    return token_response


@router.post(
    "/login",
    response_model=TokenResponse,
    summary="Đăng nhập",
    description="""
    Đăng nhập với username/email và password.
    
    **Business Rules:**
    - Có thể dùng username hoặc email
    - Check ban status
    - Tự động unban nếu hết thời gian
    """
)
async def login(
    request: UserLoginRequest,
    db: Session = Depends(get_db)
):
    """
    Endpoint đăng nhập
    
    Returns:
        TokenResponse: JWT token và thông tin user
    """
    # Gọi service layer
    token_response = auth_service.login_user(db, request)
    
    # Log activity
    activity_log = UserActivityLog(
        user_id=token_response.user.id,
        activity_type="login",
        activity_data={"ip": "unknown"}
    )
    db.add(activity_log)
    db.commit()
    
    return token_response


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Lấy thông tin user hiện tại",
    description="Lấy thông tin chi tiết của user đang đăng nhập"
)
async def get_current_user_info(
    current_user: User = Depends(get_current_user)
):
    """
    Endpoint lấy thông tin user hiện tại
    
    Requires:
        - Valid JWT token trong Authorization header
    
    Returns:
        UserResponse: Thông tin user
    """
    return UserResponse.from_orm(current_user)


@router.post(
    "/logout",
    summary="Đăng xuất",
    description="""
    Đăng xuất user hiện tại.
    
    Note: JWT tokens là stateless, nên logout chỉ log activity.
    Client phải tự xóa token.
    """
)
async def logout(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Endpoint đăng xuất
    
    Note: Token vẫn valid cho đến khi hết hạn.
    Client cần xóa token ở phía mình.
    """
    # Log activity
    activity_log = UserActivityLog(
        user_id=current_user.id,
        activity_type="logout",
        activity_data={"ip": "unknown"}
    )
    db.add(activity_log)
    db.commit()
    
    return {
        "success": True,
        "message": "Logged out successfully"
    }


# ========== Admin Endpoints ==========

@router.post(
    "/admin/ban-user/{user_id}",
    response_model=UserResponse,
    summary="Ban user (Admin only)",
    description="Admin có thể ban user trong một khoảng thời gian"
)
async def ban_user(
    user_id: int,
    duration_minutes: int,
    reason: str,
    admin: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    Ban user (chỉ admin)
    
    Args:
        user_id: ID của user cần ban
        duration_minutes: Thời gian ban (phút)
        reason: Lý do ban
    """
    banned_user = auth_service.ban_user(
        db=db,
        admin_id=admin.id,
        user_id=user_id,
        duration_minutes=duration_minutes,
        reason=reason
    )
    
    return UserResponse.from_orm(banned_user)


@router.post(
    "/admin/unban-user/{user_id}",
    response_model=UserResponse,
    summary="Unban user (Admin only)",
    description="Admin có thể unban user"
)
async def unban_user(
    user_id: int,
    admin: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    Unban user (chỉ admin)
    """
    unbanned_user = auth_service.unban_user(
        db=db,
        admin_id=admin.id,
        user_id=user_id
    )
    
    return UserResponse.from_orm(unbanned_user)


@router.delete(
    "/admin/delete-user/{user_id}",
    summary="Xóa user (Admin only)",
    description="Admin có thể xóa user"
)
async def delete_user(
    user_id: int,
    admin: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    Xóa user (chỉ admin)
    """
    success = auth_service.delete_user(
        db=db,
        admin_id=admin.id,
        user_id=user_id
    )
    
    return {
        "success": success,
        "message": "User deleted successfully" if success else "Failed to delete user"
    }
