"""
Leaderboard API endpoints
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional
from ...core.database import get_db
from ...core.dependencies import get_current_user
from ...models.user import User
from ...models.schemas import (
    LeaderboardResponse,
    LeaderboardEntryResponse,
    SaveGameScoreRequest
)
from ...repositories.leaderboard_repository import LeaderboardRepository

router = APIRouter(prefix="/leaderboard", tags=["leaderboard"])


@router.post("/save-score")
async def save_game_score(
    request: SaveGameScoreRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Save a game score for the current user
    """
    try:
        repo = LeaderboardRepository(db)
        score = repo.save_game_score(
            user_id=current_user.id,
            game_type=request.game_type,
            score=request.score,
            moves=request.moves or 0,
            time_seconds=request.time_seconds or 0,
            completed=request.completed,
            game_data=request.game_data
        )
        
        return {
            "success": True,
            "message": "Score saved successfully",
            "score_id": score.id,
            "score": score.score
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save score: {str(e)}")


@router.get("/{game_type}", response_model=LeaderboardResponse)
async def get_leaderboard(
    game_type: str,
    limit: int = Query(default=100, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    completed_only: bool = Query(default=True),
    current_user: Optional[User] = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get leaderboard for a specific game type
    - **game_type**: Type of game ('2048', 'sudoku', 'caro')
    - **limit**: Number of entries to return (max 500)
    - **offset**: Pagination offset
    - **completed_only**: Only show completed games
    """
    if game_type not in ['2048', 'sudoku', 'caro']:
        raise HTTPException(status_code=400, detail="Invalid game type")

    try:
        repo = LeaderboardRepository(db)
        # For 2048, don't filter by completed (only high scores matter)
        should_filter_completed = completed_only and game_type != '2048'
        entries, total_count = repo.get_leaderboard(
            game_type=game_type,
            limit=limit,
            offset=offset,
            completed_only=should_filter_completed
        )

        # Get current user's best score if authenticated
        user_entry = None
        if current_user:
            user_best = repo.get_user_best_score(current_user.id, game_type)
            if user_best:
                user_rank = repo.get_user_rank(current_user.id, game_type)
                user_best['rank'] = user_rank or 0
                user_entry = LeaderboardEntryResponse(**user_best)

        # Convert entries to response model
        entry_responses = [LeaderboardEntryResponse(**entry) for entry in entries]

        return LeaderboardResponse(
            game_type=game_type,
            entries=entry_responses,
            total_count=total_count,
            user_entry=user_entry
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get leaderboard: {str(e)}")


@router.get("/{game_type}/user/{user_id}")
async def get_user_leaderboard_info(
    game_type: str,
    user_id: int,
    db: Session = Depends(get_db)
):
    """
    Get specific user's leaderboard information for a game type
    """
    if game_type not in ['2048', 'sudoku', 'caro']:
        raise HTTPException(status_code=400, detail="Invalid game type")

    try:
        repo = LeaderboardRepository(db)
        user_best = repo.get_user_best_score(user_id, game_type)
        
        if not user_best:
            return {
                "user_id": user_id,
                "game_type": game_type,
                "has_scores": False,
                "message": "No scores found for this user"
            }

        user_rank = repo.get_user_rank(user_id, game_type)

        return {
            "user_id": user_id,
            "game_type": game_type,
            "has_scores": True,
            "rank": user_rank,
            "best_score": user_best['score'],
            "best_moves": user_best['moves'],
            "best_time": user_best['time_seconds'],
            "created_at": user_best['created_at']
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get user info: {str(e)}")


@router.get("/{game_type}/stats")
async def get_game_statistics(
    game_type: str,
    db: Session = Depends(get_db)
):
    """
    Get overall statistics for a game type
    """
    if game_type not in ['2048', 'sudoku', 'caro']:
        raise HTTPException(status_code=400, detail="Invalid game type")

    try:
        repo = LeaderboardRepository(db)
        stats = repo.get_game_statistics(game_type)
        return stats
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get statistics: {str(e)}")


@router.get("/user/history")
async def get_user_game_history(
    game_type: Optional[str] = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get current user's game history
    """
    if game_type and game_type not in ['2048', 'sudoku', 'caro']:
        raise HTTPException(status_code=400, detail="Invalid game type")

    try:
        repo = LeaderboardRepository(db)
        history, total_count = repo.get_user_game_history(
            user_id=current_user.id,
            game_type=game_type,
            limit=limit,
            offset=offset
        )

        return {
            "user_id": current_user.id,
            "game_type": game_type,
            "total_count": total_count,
            "history": [
                {
                    "id": game.id,
                    "game_type": game.game_type,
                    "score": game.score,
                    "moves": game.moves,
                    "time_seconds": game.time_seconds,
                    "completed": game.completed,
                    "created_at": game.created_at,
                    "game_data": game.game_data
                }
                for game in history
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get history: {str(e)}")
