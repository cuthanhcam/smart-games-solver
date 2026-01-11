"""
Sudoku Game Endpoints
Clean architecture with service layer
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List, Optional

from app.core.database import get_db
from app.core.dependencies import get_current_user, get_optional_user
from app.models.user import User
from app.models.schemas import (
    SudokuNewGameRequest,
    SudokuPuzzleResponse,
    SudokuValidateRequest,
    SudokuValidateResponse,
    SudokuMoveRequest
)
from app.services.sudoku_service import SudokuService

router = APIRouter(prefix="/sudoku", tags=["Sudoku"])


@router.post("/new", response_model=SudokuPuzzleResponse, status_code=200)
async def get_new_puzzle(
    difficulty: str = "medium",
    current_user: Optional[User] = Depends(get_optional_user),
    db: Session = Depends(get_db)
):
    """
    Get a new Sudoku puzzle
    
    **Authentication**: Not required (guests can play)
    
    **Query Parameters**:
    - `difficulty`: Puzzle difficulty ('easy', 'medium', 'hard')
    
    **Returns**:
    - Puzzle ID and grid (9x9 matrix)
    - Solution grid (for validation)
    - Difficulty level
    - Creation timestamp
    
    **Puzzle Format**:
    - 9x9 grid with some pre-filled numbers
    - 0 represents empty cells
    - Numbers 1-9 are pre-filled clues
    """
    service = SudokuService(db)
    puzzle_data = service.get_puzzle(difficulty=difficulty.lower())
    
    return SudokuPuzzleResponse(
        puzzle_id=puzzle_data["id"],
        difficulty=puzzle_data["difficulty"],
        puzzle=puzzle_data["puzzle"],
        solution=puzzle_data["solution"],  # In production, don't send this to client
        hints_used=puzzle_data["hints_used"],
        message=f"{difficulty.capitalize()} Sudoku puzzle loaded"
    )


@router.post("/move")
async def make_move(
    request: SudokuMoveRequest,
    db: Session = Depends(get_db)
):
    """
    Make a move in Sudoku puzzle
    
    **Authentication**: Not required
    
    **Request**:
    - `grid`: Current 9x9 grid state
    - `row`: Row index (0-8)
    - `col`: Column index (0-8)
    - `value`: Number to place (1-9) or 0 to clear
    
    **Returns**:
    - Updated grid
    - Move validation result
    - Conflict information if invalid
    - Completion status
    
    **Validation**:
    - Checks row, column, and 3x3 box constraints
    - Returns specific conflict type if invalid
    """
    service = SudokuService(db)
    
    result = service.make_move(
        grid=request.grid,
        row=request.row,
        col=request.col,
        value=request.value
    )
    
    return result


@router.post("/validate")
async def validate_move(
    request: SudokuMoveRequest,
    db: Session = Depends(get_db)
):
    """
    Validate a move without applying it
    
    **Authentication**: Not required
    
    **Request**:
    - `grid`: Current grid state
    - `row`: Row to check
    - `col`: Column to check
    - `value`: Value to validate
    
    **Returns**:
    - Validation result (valid/invalid)
    - Error message if invalid
    - Conflict type (row/column/box)
    """
    service = SudokuService(db)
    
    validation = service.validate_move(
        grid=request.grid,
        row=request.row,
        col=request.col,
        value=request.value
    )
    
    return validation


@router.post("/hint")
async def get_hint(
    puzzle_grid: List[List[int]],
    solution_grid: List[List[int]],
    db: Session = Depends(get_db)
):
    """
    Get a hint for the current puzzle
    
    **Authentication**: Not required
    
    **Request**:
    - `puzzle_grid`: Current grid with user's progress
    - `solution_grid`: Complete solution grid
    
    **Returns**:
    - Position (row, col) of hint
    - Correct value for that position
    - Hint message
    
    **Note**: Using hints may reduce final score
    """
    service = SudokuService(db)
    
    hint = service.get_hint(
        puzzle_grid=puzzle_grid,
        solution_grid=solution_grid
    )
    
    return hint


@router.post("/save-score", status_code=201)
async def save_completion_score(
    puzzle_id: int,
    time_seconds: int,
    hints_used: int,
    difficulty: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Save score after completing Sudoku puzzle
    
    **Authentication**: Required
    
    **Request**:
    - `puzzle_id`: ID of completed puzzle
    - `time_seconds`: Time taken to complete
    - `hints_used`: Number of hints used
    - `difficulty`: Puzzle difficulty
    
    **Returns**:
    - Saved score record
    - Final calculated score
    
    **Scoring**:
    - Base: 1000 points
    - Penalty: -1 point per 5 seconds
    - Penalty: -50 points per hint
    - Multiplier: Easy ×1.0, Medium ×1.5, Hard ×2.0
    """
    service = SudokuService(db)
    
    saved_score = service.save_score(
        user_id=current_user.id,
        puzzle_id=puzzle_id,
        time_seconds=time_seconds,
        hints_used=hints_used,
        difficulty=difficulty
    )
    
    return {
        "message": "Sudoku completed! Score saved.",
        "score": saved_score
    }


@router.get("/leaderboard")
async def get_leaderboard(
    db: Session = Depends(get_db),
    difficulty: Optional[str] = None,
    limit: int = 10
):
    """
    Get Sudoku leaderboard
    
    **Authentication**: Not required
    
    **Query Parameters**:
    - `difficulty`: Optional filter ('easy', 'medium', 'hard')
    - `limit`: Number of top scores (default: 10, max: 100)
    
    **Sorting**: By highest score
    
    **Returns**:
    - Ranked list of top players
    - Score, time, hints used for each entry
    """
    service = SudokuService(db)
    
    leaderboard = service.get_leaderboard(
        difficulty=difficulty,
        limit=min(limit, 100)
    )
    
    return {
        "leaderboard": leaderboard,
        "difficulty_filter": difficulty,
        "total": len(leaderboard)
    }


@router.get("/stats")
async def get_user_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get user's Sudoku statistics
    
    **Authentication**: Required
    
    **Returns**:
    - Total games played
    - Total completions
    - Best score
    - Average score
    - Average completion time
    - Total hints used
    """
    service = SudokuService(db)
    stats = service.get_user_stats(current_user.id)
    
    return {
        "username": current_user.username,
        **stats
    }


@router.get("/rules")
async def get_game_rules():
    """
    Get Sudoku game rules and instructions
    
    **Authentication**: Not required
    
    **Returns**:
    - Game objective and rules
    - Difficulty descriptions
    - Scoring system
    - Strategy tips
    """
    service = SudokuService(Session())
    return service.get_game_rules()


@router.get("/puzzle/{puzzle_id}")
async def get_puzzle_by_id(
    puzzle_id: int,
    db: Session = Depends(get_db)
):
    """
    Get a specific puzzle by ID
    
    **Authentication**: Not required
    
    **Returns**:
    - Puzzle data with grid and solution
    """
    service = SudokuService(db)
    puzzle = service.get_puzzle(puzzle_id=puzzle_id)
    
    return puzzle


