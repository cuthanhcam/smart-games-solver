"""
Caro (Gomoku) Game Endpoints
Clean architecture with service layer
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List, Optional

from app.core.database import get_db
from app.core.dependencies import get_current_user, get_optional_user
from app.models.user import User
from app.models.schemas import (
    CaroNewGameRequest,
    CaroMoveRequest,
    CaroGameStateResponse,
    CaroAIMoveRequest,
    CaroSaveScoreRequest
)
from app.services.caro_service import CaroService

router = APIRouter(prefix="/caro", tags=["Caro (Gomoku)"])


@router.post("/new", response_model=CaroGameStateResponse, status_code=201)
async def create_new_game(
    request: CaroNewGameRequest,
    current_user: Optional[User] = Depends(get_optional_user),
    db: Session = Depends(get_db)
):
    """
    Create a new Caro (Five in a Row) game
    
    **Authentication**: Not required (guests can play)
    
    **Request**:
    - `board_size`: Board dimensions (10-20, default: 15)
    - `win_length`: Pieces needed to win (3-board_size, default: 5)
    - `mode`: 'pvp' (player vs player) or 'ai' (player vs computer)
    
    **Returns**:
    - Empty board
    - Initial game state
    - Current player (always Player 1 / X starts)
    
    **Game Modes**:
    - PvP: Two human players take turns
    - AI: Play against computer (difficulty levels available)
    """
    service = CaroService(db)
    
    game_state = service.create_new_game(
        board_size=request.board_size or 15,
        win_length=request.win_length or 5,
        mode=request.mode or "pvp"
    )
    
    return CaroGameStateResponse(
        board=game_state["board"],
        board_size=game_state["board_size"],
        win_length=game_state["win_length"],
        mode=game_state["mode"],
        current_player=game_state["current_player"],
        moves=game_state["moves"],
        game_over=game_state["game_over"],
        winner=game_state["winner"],
        winning_line=game_state["winning_line"],
        message="New Caro game created. Player 1 (X) starts!"
    )


@router.post("/move", response_model=CaroGameStateResponse)
async def make_move(
    request: CaroMoveRequest,
    db: Session = Depends(get_db)
):
    """
    Make a move in Caro game
    
    **Authentication**: Not required
    
    **Request**:
    - `board`: Current board state
    - `row`: Row index (0-based)
    - `col`: Column index (0-based)
    - `player`: Player number (1 or 2)
    - `win_length`: Win condition (default: 5)
    
    **Returns**:
    - Updated board after move
    - Game status (game_over, winner, draw)
    - Winning line coordinates if game won
    - Next player indicator
    
    **Players**:
    - Player 1: X (value = 1)
    - Player 2: O (value = 2)
    
    **Win Condition**:
    - Get 5 (or win_length) pieces in a row
    - Can be horizontal, vertical, or diagonal
    """
    service = CaroService(db)
    
    result = service.make_move(
        board=request.board,
        row=request.row,
        col=request.col,
        player=request.player,
        win_length=request.win_length or 5
    )
    
    if not result.get("valid"):
        return CaroGameStateResponse(
            board=request.board,
            board_size=len(request.board),
            win_length=request.win_length or 5,
            mode="pvp",
            current_player=request.player,
            moves=[],
            game_over=False,
            winner=None,
            winning_line=None,
            message=result.get("error", "Invalid move")
        )
    
    return CaroGameStateResponse(
        board=result["board"],
        board_size=len(result["board"]),
        win_length=request.win_length or 5,
        mode="pvp",
        current_player=result["next_player"],
        moves=[],
        game_over=result["game_over"],
        winner=result.get("winner"),
        winning_line=result.get("winning_line"),
        draw=result.get("draw", False),
        message="Player {} wins!".format(result["winner"]) if result.get("winner") else
                "Game is a draw!" if result.get("draw") else
                f"Player {result['next_player']} turn"
    )


@router.post("/ai-move")
async def get_ai_move(
    request: CaroAIMoveRequest,
    db: Session = Depends(get_db)
):
    """
    Get AI move suggestion
    
    **Authentication**: Not required
    
    **Request**:
    - `board`: Current board state
    - `ai_player`: AI player number (1 or 2)
    - `win_length`: Win condition (default: 5)
    - `difficulty`: AI difficulty ('easy', 'medium', 'hard')
    
    **Returns**:
    - Suggested move coordinates (row, col)
    
    **AI Difficulty**:
    - Easy: Random moves
    - Medium: Blocks wins and takes winning moves
    - Hard: Advanced strategy with position scoring
    """
    service = CaroService(db)
    
    ai_move = service.get_ai_move(
        board=request.board,
        ai_player=request.ai_player,
        win_length=request.win_length or 5,
        difficulty=request.difficulty or "medium"
    )
    
    return {
        "row": ai_move["row"],
        "col": ai_move["col"],
        "player": request.ai_player,
        "message": f"AI suggests move at ({ai_move['row']}, {ai_move['col']})"
    }


@router.post("/save-result", status_code=201)
async def save_game_result(
    opponent_id: Optional[int],
    won: bool,
    moves: int,
    mode: str,
    board_size: int = 15,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Save Caro game result after completion
    
    **Authentication**: Required
    
    **Request**:
    - `opponent_id`: Opponent user ID (None for AI)
    - `won`: Whether current user won
    - `moves`: Total moves made in game
    - `mode`: Game mode ('pvp' or 'ai')
    - `board_size`: Board size used
    
    **Returns**:
    - Saved game record
    
    **Scoring**:
    - Win: 100 base points
    - Draw: 50 base points
    - Move bonus: Fewer moves = higher bonus (max 100)
    """
    service = CaroService(db)
    
    saved_result = service.save_game_result(
        user_id=current_user.id,
        opponent_id=opponent_id,
        won=won,
        moves=moves,
        mode=mode,
        board_size=board_size
    )
    
    return {
        "message": "Game result saved",
        "result": saved_result
    }


