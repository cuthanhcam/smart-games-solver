"""
Announcement Endpoints
Xử lý tạo, cập nhật, xóa, và lấy thông báo
"""
from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from typing import List

from ...core.database import get_db
from ...core.dependencies import get_current_user, get_current_admin_user
from ...models.user import User
from ...models.game import Announcement
from ...models.schemas import (
    CreateAnnouncementRequest,
    UpdateAnnouncementRequest,
    AnnouncementResponse,
)

router = APIRouter(prefix="/announcements", tags=["Announcements"])


@router.post("/create", response_model=AnnouncementResponse, status_code=status.HTTP_201_CREATED)
async def create_announcement(
    request: CreateAnnouncementRequest,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    Create a new announcement (admin only)
    """
    announcement = Announcement(
        admin_id=admin_user.id,
        title=request.title,
        content=request.content,
        type=request.type,
        is_active=True
    )
    db.add(announcement)
    db.commit()
    db.refresh(announcement)

    return AnnouncementResponse.from_orm(announcement)


@router.get("/list", response_model=List[AnnouncementResponse])
async def get_announcements(
    skip: int = 0,
    limit: int = 20,
    active_only: bool = True,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get all announcements
    - Users see only active announcements
    - Admins see all announcements
    """
    query = db.query(Announcement)
    
    if not current_user.is_admin:
        query = query.filter(Announcement.is_active == True)
    elif active_only:
        query = query.filter(Announcement.is_active == True)
    
    announcements = query.order_by(Announcement.created_at.desc()).offset(skip).limit(limit).all()

    return [AnnouncementResponse.from_orm(a) for a in announcements]


@router.get("/{announcement_id}", response_model=AnnouncementResponse)
async def get_announcement(
    announcement_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get a specific announcement by ID
    """
    announcement = db.query(Announcement).filter(Announcement.id == announcement_id).first()

    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found")
    
    # Users can only see active announcements
    if not current_user.is_admin and not announcement.is_active:
        raise HTTPException(status_code=403, detail="This announcement is not active")

    return AnnouncementResponse.from_orm(announcement)


@router.patch("/{announcement_id}", response_model=AnnouncementResponse)
async def update_announcement(
    announcement_id: int,
    request: UpdateAnnouncementRequest,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    Update an announcement (admin only)
    """
    announcement = db.query(Announcement).filter(Announcement.id == announcement_id).first()

    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found")

    # Update only provided fields
    if request.title is not None:
        announcement.title = request.title
    if request.content is not None:
        announcement.content = request.content
    if request.type is not None:
        announcement.type = request.type
    if request.is_active is not None:
        announcement.is_active = request.is_active

    db.commit()
    db.refresh(announcement)

    return AnnouncementResponse.from_orm(announcement)


@router.delete("/{announcement_id}", response_model=dict)
async def delete_announcement(
    announcement_id: int,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    Delete an announcement (admin only)
    """
    announcement = db.query(Announcement).filter(Announcement.id == announcement_id).first()

    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found")

    db.delete(announcement)
    db.commit()

    return {"message": "Announcement deleted successfully"}


@router.post("/{announcement_id}/activate", response_model=AnnouncementResponse)
async def activate_announcement(
    announcement_id: int,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    Activate an announcement (admin only)
    """
    announcement = db.query(Announcement).filter(Announcement.id == announcement_id).first()

    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found")

    announcement.is_active = True
    db.commit()
    db.refresh(announcement)

    return AnnouncementResponse.from_orm(announcement)


@router.post("/{announcement_id}/deactivate", response_model=AnnouncementResponse)
async def deactivate_announcement(
    announcement_id: int,
    admin_user: User = Depends(get_current_admin_user),
    db: Session = Depends(get_db)
):
    """
    Deactivate an announcement (admin only)
    """
    announcement = db.query(Announcement).filter(Announcement.id == announcement_id).first()

    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found")

    announcement.is_active = False
    db.commit()
    db.refresh(announcement)

    return AnnouncementResponse.from_orm(announcement)
