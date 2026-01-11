"""
Base Repository Interface
Định nghĩa các operations cơ bản cho tất cả repositories
"""
from abc import ABC, abstractmethod
from typing import Generic, TypeVar, Optional, List
from sqlalchemy.orm import Session

ModelType = TypeVar("ModelType")
CreateSchemaType = TypeVar("CreateSchemaType")
UpdateSchemaType = TypeVar("UpdateSchemaType")


class BaseRepository(Generic[ModelType, CreateSchemaType, UpdateSchemaType], ABC):
    """
    Base repository với CRUD operations cơ bản
    """
    
    def __init__(self, model: type[ModelType]):
        self.model = model
    
    @abstractmethod
    def get_by_id(self, db: Session, id: int) -> Optional[ModelType]:
        """Lấy entity theo ID"""
        pass
    
    @abstractmethod
    def get_all(
        self, 
        db: Session, 
        skip: int = 0, 
        limit: int = 100
    ) -> List[ModelType]:
        """Lấy danh sách entities"""
        pass
    
    @abstractmethod
    def create(self, db: Session, obj_in: CreateSchemaType) -> ModelType:
        """Tạo entity mới"""
        pass
    
    @abstractmethod
    def update(
        self, 
        db: Session, 
        db_obj: ModelType, 
        obj_in: UpdateSchemaType
    ) -> ModelType:
        """Cập nhật entity"""
        pass
    
    @abstractmethod
    def delete(self, db: Session, id: int) -> bool:
        """Xóa entity"""
        pass
    
    @abstractmethod
    def count(self, db: Session) -> int:
        """Đếm số lượng entities"""
        pass
