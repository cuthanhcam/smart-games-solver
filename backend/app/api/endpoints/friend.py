"""
Friend Management Endpoints
Xử lý lời mời kết bạn, danh sách bạn bè, tìm kiếm user
"""
from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from typing import List

from ...core.database import get_db
from ...core.dependencies import get_current_user
from ...models.user import User
from ...models.game import Friendship
from ...models.schemas import (
    FriendshipResponse,
    UserSearchResponse,
    FriendListResponse,
    SendFriendRequestRequest,
    AcceptFriendRequestRequest,
    RejectFriendRequestRequest,
    RemoveFriendRequest,
)

router = APIRouter(prefix="/friends", tags=["Friends"])


@router.get("/search", response_model=List[UserSearchResponse])
async def search_users(
    query: str,
    skip: int = 0,
    limit: int = 10,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Search users by username or email
    Exclude current user and already friends from results
    """
    # Find users by username or email, exclude current user
    users = db.query(User).filter(
        (User.username.ilike(f"%{query}%") | User.email.ilike(f"%{query}%")),
        User.id != current_user.id,
        User.is_banned == False
    ).offset(skip).limit(limit).all()

    return [UserSearchResponse.from_orm(user) for user in users]


@router.get("/list", response_model=List[FriendListResponse])
async def get_friends(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get all accepted friends of current user
    """
    friendships = db.query(Friendship).filter(
        (Friendship.user_id == current_user.id) | (Friendship.friend_id == current_user.id),
        Friendship.status == 'accepted'
    ).all()

    friends_list = []
    for friendship in friendships:
        friend_id = friendship.friend_id if friendship.user_id == current_user.id else friendship.user_id
        friend = db.query(User).filter(User.id == friend_id).first()
        if friend:
            friends_list.append(
                FriendListResponse(
                    id=friend.id,
                    username=friend.username,
                    email=friend.email,
                    friend_id=friend.id,
                    created_at=friendship.created_at
                )
            )
    
    return friends_list


@router.get("/requests/incoming", response_model=List[dict])
async def get_incoming_friend_requests(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get all pending friend requests received by current user
    """
    requests = db.query(Friendship).filter(
        Friendship.friend_id == current_user.id,
        Friendship.status == 'pending'
    ).all()

    result = []
    for req in requests:
        sender = db.query(User).filter(User.id == req.user_id).first()
        if sender:
            result.append({
                "id": req.id,
                "sender_id": sender.id,
                "username": sender.username,
                "email": sender.email,
                "created_at": req.created_at
            })
    
    return result


@router.get("/requests/outgoing", response_model=List[dict])
async def get_outgoing_friend_requests(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get all pending friend requests sent by current user
    """
    requests = db.query(Friendship).filter(
        Friendship.user_id == current_user.id,
        Friendship.status == 'pending'
    ).all()

    result = []
    for req in requests:
        receiver = db.query(User).filter(User.id == req.friend_id).first()
        if receiver:
            result.append({
                "id": req.id,
                "receiver_id": receiver.id,
                "username": receiver.username,
                "email": receiver.email,
                "created_at": req.created_at
            })
    
    return result


@router.post("/request", response_model=dict, status_code=status.HTTP_201_CREATED)
async def send_friend_request(
    request: SendFriendRequestRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Send a friend request to another user
    """
    # Check if receiver exists
    receiver = db.query(User).filter(User.id == request.receiver_id).first()
    if not receiver:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if already friends
    existing_friendship = db.query(Friendship).filter(
        ((Friendship.user_id == current_user.id) & (Friendship.friend_id == request.receiver_id)) |
        ((Friendship.user_id == request.receiver_id) & (Friendship.friend_id == current_user.id))
    ).first()
    
    if existing_friendship and existing_friendship.status == 'accepted':
        raise HTTPException(status_code=400, detail="Already friends with this user")
    
    # Remove old requests if any
    if existing_friendship:
        db.delete(existing_friendship)
        db.commit()

    # Create new friendship request
    friendship = Friendship(
        user_id=current_user.id,
        friend_id=request.receiver_id,
        status='pending'
    )
    db.add(friendship)
    db.commit()
    db.refresh(friendship)

    return {"message": "Friend request sent successfully", "friendship_id": friendship.id}


@router.post("/request/accept", response_model=dict)
async def accept_friend_request(
    request: AcceptFriendRequestRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Accept a pending friend request
    """
    friendship = db.query(Friendship).filter(
        Friendship.id == request.friendship_id,
        Friendship.friend_id == current_user.id,
        Friendship.status == 'pending'
    ).first()

    if not friendship:
        raise HTTPException(status_code=404, detail="Friend request not found")

    # Update status
    friendship.status = 'accepted'
    db.commit()

    return {"message": "Friend request accepted"}


@router.post("/request/reject", response_model=dict)
async def reject_friend_request(
    request: RejectFriendRequestRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Reject a pending friend request
    """
    friendship = db.query(Friendship).filter(
        Friendship.id == request.friendship_id,
        Friendship.friend_id == current_user.id,
        Friendship.status == 'pending'
    ).first()

    if not friendship:
        raise HTTPException(status_code=404, detail="Friend request not found")

    friendship.status = 'rejected'
    db.commit()

    return {"message": "Friend request rejected"}


@router.delete("/remove/{friend_id}", response_model=dict)
async def remove_friend(
    friend_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Remove a friend from your friend list
    """
    friendship = db.query(Friendship).filter(
        or_(
            and_(Friendship.user_id == current_user.id, Friendship.friend_id == friend_id),
            and_(Friendship.user_id == friend_id, Friendship.friend_id == current_user.id)
        ),
        Friendship.status == 'accepted'
    ).first()

    if not friendship:
        raise HTTPException(status_code=404, detail="Friendship not found")

    db.delete(friendship)
    db.commit()

    return {"message": "Friend removed successfully"}


@router.get("/status/{user_id}", response_model=dict)
async def get_friendship_status(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get friendship status between current user and another user
    Returns: 'friends', 'pending_received', 'pending_sent', 'none'
    """
    # Check if they are friends
    friendship = db.query(Friendship).filter(
        or_(
            and_(Friendship.user_id == current_user.id, Friendship.friend_id == user_id),
            and_(Friendship.user_id == user_id, Friendship.friend_id == current_user.id)
        )
    ).first()

    if not friendship:
        return {"status": "none"}

    if friendship.status == 'accepted':
        return {"status": "friends"}
    elif friendship.status == 'pending':
        if friendship.user_id == current_user.id:
            return {"status": "pending_sent"}
        else:
            return {"status": "pending_received", "friendship_id": friendship.id}
    else:
        return {"status": "rejected"}
