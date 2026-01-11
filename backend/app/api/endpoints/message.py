"""
Message Endpoints
Xử lý gửi tin nhắn, lấy lịch sử chat, danh sách cuộc trò chuyện
"""
from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from typing import List

from ...core.database import get_db
from ...core.dependencies import get_current_user
from ...models.user import User
from ...models.game import Message, Friendship
from ...models.schemas import (
    SendMessageRequest,
    MessageResponse,
    ChatListResponse,
    MarkMessageAsReadRequest,
)

router = APIRouter(prefix="/messages", tags=["Messages"])


@router.post("/send", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def send_message(
    request: SendMessageRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Send a message to another user
    """
    # Check if receiver exists
    receiver = db.query(User).filter(User.id == request.receiver_id).first()
    if not receiver:
        raise HTTPException(status_code=404, detail="Receiver not found")

    # Create message
    message = Message(
        sender_id=current_user.id,
        receiver_id=request.receiver_id,
        content=request.content,
        is_read=False
    )
    db.add(message)
    db.commit()
    db.refresh(message)

    return MessageResponse.from_orm(message)


@router.get("/with/{user_id}", response_model=List[MessageResponse])
async def get_messages_with_user(
    user_id: int,
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get all messages between current user and another user
    Messages are sorted by creation date (newest last)
    """
    messages = db.query(Message).filter(
        or_(
            and_(Message.sender_id == current_user.id, Message.receiver_id == user_id),
            and_(Message.sender_id == user_id, Message.receiver_id == current_user.id)
        )
    ).order_by(Message.created_at.asc()).offset(skip).limit(limit).all()

    # Mark messages sent to current user as read
    for message in messages:
        if message.receiver_id == current_user.id and not message.is_read:
            message.is_read = True
    db.commit()

    return [MessageResponse.from_orm(msg) for msg in messages]


@router.get("/list", response_model=List[ChatListResponse])
async def get_chat_list(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get list of all chats (conversations) for current user
    Shows last message and unread count for each conversation
    """
    # Get all friends first
    friendships = db.query(Friendship).filter(
        or_(
            Friendship.user_id == current_user.id,
            Friendship.friend_id == current_user.id
        ),
        Friendship.status == 'accepted'
    ).all()

    chat_list = []
    processed_users = set()

    for friendship in friendships:
        other_user_id = friendship.friend_id if friendship.user_id == current_user.id else friendship.user_id
        
        if other_user_id in processed_users:
            continue
        processed_users.add(other_user_id)

        other_user = db.query(User).filter(User.id == other_user_id).first()
        if not other_user:
            continue

        # Get last message
        last_message = db.query(Message).filter(
            or_(
                and_(Message.sender_id == current_user.id, Message.receiver_id == other_user_id),
                and_(Message.sender_id == other_user_id, Message.receiver_id == current_user.id)
            )
        ).order_by(Message.created_at.desc()).first()

        # Count unread messages
        unread_count = db.query(Message).filter(
            Message.sender_id == other_user_id,
            Message.receiver_id == current_user.id,
            Message.is_read == False
        ).count()

        chat_list.append(ChatListResponse(
            user_id=other_user.id,
            username=other_user.username,
            email=other_user.email,
            last_message=last_message.content if last_message else None,
            last_message_time=last_message.created_at if last_message else None,
            is_read=last_message.is_read if last_message else True,
            is_sent_by_me=last_message.sender_id == current_user.id if last_message else False,
            unread_count=unread_count
        ))

    # Sort by last message time (newest first)
    chat_list.sort(key=lambda x: x.last_message_time or x.user_id, reverse=True)
    
    return chat_list


@router.post("/mark-read", response_model=dict)
async def mark_message_as_read(
    request: MarkMessageAsReadRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Mark a single message as read
    """
    message = db.query(Message).filter(
        Message.id == request.message_id,
        Message.receiver_id == current_user.id
    ).first()

    if not message:
        raise HTTPException(status_code=404, detail="Message not found")

    message.is_read = True
    db.commit()

    return {"message": "Message marked as read"}


@router.post("/mark-all-read/{user_id}", response_model=dict)
async def mark_all_messages_read(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Mark all messages from a specific user as read
    """
    messages = db.query(Message).filter(
        Message.sender_id == user_id,
        Message.receiver_id == current_user.id,
        Message.is_read == False
    ).all()

    for message in messages:
        message.is_read = True
    
    db.commit()

    return {"message": f"Marked {len(messages)} messages as read"}


@router.get("/unread-count", response_model=dict)
async def get_unread_count(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get total unread message count for current user
    """
    unread_count = db.query(Message).filter(
        Message.receiver_id == current_user.id,
        Message.is_read == False
    ).count()

    return {"unread_count": unread_count}


@router.delete("/delete/{message_id}", response_model=dict)
async def delete_message(
    message_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Delete a message (can only delete your own messages)
    """
    message = db.query(Message).filter(
        Message.id == message_id,
        Message.sender_id == current_user.id
    ).first()

    if not message:
        raise HTTPException(status_code=404, detail="Message not found or you don't have permission to delete it")

    db.delete(message)
    db.commit()

    return {"message": "Message deleted successfully"}
