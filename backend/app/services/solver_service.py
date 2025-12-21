import kociemba
from app.models.cube import CubeStateRequest, FaceColor
from app.models.solution import SolutionResponse, SolutionStep
from typing import List


class SolverService:
    """Service for solving Rubik's cube using Kociemba algorithm."""
    
    MOVE_DESCRIPTIONS = {
        "U": "Turn upper face clockwise",
        "U'": "Turn upper face counter-clockwise",
        "U2": "Turn upper face 180 degrees",
        "D": "Turn down face clockwise",
        "D'": "Turn down face counter-clockwise",
        "D2": "Turn down face 180 degrees",
        "L": "Turn left face clockwise",
        "L'": "Turn left face counter-clockwise",
        "L2": "Turn left face 180 degrees",
        "R": "Turn right face clockwise",
        "R'": "Turn right face counter-clockwise",
        "R2": "Turn right face 180 degrees",
        "F": "Turn front face clockwise",
        "F'": "Turn front face counter-clockwise",
        "F2": "Turn front face 180 degrees",
        "B": "Turn back face clockwise",
        "B'": "Turn back face counter-clockwise",
        "B2": "Turn back face 180 degrees",
    }
    
    async def solve(self, cube_state: CubeStateRequest, notation: str = None) -> SolutionResponse:
        """
        Solve the Rubik's cube using Kociemba's two-phase algorithm.
        
        Args:
            cube_state: Complete validated cube state
            notation: Optional pre-computed Kociemba notation string
        
        Returns:
            SolutionResponse with steps to solve the cube
        """
        try:
            # Use provided notation or convert cube state
            if notation is None:
                notation = self._convert_to_kociemba_notation(cube_state)
            
            # Solve using Kociemba algorithm
            solution_string = kociemba.solve(notation)
            
            # Parse solution into steps
            moves = solution_string.split()
            steps = [
                SolutionStep(
                    move=move,
                    notation=move,
                    description=self.MOVE_DESCRIPTIONS.get(move, f"Move: {move}")
                )
                for move in moves
            ]
            
            return SolutionResponse(
                success=True,
                steps=steps,
                total_moves=len(steps),
                algorithm=solution_string,
                execution_time=0.0,  # Will be set by the endpoint
                error_message=None
            )
        
        except Exception as e:
            return SolutionResponse(
                success=False,
                steps=[],
                total_moves=0,
                algorithm="",
                execution_time=0.0,
                error_message=f"Failed to solve: {str(e)}"
            )
    
    def _convert_to_kociemba_notation(self, cube_state: CubeStateRequest) -> str:
        """
        Convert our cube state to Kociemba notation string.
        
        Kociemba notation format (54 chars):
        - First 9: Upper face (U)
        - Next 9: Right face (R)
        - Next 9: Front face (F)
        - Next 9: Down face (D)
        - Next 9: Left face (L)
        - Next 9: Back face (B)
        
        Colors: U (white/yellow), R (red/orange), F (green/blue), D, L, B
        """
        # Map our face names to Kociemba order
        face_order = ["top", "right", "front", "bottom", "left", "back"]
        
        # Build notation string
        notation = ""
        for face_name in face_order:
            # Find the face in cube_state
            face = next((f for f in cube_state.faces if f.face_name == face_name), None)
            if not face:
                raise ValueError(f"Missing face: {face_name}")
            
            # Add colors to notation
            for row in face.colors:
                for color in row:
                    # Map our colors to Kociemba notation
                    notation += self._map_color_to_kociemba(color)
        
        return notation
    
    def _map_color_to_kociemba(self, color: FaceColor) -> str:
        """Map our color codes to Kociemba notation."""
        # This mapping depends on your cube orientation
        # Adjust based on your specific setup
        mapping = {
            FaceColor.WHITE: "U",
            FaceColor.YELLOW: "D",
            FaceColor.RED: "R",
            FaceColor.ORANGE: "L",
            FaceColor.BLUE: "F",
            FaceColor.GREEN: "B",
        }
        return mapping.get(color, "U")
