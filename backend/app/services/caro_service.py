"""
Caro (Gomoku) Game Service
Business logic for Caro / Five in a Row game
"""
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime
from sqlalchemy.orm import Session
import copy

from app.repositories.game_repository import GameScoreRepository
from app.core.exceptions import AppException


class CaroService:
    """Service layer for Caro game operations"""
    
    def __init__(self, db: Session):
        """Initialize service with database session"""
        self.db = db
        self.game_score_repository = GameScoreRepository()
    
    def create_new_game(
        self,
        board_size: int = 15,
        win_length: int = 5,
        mode: str = "pvp"
    ) -> Dict[str, Any]:
        """
        Create a new Caro game
        
        Args:
            board_size: Size of the board (default 15x15)
            win_length: Number in a row needed to win (default 5)
            mode: Game mode ('pvp' or 'ai')
        
        Returns:
            Dict containing initial game state
        """
        if board_size < 10 or board_size > 20:
            raise AppException("Board size must be between 10 and 20")
        
        if win_length < 3 or win_length > board_size:
            raise AppException(f"Win length must be between 3 and {board_size}")
        
        # Initialize empty board
        board = [[0 for _ in range(board_size)] for _ in range(board_size)]
        
        return {
            "board": board,
            "board_size": board_size,
            "win_length": win_length,
            "mode": mode,
            "current_player": 1,  # 1 = X, 2 = O
            "moves": [],
            "game_over": False,
            "winner": None,
            "winning_line": None
        }
    
    def make_move(
        self,
        board: List[List[int]],
        row: int,
        col: int,
        player: int,
        win_length: int = 5
    ) -> Dict[str, Any]:
        """
        Make a move on the Caro board
        
        Args:
            board: Current game board
            row: Row index
            col: Column index
            player: Player number (1 or 2)
            win_length: Number in a row needed to win
        
        Returns:
            Dict with move result and updated board
        """
        board_size = len(board)
        
        # Validate move
        if not (0 <= row < board_size and 0 <= col < board_size):
            return {
                "valid": False,
                "error": "Position out of bounds"
            }
        
        if board[row][col] != 0:
            return {
                "valid": False,
                "error": "Cell is already occupied"
            }
        
        if player not in [1, 2]:
            return {
                "valid": False,
                "error": "Invalid player number"
            }
        
        # Make the move
        new_board = copy.deepcopy(board)
        new_board[row][col] = player
        
        # Check for win
        is_winning_move, winning_line = self._check_win(
            new_board, row, col, player, win_length
        )
        
        # Check for draw (board full)
        is_draw = self._is_board_full(new_board) and not is_winning_move
        
        return {
            "valid": True,
            "board": new_board,
            "game_over": is_winning_move or is_draw,
            "winner": player if is_winning_move else None,
            "winning_line": winning_line if is_winning_move else None,
            "draw": is_draw,
            "next_player": 2 if player == 1 else 1
        }
    
    def _check_win(
        self,
        board: List[List[int]],
        row: int,
        col: int,
        player: int,
        win_length: int
    ) -> Tuple[bool, Optional[List[Tuple[int, int]]]]:
        """
        Check if the last move resulted in a win
        
        Returns:
            Tuple of (is_win, winning_line_coordinates)
        """
        board_size = len(board)
        directions = [
            (0, 1),   # Horizontal
            (1, 0),   # Vertical
            (1, 1),   # Diagonal \
            (1, -1)   # Diagonal /
        ]
        
        for dr, dc in directions:
            count = 1  # Count the placed piece
            line = [(row, col)]
            
            # Check forward direction
            r, c = row + dr, col + dc
            while (0 <= r < board_size and 0 <= c < board_size and
                   board[r][c] == player):
                count += 1
                line.append((r, c))
                r += dr
                c += dc
            
            # Check backward direction
            r, c = row - dr, col - dc
            while (0 <= r < board_size and 0 <= c < board_size and
                   board[r][c] == player):
                count += 1
                line.append((r, c))
                r -= dr
                c -= dc
            
            # Check if win condition met
            if count >= win_length:
                return True, sorted(line)
        
        return False, None
    
    def _is_board_full(self, board: List[List[int]]) -> bool:
        """Check if board is completely filled"""
        for row in board:
            if 0 in row:
                return False
        return True
    
    def get_ai_move(
        self,
        board: List[List[int]],
        ai_player: int,
        win_length: int = 5,
        difficulty: str = "medium"
    ) -> Dict[str, Any]:
        """
        Calculate AI move (simple heuristic-based)
        
        Args:
            board: Current board state
            ai_player: AI player number (1 or 2)
            win_length: Win condition
            difficulty: AI difficulty ('easy', 'medium', 'hard')
        
        Returns:
            Dict with AI move coordinates
        """
        board_size = len(board)
        opponent = 2 if ai_player == 1 else 1
        
        # Easy: random move
        if difficulty == "easy":
            empty_cells = [
                (i, j) for i in range(board_size)
                for j in range(board_size)
                if board[i][j] == 0
            ]
            if empty_cells:
                import random
                row, col = random.choice(empty_cells)
                return {"row": row, "col": col}
        
        # Medium/Hard: check for winning moves and blocking moves
        # 1. Check if AI can win
        for i in range(board_size):
            for j in range(board_size):
                if board[i][j] == 0:
                    # Try the move
                    board[i][j] = ai_player
                    is_win, _ = self._check_win(board, i, j, ai_player, win_length)
                    board[i][j] = 0
                    
                    if is_win:
                        return {"row": i, "col": j}
        
        # 2. Check if need to block opponent
        for i in range(board_size):
            for j in range(board_size):
                if board[i][j] == 0:
                    # Try opponent's move
                    board[i][j] = opponent
                    is_win, _ = self._check_win(board, i, j, opponent, win_length)
                    board[i][j] = 0
                    
                    if is_win:
                        return {"row": i, "col": j}
        
        # 3. Hard: score-based move selection
        if difficulty == "hard":
            best_score = -float('inf')
            best_move = None
            
            for i in range(board_size):
                for j in range(board_size):
                    if board[i][j] == 0:
                        score = self._evaluate_position(board, i, j, ai_player)
                        if score > best_score:
                            best_score = score
                            best_move = (i, j)
            
            if best_move:
                return {"row": best_move[0], "col": best_move[1]}
        
        # 4. Default: prefer center and nearby moves
        center = board_size // 2
        
        # Try center
        if board[center][center] == 0:
            return {"row": center, "col": center}
        
        # Try near existing pieces
        for i in range(board_size):
            for j in range(board_size):
                if board[i][j] != 0:
                    # Try adjacent cells
                    for di in [-1, 0, 1]:
                        for dj in [-1, 0, 1]:
                            ni, nj = i + di, j + dj
                            if (0 <= ni < board_size and 0 <= nj < board_size and
                                board[ni][nj] == 0):
                                return {"row": ni, "col": nj}
        
        # Fallback: any empty cell
        for i in range(board_size):
            for j in range(board_size):
                if board[i][j] == 0:
                    return {"row": i, "col": j}
        
        raise AppException("No valid moves available")
    
    def _evaluate_position(
        self,
        board: List[List[int]],
        row: int,
        col: int,
        player: int
    ) -> float:
        """
        Evaluate the strategic value of a position
        Higher score = better position
        """
        board_size = len(board)
        score = 0.0
        
        # Center preference
        center = board_size // 2
        distance_from_center = abs(row - center) + abs(col - center)
        score += (board_size - distance_from_center) * 0.1
        
        # Count adjacent friendly pieces
        directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        for dr, dc in directions:
            count = 0
            for sign in [1, -1]:
                r, c = row + sign * dr, col + sign * dc
                if (0 <= r < board_size and 0 <= c < board_size and
                    board[r][c] == player):
                    count += 1
            score += count * 10
        
        return score
    
    def save_game_result(
        self,
        user_id: int,
        opponent_id: Optional[int],
        won: bool,
        moves: int,
        mode: str,
        board_size: int
    ) -> Dict[str, Any]:
        """
        Save Caro game result
        
        Args:
            user_id: User who played
            opponent_id: Opponent user ID (None for AI)
            won: Whether user won
            moves: Number of moves made
            mode: Game mode ('pvp' or 'ai')
            board_size: Board size used
        
        Returns:
            Saved game data
        """
        # Calculate score
        base_score = 100 if won else 50
        move_bonus = max(0, 100 - moves)  # Fewer moves = higher bonus
        final_score = base_score + move_bonus
        
        score_data = {
            "user_id": user_id,
            "game_type": "caro",
            "score": final_score,
            "moves": moves,
            "won": won
        }
        
        saved_score = self.game_score_repository.create(score_data)
        
        return {
            "id": saved_score.id,
            "user_id": saved_score.user_id,
            "opponent_id": opponent_id,
            "mode": mode,
            "won": saved_score.won,
            "score": saved_score.score,
            "moves": saved_score.moves,
            "board_size": board_size,
            "played_at": saved_score.played_at.isoformat()
        }
    
    def get_leaderboard(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Get Caro leaderboard"""
        scores = self.game_score_repository.get_leaderboard("caro", limit)
        
        result = []
        rank = 1
        for score in scores:
            result.append({
                "rank": rank,
                "user_id": score.user_id,
                "username": score.user.username if score.user else "Anonymous",
                "score": score.score,
                "wins": score.won,
                "played_at": score.played_at.isoformat()
            })
            rank += 1
        
        return result
    
    def get_user_stats(self, user_id: int) -> Dict[str, Any]:
        """Get user's Caro statistics"""
        stats = self.game_score_repository.get_user_stats(user_id, "caro")
        
        return {
            "user_id": user_id,
            "game_type": "caro",
            "total_games": stats["total_games"],
            "total_wins": stats["total_wins"],
            "win_rate": stats["win_rate"],
            "best_score": stats["best_score"],
            "average_score": stats["average_score"]
        }
    
    def get_game_rules(self) -> Dict[str, Any]:
        """Get Caro game rules"""
        return {
            "name": "Caro (Gomoku)",
            "description": "Five in a Row strategy game",
            "objective": "Be the first to get 5 pieces in a row (horizontal, vertical, or diagonal)",
            "rules": [
                "Two players alternate placing their pieces on the board",
                "Player 1 (X) goes first",
                "Place one piece per turn on any empty cell",
                "First to get 5 pieces in a row wins",
                "Game is draw if board fills with no winner"
            ],
            "board_sizes": {
                "standard": "15×15",
                "small": "10×10",
                "large": "20×20"
            },
            "modes": {
                "pvp": "Play against another human player",
                "ai": "Play against computer (Easy/Medium/Hard)"
            },
            "scoring": {
                "win": "100 base points",
                "draw": "50 base points",
                "move_bonus": "Fewer moves = higher bonus (max 100)"
            },
            "strategies": [
                "Control the center of the board",
                "Create multiple threats (forking)",
                "Block opponent's potential winning lines",
                "Build open-ended sequences (not blocked)",
                "Plan several moves ahead"
            ],
            "tips": [
                "Opening: Start near the center",
                "Create 'double threes' - two ways to make 5",
                "Watch for opponent's threats",
                "Don't focus only on attack, defense is crucial",
                "Practice pattern recognition"
            ]
        }
