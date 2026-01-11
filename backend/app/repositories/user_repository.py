"""
User Repository
Xử lý tất cả data access operations liên quan đến User
"""
from typing import Optional, List
from sqlalchemy.orm import Session
from sqlalchemy import or_, func

from ..models.user import User
from ..models.schemas import UserRegisterRequest
from .base import BaseRepository


class UserRepository(BaseRepository[User, UserRegisterRequest, dict]):
    """
    Repository pattern cho User entity
    Tách biệt data access logic khỏi business logic
    """
    
    def __init__(self):
        super().__init__(User)
    
    def get_by_id(self, db: Session, id: int) -> Optional[User]:
        """Lấy user theo ID"""
        return db.query(User).filter(User.id == id).first()
    
    def get_all(
        self, 
        db: Session, 
        skip: int = 0, 
        limit: int = 100
    ) -> List[User]:
        """Lấy danh sách users"""
        return db.query(User).offset(skip).limit(limit).all()
    
    def get_by_username(self, db: Session, username: str) -> Optional[User]:
        """Lấy user theo username"""
        return db.query(User).filter(User.username == username).first()
    
    def get_by_email(self, db: Session, email: str) -> Optional[User]:
        """Lấy user theo email"""
        return db.query(User).filter(User.email == email).first()
    
    def get_by_username_or_email(
        self, 
        db: Session, 
        username_or_email: str
    ) -> Optional[User]:
        """Lấy user theo username hoặc email"""
        return db.query(User).filter(
            or_(
                User.username == username_or_email,
                User.email == username_or_email
            )
        ).first()
    
    def create(self, db: Session, obj_in: UserRegisterRequest) -> User:
        """
        Tạo user mới
        Note: Password đã được hash ở service layer
        """
        db_user = User(
            username=obj_in.username,
            email=obj_in.email,
            password_hash=obj_in.password,  # Will be hashed in service
            salt="",  # Will be set in service
            is_admin=False,
            is_banned=False
        )
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user
    
    def update(self, db: Session, db_obj: User, obj_in: dict) -> User:
        """Cập nhật user"""
        for field, value in obj_in.items():
            if hasattr(db_obj, field):
                setattr(db_obj, field, value)
        db.commit()
        db.refresh(db_obj)
        return db_obj
    
    def delete(self, db: Session, id: int) -> bool:
        """Xóa user"""
        user = self.get_by_id(db, id)
        if user:
            db.delete(user)
            db.commit()
            return True
        return False
    
    def count(self, db: Session) -> int:
        """Đếm tổng số users"""
        return db.query(func.count(User.id)).scalar()
    
    def check_username_exists(self, db: Session, username: str) -> bool:
        """Kiểm tra username đã tồn tại"""
        return db.query(User).filter(User.username == username).first() is not None
    
    def check_email_exists(self, db: Session, email: str) -> bool:
        """Kiểm tra email đã tồn tại"""
        return db.query(User).filter(User.email == email).first() is not None
    
    def get_admins(self, db: Session) -> List[User]:
        """Lấy danh sách admin users"""
        return db.query(User).filter(User.is_admin == True).all()
    
    def get_banned_users(self, db: Session) -> List[User]:
        """Lấy danh sách users bị ban"""
        return db.query(User).filter(User.is_banned == True).all()


# Singleton instance
user_repository = UserRepository()
