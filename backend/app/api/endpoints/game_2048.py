"""
2048 Game Endpoints
Clean architecture with service layer
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.schemas import (
    Game2048NewRequest,
    Game2048MoveRequest,
    Game2048StateResponse
)
from app.services.game_2048_service import Game2048Service

router = APIRouter(prefix="/2048", tags=["Game 2048"])


@router.post("/new", response_model=Game2048StateResponse, status_code=201)
async def create_new_game(
    db: Session = Depends(get_db)
):
    """
    Create a new 2048 game
    
    **Authentication**: Not required (guest play available)
    
    **Returns**:
    - Initial 4x4 grid with two random tiles
    - Score starts at 0
    - Game status indicators
    
    **Game Rules**:
    - Combine tiles with same numbers
    - Each move spawns a new tile (2 or 4)
    - Win by creating 2048 tile
    - Lose when no valid moves remain
    """
    service = Game2048Service(db)
    game_state = service.create_new_game()
    
    return Game2048StateResponse(
        grid=game_state["grid"],
        score=game_state["score"],
        moves=game_state["moves"],
        game_over=game_state["game_over"],
        won=game_state["won"],
        can_move=game_state["can_move"],
        message="New game created. Good luck!"
    )


@router.post("/move", response_model=Game2048StateResponse)
async def make_move(
    request: Game2048MoveRequest,
    db: Session = Depends(get_db)
):
    """
    Make a move in the game
    
    **Authentication**: Not required
    
    **Request**:
    - `grid`: Current 4x4 grid state
    - `direction`: Move direction ('up', 'down', 'left', 'right')
    - `current_score`: Current game score
    
    **Returns**:
    - Updated grid after move and merge
    - New score with points earned
    - Game status (game_over, won, can_move)
    - Move validation result
    
    **Scoring**:
    - Points equal to merged tile values
    - Example: Merging two 4s = +8 points
    """
    service = Game2048Service(db)
    
    result = service.make_move(
        grid=request.grid,
        direction=request.direction,
        current_score=request.current_score
    )
    
    if not result.get("valid_move"):
        return Game2048StateResponse(
            grid=request.grid,
            score=request.current_score,
            moves=0,
            game_over=False,
            won=False,
            can_move=True,
            message=result.get("error") or result.get("message", "Invalid move")
        )
    
    return Game2048StateResponse(
        grid=result["grid"],
        score=result["score"],
        moves=1,
        points_earned=result.get("points_earned", 0),
        game_over=result["game_over"],
        won=result["won"],
        can_move=result["can_move"],
        message="Won! You reached 2048!" if result["won"] else
                "Game Over!" if result["game_over"] else
                f"Good move! +{result.get('points_earned', 0)} points"
    )


@router.post("/save-score", status_code=201)
async def save_game_score(
    score: int,
    moves: int,
    won: bool = False,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Save game score after completion
    
    **Authentication**: Required
    
    **Request**:
    - `score`: Final game score
    - `moves`: Total moves made
    - `won`: Whether player reached 2048 tile
    
    **Returns**:
    - Saved score record with timestamp
    """
    service = Game2048Service(db)
    
    saved_score = service.save_score(
        user_id=current_user.id,
        score=score,
        moves=moves,
        won=won
    )
    
    return {
        "message": "Score saved successfully",
        "score": saved_score
    }


@router.get("/leaderboard")
async def get_leaderboard(
    db: Session = Depends(get_db),
    limit: int = 10,
    time_range: str = "all"
):
    """
    Get 2048 leaderboard
    
    **Authentication**: Not required
    
    **Query Parameters**:
    - `limit`: Number of top scores (default: 10, max: 100)
    - `time_range`: Filter by time ('daily', 'weekly', 'monthly', 'all')
    
    **Sorting**: By highest score
    
    **Returns**:
    - Ranked list of top scores with player info
    - Each entry includes: rank, username, score, moves, won status
    """
    service = Game2048Service(db)
    
    valid_ranges = ["daily", "weekly", "monthly", "all"]
    if time_range not in valid_ranges:
        time_range = "all"
    
    leaderboard = service.get_leaderboard(
        limit=min(limit, 100),
        time_range=time_range if time_range != "all" else None
    )
    
    return {
        "leaderboard": leaderboard,
        "time_range": time_range,
        "total": len(leaderboard)
    }