@router.get("/leaderboard")
async def get_leaderboard(
    db: Session = Depends(get_db),
    limit: int = 10
):
    """
    Get Caro leaderboard
    
    **Authentication**: Not required
    
    **Query Parameters**:
    - `limit`: Number of top players (default: 10, max: 100)
    
    **Sorting**: By highest score
    
    **Returns**:
    - Ranked list of top players
    - Score and win statistics
    """
    service = CaroService(db)
    
    leaderboard = service.get_leaderboard(limit=min(limit, 100))
    
    return {
        "leaderboard": leaderboard,
        "total": len(leaderboard)
    }


@router.get("/stats")
async def get_user_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get user's Caro game statistics
    
    **Authentication**: Required
    
    **Returns**:
    - Total games played
    - Total wins
    - Win rate percentage
    - Best score
    - Average score
    """
    service = CaroService(db)
    stats = service.get_user_stats(current_user.id)
    
    return {
        "username": current_user.username,
        **stats
    }


@router.get("/rules")
async def get_game_rules():
    """
    Get Caro game rules and strategy guide
    
    **Authentication**: Not required
    
    **Returns**:
    - Game objective and rules
    - Board size options
    - Game modes (PvP, AI)
    - Scoring system
    - Strategy tips and opening advice
    """
    service = CaroService(Session())
    return service.get_game_rules()


    """Create an empty Caro board"""
    return [[0 for _ in range(size)] for _ in range(size)]


def check_winner(board, row, col, player):
    """
    Check if the last move at (row, col) by player resulted in a win
    Returns True if player wins
    """
    size = len(board)
    directions = [(0, 1), (1, 0), (1, 1), (1, -1)]  # horizontal, vertical, diagonal, anti-diagonal
    
    for dx, dy in directions:
        count = 1  # Count the current piece
        
        # Check positive direction
        r, c = row + dx, col + dy
        while 0 <= r < size and 0 <= c < size and board[r][c] == player:
            count += 1
            r += dx
            c += dy
        
        # Check negative direction
        r, c = row - dx, col - dy
        while 0 <= r < size and 0 <= c < size and board[r][c] == player:
            count += 1
            r -= dx
            c -= dy
        
        if count >= 5:
            return True
    
    return False


def get_ai_move(board):
    """
    Simple AI for Caro - finds first empty cell
    In production, implement minimax or other AI algorithms
    """
    size = len(board)
    for i in range(size):
        for j in range(size):
            if board[i][j] == 0:
                return i, j
    return None, None


@router.post("/new", response_model=CaroGameStateResponse)
async def new_caro_game(
    request: CaroNewGameRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Start a new Caro game
    
    If player2_id is None, play against AI
    """
    # Create empty board
    board = create_empty_board(request.board_size)
    
    # Create new game
    game = CaroGame(
        player1_id=request.player1_id,
        player2_id=request.player2_id,
        board_size=request.board_size,
        board_state=board,
        current_turn="player1",
        status="in_progress"
    )
    
    db.add(game)
    db.commit()
    db.refresh(game)
    
    return CaroGameStateResponse(
        game_id=game.id,
        board_state=board,
        current_turn="player1",
        status="in_progress",
        winner_id=None,
        message="Game started! Player 1's turn."
    )


