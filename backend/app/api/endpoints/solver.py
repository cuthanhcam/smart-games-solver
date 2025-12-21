from fastapi import APIRouter, HTTPException
from app.models.cube import CubeStateRequest
from app.models.solution import SolutionResponse
from app.services.solver_service import SolverService
from app.services.cube_validator import CubeValidator
import time

router = APIRouter()
solver_service = SolverService()
cube_validator = CubeValidator()


@router.post("/solve", response_model=SolutionResponse)
async def solve_cube(cube_state: CubeStateRequest):
    """
    Solve the Rubik's cube and return step-by-step solution.
    
    Args:
        cube_state: Complete validated cube state with all 6 faces
    
    Returns:
        SolutionResponse with solving steps and algorithm
    """
    start_time = time.time()
    
    try:
        # First validate and get Kociemba notation
        validation_result = cube_validator.validate(cube_state)
        
        if not validation_result.is_valid:
            return SolutionResponse(
                success=False,
                steps=[],
                total_moves=0,
                algorithm="",
                execution_time=0.0,
                error_message=validation_result.error_message
            )
        
        # Solve the cube using the validated notation
        solution = await solver_service.solve(cube_state, notation=validation_result.notation)
        
        execution_time = time.time() - start_time
        solution.execution_time = execution_time
        
        return solution
    
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Solving failed: {str(e)}")
