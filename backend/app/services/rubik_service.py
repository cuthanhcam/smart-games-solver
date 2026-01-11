"""
Rubik Cube Solver Service
Business logic for Rubik Cube solving using Kociemba algorithm
"""
from typing import List, Dict, Any, Optional
from datetime import datetime
from sqlalchemy.orm import Session
import kociemba

from app.repositories.game_repository import RubikSolutionRepository
from app.core.exceptions import InvalidCubeStateError, AppException


class RubikService:
    """Service layer for Rubik Cube solving operations"""
    
    def __init__(self, db: Session):
        """Initialize service with database session"""
        self.db = db
        self.rubik_repository = RubikSolutionRepository()
    
    def validate_cube_state(self, cube_state: str) -> None:
        """
        Validate Rubik cube state string
        
        Args:
            cube_state: 54-character string representing cube faces
        
        Raises:
            InvalidCubeStateError: If cube state is invalid
        """
        if len(cube_state) != 54:
            raise InvalidCubeStateError(
                f"Cube state must be 54 characters, got {len(cube_state)}"
            )
        
        # Check valid colors (URFDLB)
        valid_colors = set('URFDLB')
        if not all(c in valid_colors for c in cube_state):
            invalid_chars = set(cube_state) - valid_colors
            raise InvalidCubeStateError(
                f"Invalid colors in cube state: {invalid_chars}. Valid colors: U, R, F, D, L, B"
            )
        
        # Check each color appears exactly 9 times (9 facets per face)
        color_counts = {color: cube_state.count(color) for color in valid_colors}
        invalid_counts = {color: count for color, count in color_counts.items() if count != 9}
        
        if invalid_counts:
            raise InvalidCubeStateError(
                f"Each color must appear exactly 9 times. Invalid counts: {invalid_counts}"
            )
    
    def solve_cube(self, cube_state: str, user_id: Optional[int] = None) -> Dict[str, Any]:
        """
        Solve Rubik cube using Kociemba algorithm
        
        Args:
            cube_state: 54-character string representing cube
            user_id: Optional user ID to save solution
        
        Returns:
            Dict containing solution steps and move count
        
        Raises:
            InvalidCubeStateError: If cube cannot be solved
        """
        # Validate cube state
        self.validate_cube_state(cube_state)
        
        try:
            # Solve using Kociemba algorithm
            solution = kociemba.solve(cube_state)
            
            # Parse solution steps
            steps = solution.split()
            move_count = len(steps)
            
            # Calculate solving time estimate (based on typical human speed: ~1-2 seconds per move)
            estimated_time_seconds = move_count * 1.5
            
            result = {
                "cube_state": cube_state,
                "solution": solution,
                "steps": steps,
                "move_count": move_count,
                "estimated_time": estimated_time_seconds,
                "algorithm": "Kociemba Two-Phase",
                "optimal": "Near-optimal (max 20 moves)",
                "solved_at": datetime.utcnow().isoformat()
            }
            
            # Save to database if user is logged in
            if user_id:
                self.save_solution(
                    user_id=user_id,
                    cube_state=cube_state,
                    solution=solution,
                    move_count=move_count
                )
            
            return result
            
        except Exception as e:
            if "Error" in str(e) or "invalid" in str(e).lower():
                raise InvalidCubeStateError(
                    f"Invalid cube configuration: {str(e)}"
                )
            raise AppException(f"Failed to solve cube: {str(e)}")
    
    def save_solution(
        self,
        user_id: int,
        cube_state: str,
        solution: str,
        move_count: int
    ) -> Dict[str, Any]:
        """
        Save Rubik solution to database
        
        Args:
            user_id: User who solved the cube
            cube_state: Original cube state
            solution: Solution string
            move_count: Number of moves in solution
        
        Returns:
            Saved solution data
        """
        solution_data = {
            "user_id": user_id,
            "cube_state": cube_state,
            "solution": solution,
            "move_count": move_count
        }
        
        saved_solution = self.rubik_repository.create(solution_data)
        
        return {
            "id": saved_solution.id,
            "user_id": saved_solution.user_id,
            "cube_state": saved_solution.cube_state,
            "solution": saved_solution.solution,
            "move_count": saved_solution.move_count,
            "solved_at": saved_solution.solved_at.isoformat()
        }
    
    def get_user_solutions(
        self,
        user_id: int,
        limit: int = 10,
        offset: int = 0
    ) -> Dict[str, Any]:
        """
        Get user's Rubik solving history
        
        Args:
            user_id: User ID
            limit: Number of results per page
            offset: Pagination offset
        
        Returns:
            Dict with solutions and pagination info
        """
        solutions = self.rubik_repository.get_by_user(user_id, limit, offset)
        total = self.rubik_repository.count_by_user(user_id)
        
        result_solutions = []
        for sol in solutions:
            result_solutions.append({
                "id": sol.id,
                "cube_state": sol.cube_state,
                "solution": sol.solution,
                "move_count": sol.move_count,
                "solved_at": sol.solved_at.isoformat()
            })
        
        return {
            "solutions": result_solutions,
            "total": total,
            "limit": limit,
            "offset": offset,
            "has_more": (offset + limit) < total
        }
    
    def get_best_solutions(
        self,
        limit: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Get best (fewest moves) solutions from all users
        
        Args:
            limit: Number of results to return
        
        Returns:
            List of best solutions with user info
        """
        solutions = self.rubik_repository.get_best_solutions(limit)
        
        result = []
        for sol in solutions:
            result.append({
                "id": sol.id,
                "user_id": sol.user_id,
                "username": sol.user.username if sol.user else "Anonymous",
                "cube_state": sol.cube_state,
                "solution": sol.solution,
                "move_count": sol.move_count,
                "solved_at": sol.solved_at.isoformat()
            })
        
        return result
    
    def get_user_best_solution(self, user_id: int) -> Optional[Dict[str, Any]]:
        """
        Get user's best (fewest moves) solution
        
        Args:
            user_id: User ID
        
        Returns:
            Best solution or None
        """
        solution = self.rubik_repository.get_user_best(user_id)
        
        if not solution:
            return None
        
        return {
            "id": solution.id,
            "cube_state": solution.cube_state,
            "solution": solution.solution,
            "move_count": solution.move_count,
            "solved_at": solution.solved_at.isoformat()
        }
    
    def delete_solution(self, solution_id: int, user_id: int) -> None:
        """
        Delete a solution (only by owner or admin)
        
        Args:
            solution_id: Solution ID to delete
            user_id: User requesting deletion
        
        Raises:
            AppException: If solution not found or unauthorized
        """
        solution = self.rubik_repository.get_by_id(solution_id)
        
        if not solution:
            raise AppException("Solution not found", status_code=404)
        
        if solution.user_id != user_id:
            raise AppException(
                "Unauthorized to delete this solution",
                status_code=403
            )
        
        self.rubik_repository.delete(solution_id)
    
    def get_algorithm_info(self) -> Dict[str, Any]:
        """
        Get information about Rubik solving algorithm
        
        Returns:
            Algorithm details and usage guide
        """
        return {
            "algorithm": "Kociemba Two-Phase Algorithm",
            "description": "Optimal Rubik's Cube solver using two-phase algorithm",
            "features": [
                "Near-optimal solutions (maximum 20 moves)",
                "Fast computation (typically < 1 second)",
                "Guaranteed to find solution for valid cubes"
            ],
            "cube_notation": {
                "U": "Up face (white)",
                "R": "Right face (red)",
                "F": "Front face (green)",
                "D": "Down face (yellow)",
                "L": "Left face (orange)",
                "B": "Back face (blue)"
            },
            "move_notation": {
                "U": "Rotate Up face clockwise",
                "U'": "Rotate Up face counter-clockwise",
                "U2": "Rotate Up face 180 degrees",
                "R, F, D, L, B": "Similar for other faces"
            },
            "input_format": {
                "length": 54,
                "description": "54-character string representing all cube facets",
                "order": "U face (9) + R face (9) + F face (9) + D face (9) + L face (9) + B face (9)",
                "example": "UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB",
                "validation": "Each color (U, R, F, D, L, B) must appear exactly 9 times"
            },
            "performance": {
                "max_moves": 20,
                "typical_moves": "15-20",
                "computation_time": "< 1 second",
                "optimal": "Near-optimal (God's number is 20)"
            }
        }