@router.get("/stats")
async def get_user_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get user's 2048 game statistics
    
    **Authentication**: Required
    
    **Returns**:
    - Total games played
    - Total wins (reached 2048)
    - Win rate percentage
    - Best score
    - Average score
    - Total and average moves
    """
    service = Game2048Service(db)
    stats = service.get_user_stats(current_user.id)
    
    return {
        "username": current_user.username,
        **stats
    }


@router.get("/history")
async def get_user_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = 10,
    offset: int = 0
):
    """
    Get user's 2048 game history
    
    **Authentication**: Required
    
    **Query Parameters**:
    - `limit`: Games per page (default: 10)
    - `offset`: Pagination offset (default: 0)
    
    **Returns**:
    - List of past games with scores, moves, timestamps
    - Pagination info (total, has_more)
    """
    service = Game2048Service(db)
    
    result = service.get_user_history(
        user_id=current_user.id,
        limit=limit,
        offset=offset
    )
    
    return {
        "username": current_user.username,
        **result
    }


@router.get("/rules")
async def get_game_rules():
    """
    Get 2048 game rules and instructions
    
    **Authentication**: Not required
    
    **Returns**:
    - Game objective and rules
    - Scoring system explanation
    - Strategy tips for beginners
    - Grid size and win/lose conditions
    """
    service = Game2048Service(Session())
    return service.get_game_rules()


    """Create a 4x4 empty grid"""
    return [[0 for _ in range(4)] for _ in range(4)]


def add_random_tile(grid):
    """Add a random tile (2 or 4) to an empty cell"""
    empty_cells = [(i, j) for i in range(4) for j in range(4) if grid[i][j] == 0]
    if empty_cells:
        i, j = random.choice(empty_cells)
        grid[i][j] = 2 if random.random() < 0.9 else 4
    return grid


def move_left(grid):
    """Move and merge tiles to the left"""
    moved = False
    score_gained = 0
    
    for i in range(4):
        # Compress non-zero values to the left
        row = [val for val in grid[i] if val != 0]
        
        # Merge adjacent equal values
        j = 0
        while j < len(row) - 1:
            if row[j] == row[j + 1]:
                row[j] *= 2
                score_gained += row[j]
                row.pop(j + 1)
                moved = True
            j += 1
        
        # Pad with zeros
        row += [0] * (4 - len(row))
        
        if grid[i] != row:
            moved = True
        grid[i] = row
    
    return grid, moved, score_gained


def rotate_grid_clockwise(grid):
    """Rotate grid 90 degrees clockwise"""
    return [list(row) for row in zip(*grid[::-1])]


def move_grid(grid, direction):
    """Move grid in specified direction"""
    rotations = {'left': 0, 'up': 1, 'right': 2, 'down': 3}
    n = rotations.get(direction, 0)
    
    # Rotate to make the move equivalent to moving left
    for _ in range(n):
        grid = rotate_grid_clockwise(grid)
    
    grid, moved, score_gained = move_left(grid)
    
    # Rotate back
    for _ in range(4 - n):
        grid = rotate_grid_clockwise(grid)
    
    return grid, moved, score_gained


def is_game_over(grid):
    """Check if no more moves are possible"""
    # Check for empty cells
    for row in grid:
        if 0 in row:
            return False
    
    # Check for possible merges horizontally
    for i in range(4):
        for j in range(3):
            if grid[i][j] == grid[i][j + 1]:
                return False
    
    # Check for possible merges vertically
    for i in range(3):
        for j in range(4):
            if grid[i][j] == grid[i + 1][j]:
                return False
    
    return True


@router.post("/new", response_model=Game2048StateResponse)
async def new_game(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Start a new 2048 game
    """
    # Create initial grid with 2 random tiles
    grid = create_empty_grid()
    grid = add_random_tile(grid)
    grid = add_random_tile(grid)
    
    # Get user's best score
    best_score_record = db.query(GameScore).filter(
        GameScore.user_id == current_user.id,
        GameScore.game_type == "2048"
    ).order_by(GameScore.score.desc()).first()
    
    best_score = best_score_record.score if best_score_record else 0
    
    # Create new session
    session = Game2048Session(
        user_id=current_user.id,
        grid_state=grid,
        score=0,
        best_score=best_score,
        game_over=False
    )
    
    db.add(session)
    db.commit()
    db.refresh(session)
    
    return Game2048StateResponse(
        session_id=session.id,
        grid_state=grid,
        score=0,
        best_score=best_score,
        game_over=False,
        message="New game started!"
    )


