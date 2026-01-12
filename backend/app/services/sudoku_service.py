"""
Sudoku Game Service
Business logic for Sudoku puzzle game
"""
from typing import List, Dict, Any, Optional
from datetime import datetime
from sqlalchemy.orm import Session
import random
import copy

from app.repositories.game_repository import SudokuPuzzleRepository, GameScoreRepository
from app.core.exceptions import AppException


class SudokuService:
    """Service layer for Sudoku game operations"""
    
    GRID_SIZE = 9
    BOX_SIZE = 3
    
    def __init__(self, db: Session):
        """Initialize service with database session"""
        self.db = db
        self.sudoku_repository = SudokuPuzzleRepository()
        self.game_score_repository = GameScoreRepository()
    
    def get_puzzle(
        self,
        difficulty: str = "medium",
        puzzle_id: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Get a Sudoku puzzle by difficulty or ID
        
        Args:
            difficulty: Puzzle difficulty ('easy', 'medium', 'hard')
            puzzle_id: Optional specific puzzle ID
        
        Returns:
            Dict containing puzzle data
        """
        if puzzle_id:
            puzzle = self.sudoku_repository.get_by_id(puzzle_id)
            if not puzzle:
                raise AppException("Puzzle not found", status_code=404)
        else:
            # Get random puzzle by difficulty
            puzzles = self.sudoku_repository.get_by_difficulty(difficulty, limit=10)
            if not puzzles:
                raise AppException(
                    f"No puzzles available for difficulty: {difficulty}",
                    status_code=404
                )
            puzzle = random.choice(puzzles)
        
        return {
            "id": puzzle.id,
            "difficulty": puzzle.difficulty,
            "puzzle": self._parse_grid(puzzle.puzzle_data),
            "solution": self._parse_grid(puzzle.solution_data),
            "hints_used": 0,
            "created_at": puzzle.created_at.isoformat()
        }
    
    def _parse_grid(self, grid_string: str) -> List[List[int]]:
        """
        Parse 81-character grid string to 9x9 matrix
        
        Args:
            grid_string: 81 characters representing Sudoku grid
        
        Returns:
            9x9 matrix of integers
        """
        if len(grid_string) != 81:
            raise AppException(f"Invalid grid string length: {len(grid_string)}")
        
        grid = []
        for i in range(self.GRID_SIZE):
            row = []
            for j in range(self.GRID_SIZE):
                char = grid_string[i * self.GRID_SIZE + j]
                row.append(int(char) if char.isdigit() else 0)
            grid.append(row)
        
        return grid
    
    def _grid_to_string(self, grid: List[List[int]]) -> str:
        """Convert 9x9 grid to 81-character string"""
        result = ""
        for row in grid:
            for val in row:
                result += str(val) if val != 0 else "0"
        return result
    
    def validate_move(
        self,
        grid: List[List[int]],
        row: int,
        col: int,
        value: int
    ) -> Dict[str, Any]:
        """
        Validate if a number can be placed at given position
        
        Args:
            grid: Current Sudoku grid
            row: Row index (0-8)
            col: Column index (0-8)
            value: Number to place (1-9)
        
        Returns:
            Dict with validation result
        """
        if not (0 <= row < self.GRID_SIZE and 0 <= col < self.GRID_SIZE):
            return {
                "valid": False,
                "error": "Position out of bounds"
            }
        
        if not (1 <= value <= 9):
            return {
                "valid": False,
                "error": "Value must be between 1 and 9"
            }
        
        # Check if cell is already filled
        if grid[row][col] != 0:
            return {
                "valid": False,
                "error": "Cell is already filled"
            }
        
        # Check row
        if value in grid[row]:
            return {
                "valid": False,
                "error": f"Number {value} already exists in row {row + 1}",
                "conflict": "row"
            }
        
        # Check column
        for i in range(self.GRID_SIZE):
            if grid[i][col] == value:
                return {
                    "valid": False,
                    "error": f"Number {value} already exists in column {col + 1}",
                    "conflict": "column"
                }
        
        # Check 3x3 box
        box_row = (row // self.BOX_SIZE) * self.BOX_SIZE
        box_col = (col // self.BOX_SIZE) * self.BOX_SIZE
        
        for i in range(box_row, box_row + self.BOX_SIZE):
            for j in range(box_col, box_col + self.BOX_SIZE):
                if grid[i][j] == value:
                    return {
                        "valid": False,
                        "error": f"Number {value} already exists in 3x3 box",
                        "conflict": "box"
                    }
        
        return {
            "valid": True,
            "message": "Valid move"
        }
    
    def make_move(
        self,
        grid: List[List[int]],
        row: int,
        col: int,
        value: int
    ) -> Dict[str, Any]:
        """
        Make a move on the Sudoku grid
        
        Args:
            grid: Current grid
            row: Row index
            col: Column index
            value: Number to place (0 to clear)
        
        Returns:
            Updated grid and validation result
        """
        new_grid = copy.deepcopy(grid)
        
        # If value is 0, clear the cell
        if value == 0:
            new_grid[row][col] = 0
            return {
                "grid": new_grid,
                "valid": True,
                "message": "Cell cleared"
            }
        
        # Validate move
        validation = self.validate_move(grid, row, col, value)
        
        if not validation["valid"]:
            return {
                "grid": grid,
                **validation
            }
        
        # Place the number
        new_grid[row][col] = value
        
        # Check if puzzle is complete
        complete = self._is_complete(new_grid)
        solved = complete and self._is_valid_solution(new_grid)
        
        return {
            "grid": new_grid,
            "valid": True,
            "complete": complete,
            "solved": solved,
            "message": "Move accepted"
        }
    
    def get_hint(
        self,
        puzzle_grid: List[List[int]],
        solution_grid: List[List[int]]
    ) -> Dict[str, Any]:
        """
        Get a hint for the current puzzle state
        
        Args:
            puzzle_grid: Current grid with user's progress
            solution_grid: Complete solution grid
        
        Returns:
            Dict with hint position and value
        """
        # Find all empty cells
        empty_cells = []
        for i in range(self.GRID_SIZE):
            for j in range(self.GRID_SIZE):
                if puzzle_grid[i][j] == 0:
                    empty_cells.append((i, j))
        
        if not empty_cells:
            return {
                "available": False,
                "message": "No empty cells remaining"
            }
        
        # Choose random empty cell
        row, col = random.choice(empty_cells)
        hint_value = solution_grid[row][col]
        
        return {
            "available": True,
            "row": row,
            "col": col,
            "value": hint_value,
            "message": f"Place {hint_value} at row {row + 1}, column {col + 1}"
        }
    
    def _is_complete(self, grid: List[List[int]]) -> bool:
        """Check if all cells are filled"""
        for row in grid:
            if 0 in row:
                return False
        return True
    
    def _is_valid_solution(self, grid: List[List[int]]) -> bool:
        """Check if filled grid is a valid solution"""
        # Check all rows
        for row in grid:
            if len(set(row)) != self.GRID_SIZE or min(row) < 1 or max(row) > 9:
                return False
        
        # Check all columns
        for col in range(self.GRID_SIZE):
            column_values = [grid[row][col] for row in range(self.GRID_SIZE)]
            if len(set(column_values)) != self.GRID_SIZE:
                return False
        
        # Check all 3x3 boxes
        for box_row in range(0, self.GRID_SIZE, self.BOX_SIZE):
            for box_col in range(0, self.GRID_SIZE, self.BOX_SIZE):
                box_values = []
                for i in range(box_row, box_row + self.BOX_SIZE):
                    for j in range(box_col, box_col + self.BOX_SIZE):
                        box_values.append(grid[i][j])
                if len(set(box_values)) != self.GRID_SIZE:
                    return False
        
        return True
    
    def save_score(
        self,
        user_id: int,
        puzzle_id: int,
        time_seconds: int,
        hints_used: int,
        difficulty: str
    ) -> Dict[str, Any]:
        """
        Save Sudoku game completion score
        
        Args:
            user_id: User who completed puzzle
            puzzle_id: Puzzle ID
            time_seconds: Time taken to complete
            hints_used: Number of hints used
            difficulty: Puzzle difficulty
        
        Returns:
            Saved score data
        """
        # Calculate score based on time and hints
        base_score = 1000
        difficulty_multiplier = {"easy": 1.0, "medium": 1.5, "hard": 2.0}
        multiplier = difficulty_multiplier.get(difficulty, 1.0)
        
        # Deduct points for time (1 point per 5 seconds)
        time_penalty = time_seconds // 5
        
        # Deduct points for hints (50 points per hint)
        hint_penalty = hints_used * 50
        
        final_score = max(100, int((base_score - time_penalty - hint_penalty) * multiplier))
        
        score_data = {
            "user_id": user_id,
            "game_type": "sudoku",
            "score": final_score,
            "time_seconds": time_seconds,
            "hints_used": hints_used,
            "won": True
        }
        
        saved_score = self.game_score_repository.create(score_data)
        
        return {
            "id": saved_score.id,
            "user_id": saved_score.user_id,
            "puzzle_id": puzzle_id,
            "difficulty": difficulty,
            "score": saved_score.score,
            "time_seconds": saved_score.time_seconds,
            "hints_used": saved_score.hints_used,
            "played_at": saved_score.played_at.isoformat()
        }
    
    def get_leaderboard(
        self,
        difficulty: Optional[str] = None,
        limit: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Get Sudoku leaderboard
        
        Args:
            difficulty: Optional difficulty filter
            limit: Number of top scores
        
        Returns:
            List of top scores
        """
        scores = self.game_score_repository.get_leaderboard(self.db, "sudoku", limit)
        
        result = []
        rank = 1
        for score in scores:
            result.append({
                "rank": rank,
                "user_id": score.user_id,
                "username": score.user.username if score.user else "Anonymous",
                "score": score.score,
                "time_seconds": score.time_seconds,
                "hints_used": score.hints_used,
                "played_at": score.played_at.isoformat()
            })
            rank += 1
        
        return result
    
    def get_user_stats(self, user_id: int) -> Dict[str, Any]:
        """Get user's Sudoku statistics"""
        stats = self.game_score_repository.get_user_stats(user_id, "sudoku")
        
        return {
            "user_id": user_id,
            "game_type": "sudoku",
            "total_games": stats["total_games"],
            "total_wins": stats["total_wins"],
            "best_score": stats["best_score"],
            "average_score": stats["average_score"],
            "average_time": stats.get("average_time", 0),
            "total_hints": stats.get("total_hints", 0)
        }
    
    def get_game_rules(self) -> Dict[str, Any]:
        """Get Sudoku game rules"""
        return {
            "name": "Sudoku",
            "description": "Logic-based number placement puzzle",
            "objective": "Fill 9x9 grid so each row, column, and 3x3 box contains digits 1-9",
            "rules": [
                "Each row must contain numbers 1-9 without repetition",
                "Each column must contain numbers 1-9 without repetition",
                "Each 3x3 box must contain numbers 1-9 without repetition",
                "Some cells are pre-filled and cannot be changed",
                "Use logic to deduce the correct numbers"
            ],
            "difficulties": {
                "easy": "30-35 pre-filled cells",
                "medium": "25-30 pre-filled cells",
                "hard": "20-25 pre-filled cells"
            },
            "scoring": {
                "base": 1000,
                "time_penalty": "1 point per 5 seconds",
                "hint_penalty": "50 points per hint",
                "difficulty_multiplier": {
                    "easy": "×1.0",
                    "medium": "×1.5",
                    "hard": "×2.0"
                }
            },
            "tips": [
                "Start by filling in rows, columns, or boxes with the most numbers",
                "Look for 'naked singles' - cells where only one number fits",
                "Use pencil marks to track possibilities",
                "Scan rows and columns for missing numbers",
                "Work on easier areas first to gain information"
            ]
        }
