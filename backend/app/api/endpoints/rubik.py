"""
Rubik Cube Solver Endpoints
Clean architecture with service layer
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import Optional

from app.core.database import get_db
from app.core.dependencies import get_current_user, get_optional_user
from app.models.user import User
from app.models.schemas import RubikSolveRequest, RubikSolveResponse
from app.services.rubik_service import RubikService

router = APIRouter(prefix="/rubik", tags=["Rubik Solver"])




@router.post("/solve", response_model=RubikSolveResponse, status_code=200)
async def solve_rubik(
    request: RubikSolveRequest,
    current_user: Optional[User] = Depends(get_optional_user),
    db: Session = Depends(get_db)
):
    """
    Solve Rubik cube from manual color input using Kociemba algorithm
    
    **Authentication**: Optional (guests can solve, but won't save history)
    
    **Request**:
    - `faces`: 6 faces with 3x3 color grid each
    - Colors: W (White/Up), R (Red/Right), G (Green/Front), 
             Y (Yellow/Down), B (Blue/Left), O (Orange/Back)
    
    **Response**:
    - `solution`: Move sequence in standard notation (e.g., "R U R' U'")
    - `steps`: List of individual moves
    - `move_count`: Number of moves (max 20 for optimal)
    - `estimated_time`: Estimated solving time for humans
    
    **Algorithm**: Kociemba Two-Phase (near-optimal, max 20 moves)
    """
    service = RubikService(db)
    
    # Convert faces to 54-character cube state string
    cube_state = _faces_to_cube_state(request.faces)
    
    # Solve cube (service handles validation and saving)
    user_id = current_user.id if current_user else None
    result = service.solve_cube(cube_state, user_id)
    
    return RubikSolveResponse(
        solution=result["solution"],
        steps=result["steps"],
        move_count=result["move_count"],
        time_to_solve_ms=int(result["estimated_time"] * 1000),
        cube_state=result["cube_state"],
        success=True,
        message="Cube solved successfully!" + (
            " (Not logged in - solution not saved)" if not current_user else ""
        )
    )


@router.get("/history")
async def get_user_solutions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = 10,
    offset: int = 0
):
    """
    Get authenticated user's Rubik solving history
    
    **Authentication**: Required
    
    **Query Parameters**:
    - `limit`: Number of solutions per page (default: 10)
    - `offset`: Pagination offset (default: 0)
    
    **Returns**:
    - List of solutions with pagination info
    - Each solution includes cube state, solution, move count, timestamp
    """
    service = RubikService(db)
    result = service.get_user_solutions(current_user.id, limit, offset)
    
    return {
        "user_id": current_user.id,
        "username": current_user.username,
        **result
    }


@router.get("/history/best")
async def get_user_best_solution(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get user's best solution (fewest moves)
    
    **Authentication**: Required
    
    **Returns**:
    - Best solution or 404 if user has no solutions
    """
    service = RubikService(db)
    best_solution = service.get_user_best_solution(current_user.id)
    
    if not best_solution:
        return {
            "message": "No solutions found",
            "best_solution": None
        }
    
    return {
        "user_id": current_user.id,
        "username": current_user.username,
        "best_solution": best_solution
    }


@router.delete("/history/{solution_id}", status_code=204)
async def delete_solution(
    solution_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Delete a solution from history
    
    **Authentication**: Required (can only delete own solutions)
    
    **Returns**: 204 No Content on success
    """
    service = RubikService(db)
    service.delete_solution(solution_id, current_user.id)


@router.get("/leaderboard")
async def get_leaderboard(
    db: Session = Depends(get_db),
    limit: int = 10
):
    """
    Get global Rubik solving leaderboard
    
    **Authentication**: Not required
    
    **Sorting**: By fewest moves (lower is better)
    
    **Query Parameters**:
    - `limit`: Number of top solvers (default: 10, max: 100)
    
    **Returns**:
    - List of best solutions with username and statistics
    """
    service = RubikService(db)
    leaderboard = service.get_best_solutions(min(limit, 100))
    
    return {
        "leaderboard": leaderboard,
        "total": len(leaderboard)
    }


@router.get("/algorithm-info")
async def get_algorithm_info():
    """
    Get information about Rubik solving algorithm and usage guide
    
    **Authentication**: Not required
    
    **Returns**:
    - Algorithm details (Kociemba Two-Phase)
    - Cube notation guide (U, R, F, D, L, B faces)
    - Move notation (clockwise, counter-clockwise, 180°)
    - Input format specification
    - Performance characteristics
    """
    service = RubikService(Session())
    return service.get_algorithm_info()


def _faces_to_cube_state(faces) -> str:
    """
    Convert 6 faces with 3x3 colors to Kociemba format (54-character string)
    
    Face order: U (Up), R (Right), F (Front), D (Down), L (Left), B (Back)
    Color mapping: W→U, R→R, G→F, Y→D, B→L, O→B
    
    Example: "UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB"
    """
    # Map face names to order indices
    face_order = {
        'U': 0, 'up': 0, 'top': 0,
        'R': 1, 'right': 1,
        'F': 2, 'front': 2,
        'D': 3, 'down': 3, 'bottom': 3,
        'L': 4, 'left': 4,
        'B': 5, 'back': 5
    }
    
    # Color to facelet mapping (Rubik's cube standard)
    color_map = {
        'W': 'U', 'w': 'U',  # White → Up face
        'R': 'R', 'r': 'R',  # Red → Right face
        'G': 'F', 'g': 'F',  # Green → Front face
        'Y': 'D', 'y': 'D',  # Yellow → Down face
        'B': 'L', 'b': 'L',  # Blue → Left face
        'O': 'B', 'o': 'B'   # Orange → Back face
    }
    
    # Initialize 6 face strings
    cube_facelets = [''] * 6
    
    for face in faces:
        # Get face index
        face_name_lower = face.face_name.lower()
        face_idx = face_order.get(
            face_name_lower,
            face_order.get(face.face_name.upper(), 0)
        )
        
        # Flatten 3x3 grid to 9 characters
        face_str = ''
        for row in face.colors:
            for color in row:
                mapped_color = color_map.get(color, color.upper())
                face_str += mapped_color
        
        cube_facelets[face_idx] = face_str
    
    # Join all 6 faces into 54-character string
    return ''.join(cube_facelets)