@router.post("/move", response_model=Game2048StateResponse)
async def make_move(
    request: Game2048MoveRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Make a move in the game (up, down, left, right)
    """
    session = db.query(Game2048Session).filter(
        Game2048Session.id == request.session_id,
        Game2048Session.user_id == current_user.id
    ).first()
    
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Game session not found"
        )
    
    if session.game_over:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Game is already over"
        )
    
    # Make move
    grid = session.grid_state
    new_grid, moved, score_gained = move_grid(grid, request.direction)
    
    if not moved:
        return Game2048StateResponse(
            session_id=session.id,
            grid_state=grid,
            score=session.score,
            best_score=session.best_score,
            game_over=False,
            message="Invalid move - no tiles moved"
        )
    
    # Add random tile after successful move
    new_grid = add_random_tile(new_grid)
    
    # Update score
    new_score = session.score + score_gained
    new_best = max(session.best_score, new_score)
    
    # Check game over
    game_over = is_game_over(new_grid)
    
    # Update session
    session.grid_state = new_grid
    session.score = new_score
    session.best_score = new_best
    session.game_over = game_over
    
    db.commit()
    
    # Save to game scores if game over
    if game_over:
        game_score = GameScore(
            user_id=current_user.id,
            game_type="2048",
            score=new_score,
            completed=True,
            game_data={"final_grid": new_grid}
        )
        db.add(game_score)
        db.commit()
    
    return Game2048StateResponse(
        session_id=session.id,
        grid_state=new_grid,
        score=new_score,
        best_score=new_best,
        game_over=game_over,
        message="Game over!" if game_over else f"Score +{score_gained}"
    )


@router.get("/session/{session_id}", response_model=Game2048StateResponse)
async def get_session(
    session_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get current game session state
    """
    session = db.query(Game2048Session).filter(
        Game2048Session.id == session_id,
        Game2048Session.user_id == current_user.id
    ).first()
    
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Game session not found"
        )
    
    return Game2048StateResponse(
        session_id=session.id,
        grid_state=session.grid_state,
        score=session.score,
        best_score=session.best_score,
        game_over=session.game_over,
        message=None
    )


@router.get("/leaderboard")
async def get_leaderboard(
    db: Session = Depends(get_db),
    limit: int = 10
):
    """
    Get 2048 game leaderboard
    """
    from sqlalchemy import func
    
    top_scores = db.query(
        User.username,
        func.max(GameScore.score).label("best_score"),
        func.count(GameScore.id).label("games_played")
    ).join(GameScore).filter(
        GameScore.game_type == "2048"
    ).group_by(User.id, User.username).order_by(
        func.max(GameScore.score).desc()
    ).limit(limit).all()
    
    return {
        "leaderboard": [
            {
                "rank": idx + 1,
                "username": score.username,
                "best_score": score.best_score,
                "games_played": score.games_played
            }
            for idx, score in enumerate(top_scores)
        ]
    }
