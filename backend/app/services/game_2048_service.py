"""
2048 Game Service
Business logic for 2048 game (number sliding puzzle)
"""
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime
from sqlalchemy.orm import Session
import random
import copy

from app.repositories.game_repository import GameScoreRepository


class Game2048Service:
    """Service layer for 2048 game operations"""
    
    GRID_SIZE = 4
    
    def __init__(self, db: Session):
        """Initialize service with database session"""
        self.db = db
        self.game_score_repository = GameScoreRepository()
    
    def create_new_game(self) -> Dict[str, Any]:
        """
        Create a new 2048 game with initial tiles
        
        Returns:
            Dict containing initial game state
        """
        # Initialize empty grid
        grid = [[0 for _ in range(self.GRID_SIZE)] for _ in range(self.GRID_SIZE)]
        
        # Add two random tiles
        self._add_random_tile(grid)
        self._add_random_tile(grid)
        
        return {
            "grid": grid,
            "score": 0,
            "moves": 0,
            "game_over": False,
            "won": False,
            "can_move": True
        }
    
    def _add_random_tile(self, grid: List[List[int]]) -> bool:
        """
        Add a random tile (2 or 4) to empty position
        
        Args:
            grid: Current game grid
        
        Returns:
            True if tile was added, False if no empty spaces
        """
        empty_cells = []
        for i in range(self.GRID_SIZE):
            for j in range(self.GRID_SIZE):
                if grid[i][j] == 0:
                    empty_cells.append((i, j))
        
        if not empty_cells:
            return False
        
        # Choose random empty cell
        i, j = random.choice(empty_cells)
        
        # 90% chance of 2, 10% chance of 4
        grid[i][j] = 2 if random.random() < 0.9 else 4
        
        return True
    
    def make_move(
        self,
        grid: List[List[int]],
        direction: str,
        current_score: int
    ) -> Dict[str, Any]:
        """
        Process a move in the specified direction
        
        Args:
            grid: Current game grid
            direction: Move direction ('up', 'down', 'left', 'right')
            current_score: Current game score
        
        Returns:
            Dict with new grid state, score, and game status
        """
        # Make a copy to detect changes
        old_grid = copy.deepcopy(grid)
        new_grid = copy.deepcopy(grid)
        
        # Perform the move
        points_earned = 0
        
        if direction == "left":
            new_grid, points_earned = self._move_left(new_grid)
        elif direction == "right":
            new_grid, points_earned = self._move_right(new_grid)
        elif direction == "up":
            new_grid, points_earned = self._move_up(new_grid)
        elif direction == "down":
            new_grid, points_earned = self._move_down(new_grid)
        else:
            return {
                "grid": grid,
                "score": current_score,
                "valid_move": False,
                "error": f"Invalid direction: {direction}"
            }
        
        # Check if grid changed
        grid_changed = new_grid != old_grid
        
        if not grid_changed:
            return {
                "grid": grid,
                "score": current_score,
                "valid_move": False,
                "message": "No tiles moved"
            }
        
        # Add random tile after successful move
        self._add_random_tile(new_grid)
        
        new_score = current_score + points_earned
        
        # Check game status
        won = self._check_win(new_grid)
        game_over = not self._has_valid_moves(new_grid)
        
        return {
            "grid": new_grid,
            "score": new_score,
            "points_earned": points_earned,
            "valid_move": True,
            "game_over": game_over,
            "won": won,
            "can_move": not game_over
        }
    
    def _move_left(self, grid: List[List[int]]) -> Tuple[List[List[int]], int]:
        """Move all tiles left and merge"""
        points = 0
        for i in range(self.GRID_SIZE):
            # Compress row (remove zeros)
            row = [x for x in grid[i] if x != 0]
            
            # Merge adjacent same numbers
            merged_row = []
            skip = False
            for j in range(len(row)):
                if skip:
                    skip = False
                    continue
                
                if j + 1 < len(row) and row[j] == row[j + 1]:
                    merged_value = row[j] * 2
                    merged_row.append(merged_value)
                    points += merged_value
                    skip = True
                else:
                    merged_row.append(row[j])
            
            # Fill with zeros
            grid[i] = merged_row + [0] * (self.GRID_SIZE - len(merged_row))
        
        return grid, points
    
    def _move_right(self, grid: List[List[int]]) -> Tuple[List[List[int]], int]:
        """Move all tiles right and merge"""
        # Reverse, move left, reverse back
        for i in range(self.GRID_SIZE):
            grid[i] = grid[i][::-1]
        
        grid, points = self._move_left(grid)
        
        for i in range(self.GRID_SIZE):
            grid[i] = grid[i][::-1]
        
        return grid, points
    
    def _move_up(self, grid: List[List[int]]) -> Tuple[List[List[int]], int]:
        """Move all tiles up and merge"""
        # Transpose, move left, transpose back
        grid = self._transpose(grid)
        grid, points = self._move_left(grid)
        grid = self._transpose(grid)
        return grid, points
    
    def _move_down(self, grid: List[List[int]]) -> Tuple[List[List[int]], int]:
        """Move all tiles down and merge"""
        # Transpose, move right, transpose back
        grid = self._transpose(grid)
        grid, points = self._move_right(grid)
        grid = self._transpose(grid)
        return grid, points
    
    def _transpose(self, grid: List[List[int]]) -> List[List[int]]:
        """Transpose grid matrix"""
        return [[grid[j][i] for j in range(self.GRID_SIZE)] for i in range(self.GRID_SIZE)]
    
    def _check_win(self, grid: List[List[int]]) -> bool:
        """Check if player reached 2048 tile"""
        for row in grid:
            if 2048 in row:
                return True
        return False
    
    def _has_valid_moves(self, grid: List[List[int]]) -> bool:
        """Check if any valid moves remain"""
        # Check for empty cells
        for row in grid:
            if 0 in row:
                return True
        
        # Check for mergeable adjacent cells
        for i in range(self.GRID_SIZE):
            for j in range(self.GRID_SIZE):
                # Check right neighbor
                if j < self.GRID_SIZE - 1 and grid[i][j] == grid[i][j + 1]:
                    return True
                # Check bottom neighbor
                if i < self.GRID_SIZE - 1 and grid[i][j] == grid[i + 1][j]:
                    return True
        
        return False
    
    def save_score(
        self,
        user_id: int,
        score: int,
        moves: int,
        won: bool = False
    ) -> Dict[str, Any]:
        """
        Save 2048 game score to database
        
        Args:
            user_id: User who played the game
            score: Final score
            moves: Number of moves made
            won: Whether player won (reached 2048)
        
        Returns:
            Saved score data
        """
        score_data = {
            "user_id": user_id,
            "game_type": "2048",
            "score": score,
            "moves": moves,
            "won": won
        }
        
        saved_score = self.game_score_repository.create(score_data)
        
        return {
            "id": saved_score.id,
            "user_id": saved_score.user_id,
            "game_type": saved_score.game_type,
            "score": saved_score.score,
            "moves": saved_score.moves,
            "won": saved_score.won,
            "played_at": saved_score.played_at.isoformat()
        }
    
    def get_leaderboard(
        self,
        limit: int = 10,
        time_range: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Get 2048 leaderboard
        
        Args:
            limit: Number of top scores to return
            time_range: Optional time filter ('daily', 'weekly', 'monthly', 'all')
        
        Returns:
            List of top scores with user info
        """
        scores = self.game_score_repository.get_leaderboard("2048", limit, time_range)
        
        result = []
        rank = 1
        for score in scores:
            result.append({
                "rank": rank,
                "user_id": score.user_id,
                "username": score.user.username if score.user else "Anonymous",
                "score": score.score,
                "moves": score.moves,
                "won": score.won,
                "played_at": score.played_at.isoformat()
            })
            rank += 1
        
        return result
    
    def get_user_stats(self, user_id: int) -> Dict[str, Any]:
        """
        Get user's 2048 game statistics
        
        Args:
            user_id: User ID
        
        Returns:
            Dict with statistics
        """
        stats = self.game_score_repository.get_user_stats(user_id, "2048")
        
        return {
            "user_id": user_id,
            "game_type": "2048",
            "total_games": stats["total_games"],
            "total_wins": stats["total_wins"],
            "win_rate": stats["win_rate"],
            "best_score": stats["best_score"],
            "average_score": stats["average_score"],
            "total_moves": stats.get("total_moves", 0),
            "average_moves": stats.get("average_moves", 0)
        }
    
    def get_user_history(
        self,
        user_id: int,
        limit: int = 10,
        offset: int = 0
    ) -> Dict[str, Any]:
        """
        Get user's 2048 game history
        
        Args:
            user_id: User ID
            limit: Number of results per page
            offset: Pagination offset
        
        Returns:
            Dict with game history and pagination info
        """
        scores = self.game_score_repository.get_user_scores(user_id, "2048", limit, offset)
        total = self.game_score_repository.count_user_games(user_id, "2048")
        
        result_scores = []
        for score in scores:
            result_scores.append({
                "id": score.id,
                "score": score.score,
                "moves": score.moves,
                "won": score.won,
                "played_at": score.played_at.isoformat()
            })
        
        return {
            "history": result_scores,
            "total": total,
            "limit": limit,
            "offset": offset,
            "has_more": (offset + limit) < total
        }
    
    def get_game_rules(self) -> Dict[str, Any]:
        """
        Get 2048 game rules and instructions
        
        Returns:
            Game rules and tips
        """
        return {
            "name": "2048",
            "description": "Classic number sliding puzzle game",
            "objective": "Combine numbered tiles to create a tile with 2048",
            "rules": [
                "Use arrow keys (or swipe) to move all tiles in a direction",
                "When two tiles with the same number touch, they merge into one",
                "After each move, a new tile (2 or 4) appears in a random empty spot",
                "Game ends when no valid moves remain",
                "Win by creating a 2048 tile"
            ],
            "scoring": {
                "description": "Score increases when tiles merge",
                "formula": "Merged tile value is added to score",
                "example": "Merging two 4s gives +8 points"
            },
            "tips": [
                "Keep your highest value tile in a corner",
                "Build numbers in ascending order around your highest tile",
                "Focus on one corner and don't move in that direction unless necessary",
                "Plan several moves ahead",
                "Keep the board as empty as possible for flexibility"
            ],
            "grid_size": "4x4",
            "win_condition": "Create 2048 tile",
            "lose_condition": "No valid moves remaining"
        }