@router.post("/move", response_model=CaroGameStateResponse)
async def make_caro_move(
    request: CaroMoveRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Make a move in Caro game
    """
    game = db.query(CaroGame).filter(CaroGame.id == request.game_id).first()
    
    if not game:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Game not found"
        )
    
    if game.status != "in_progress":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Game is not in progress"
        )
    
    # Validate player turn
    if game.current_turn == "player1" and request.player_id != game.player1_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Not your turn"
        )
    elif game.current_turn == "player2" and request.player_id != game.player2_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Not your turn"
        )
    
    # Validate move
    board = game.board_state
    if request.row < 0 or request.row >= game.board_size or \
       request.col < 0 or request.col >= game.board_size:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid position"
        )
    
    if board[request.row][request.col] != 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Position already occupied"
        )
    
    # Make move
    player_num = 1 if game.current_turn == "player1" else 2
    board[request.row][request.col] = player_num
    
    # Check for winner
    if check_winner(board, request.row, request.col, player_num):
        game.status = "finished"
        game.winner_id = request.player_id
        game.board_state = board
        db.commit()
        
        # Save to game scores
        game_score = GameScore(
            user_id=request.player_id,
            game_type="caro",
            score=100,
            completed=True,
            game_data={"game_id": game.id, "opponent_id": game.player2_id}
        )
        db.add(game_score)
        db.commit()
        
        return CaroGameStateResponse(
            game_id=game.id,
            board_state=board,
            current_turn=game.current_turn,
            status="finished",
            winner_id=request.player_id,
            message=f"Player {player_num} wins!"
        )
    
    # Check for draw (board full)
    if all(board[i][j] != 0 for i in range(game.board_size) for j in range(game.board_size)):
        game.status = "finished"
        game.board_state = board
        db.commit()
        
        return CaroGameStateResponse(
            game_id=game.id,
            board_state=board,
            current_turn=game.current_turn,
            status="finished",
            winner_id=None,
            message="Draw! Board is full."
        )
    
    # Switch turn
    game.current_turn = "player2" if game.current_turn == "player1" else "player1"
    game.board_state = board
    db.commit()
    
    # If playing against AI and it's AI's turn
    if game.player2_id is None and game.current_turn == "player2":
        ai_row, ai_col = get_ai_move(board)
        if ai_row is not None:
            board[ai_row][ai_col] = 2
            
            # Check if AI wins
            if check_winner(board, ai_row, ai_col, 2):
                game.status = "finished"
                game.winner_id = None  # AI wins
                game.board_state = board
                db.commit()
                
                return CaroGameStateResponse(
                    game_id=game.id,
                    board_state=board,
                    current_turn="player2",
                    status="finished",
                    winner_id=None,
                    message="AI wins!"
                )
            
            # Switch back to player1
            game.current_turn = "player1"
            game.board_state = board
            db.commit()
    
    return CaroGameStateResponse(
        game_id=game.id,
        board_state=board,
        current_turn=game.current_turn,
        status="in_progress",
        winner_id=None,
        message=f"{game.current_turn}'s turn"
    )


@router.get("/game/{game_id}", response_model=CaroGameStateResponse)
async def get_caro_game(
    game_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get current Caro game state
    """
    game = db.query(CaroGame).filter(CaroGame.id == game_id).first()
    
    if not game:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Game not found"
        )
    
    return CaroGameStateResponse(
        game_id=game.id,
        board_state=game.board_state,
        current_turn=game.current_turn,
        status=game.status,
        winner_id=game.winner_id,
        message=None
    )


@router.get("/leaderboard")
async def get_caro_leaderboard(
    db: Session = Depends(get_db),
    limit: int = 10
):
    """
    Get Caro leaderboard (by wins)
    """
    from sqlalchemy import func
    
    top_players = db.query(
        User.username,
        func.count(GameScore.id).label("wins"),
        func.sum(GameScore.score).label("total_score")
    ).join(GameScore).filter(
        GameScore.game_type == "caro",
        GameScore.completed == True
    ).group_by(User.id, User.username).order_by(
        func.count(GameScore.id).desc()
    ).limit(limit).all()
    
    return {
        "leaderboard": [
            {
                "rank": idx + 1,
                "username": player.username,
                "wins": player.wins,
                "total_score": player.total_score
            }
            for idx, player in enumerate(top_players)
        ]
    }

@router.post("/save-score", status_code=201)
async def save_game_score(
    request: "CaroSaveScoreRequest",
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Save Caro game score after completion
    
    **Authentication**: Required
    
    **Request Body**:
    - `moves`: Total moves made in game
    - `board_size`: Board size played (10-20)
    - `difficulty`: Game difficulty ('Easy', 'Normal', 'Hard', 'Expert')
    - `player_color`: Player's color ('X' or 'O')
    - `opponent_type`: Opponent type ('human' or 'ai')
    
    **Returns**:
    - Saved score record with timestamp
    """
    service = CaroService(db)
    
    saved_score = service.save_score(
        user_id=current_user.id,
        moves=request.moves,
        board_size=request.board_size,
        difficulty=request.difficulty,
        player_color=request.player_color,
        opponent_type=request.opponent_type
    )
    
    return {
        "message": "Caro score saved successfully",
        "score": saved_score
    }