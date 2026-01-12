"""
Admin Endpoints
Admin-only operations for managing users
"""
from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from typing import List

from ...core.database import get_db
from ...core.dependencies import get_current_admin_user
from ...models.user import User
from ...models.schemas import UserResponse

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/users", response_model=List[UserResponse])
async def get_all_users(
    skip: int = 0,
    limit: int = 100,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    Get all users (admin only)
    """
    users = db.query(User).offset(skip).limit(limit).all()
    return [UserResponse.from_orm(user) for user in users]


@router.get("/users/search", response_model=List[UserResponse])
async def search_users_admin(
    query: str,
    skip: int = 0,
    limit: int = 100,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    Search users by username or email (admin only)
    """
    users = db.query(User).filter(
        (User.username.ilike(f"%{query}%")) | (User.email.ilike(f"%{query}%"))
    ).offset(skip).limit(limit).all()
    
    return [UserResponse.from_orm(user) for user in users]


@router.patch("/users/{user_id}/admin-status", response_model=UserResponse)
async def update_user_admin_status(
    user_id: int,
    is_admin: bool,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    Update user admin status (admin only)
    Cannot remove admin status from yourself
    """
    target_user = db.query(User).filter(User.id == user_id).first()
    
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Prevent admin from removing their own admin status
    if target_user.id == admin_user.id and not is_admin:
        raise HTTPException(
            status_code=400, 
            detail="Cannot remove admin status from yourself"
        )
    
    target_user.is_admin = is_admin
    db.commit()
    db.refresh(target_user)
    
    return UserResponse.from_orm(target_user)


@router.delete("/users/{user_id}", status_code=status.HTTP_200_OK)
async def delete_user(
    user_id: int,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    Delete a user (admin only)
    Cannot delete yourself
    """
    target_user = db.query(User).filter(User.id == user_id).first()
    
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Prevent admin from deleting themselves
    if target_user.id == admin_user.id:
        raise HTTPException(
            status_code=400, 
            detail="Cannot delete yourself"
        )
    
    db.delete(target_user)
    db.commit()
    
    return {"message": "User deleted successfully"}
