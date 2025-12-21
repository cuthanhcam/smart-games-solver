from app.models.cube import CubeStateRequest, CubeStateResponse, FaceColor
from typing import Dict, List


class CubeValidator:
    """Service for validating Rubik's cube state."""
    
    def validate(self, cube_state: CubeStateRequest) -> CubeStateResponse:
        """
        Validate if a cube state is valid and solvable.
        
        A valid cube must have:
        - Exactly 6 faces
        - 9 stickers per face (3x3)
        - 9 stickers of each color across all faces
        - Valid center colors
        
        Args:
            cube_state: The cube state to validate
        
        Returns:
            CubeStateResponse indicating validity with Kociemba notation
        """
        # Check number of faces
        if len(cube_state.faces) != 6:
            return CubeStateResponse(
                is_valid=False,
                notation="",
                error_message="Cube must have exactly 6 faces"
            )
        
        # Count colors
        color_count: Dict[str, int] = {}
        
        # Define standard Rubik's cube color-to-face mapping
        # Based on Western/International standard:
        # F (Front) = Red, U (Up) = White, R (Right) = Blue
        # L (Left) = Green, B (Back) = Orange, D (Down) = Yellow
        standard_color_to_face: Dict[str, str] = {
            "W": "U",  # White -> Up
            "R": "F",  # Red -> Front
            "B": "R",  # Blue -> Right
            "G": "L",  # Green -> Left
            "O": "B",  # Orange -> Back
            "Y": "D",  # Yellow -> Down
        }
        
        # Collect all faces and build color mapping from centers
        faces_by_center: Dict[str, any] = {}
        for face in cube_state.faces:
            # Check face dimensions
            if len(face.colors) != 3 or any(len(row) != 3 for row in face.colors):
                return CubeStateResponse(
                    is_valid=False,
                    notation="",
                    error_message=f"Face {face.face_name} must be 3x3"
                )
            
            # Get center color (position [1][1])
            center_color = face.colors[1][1].value
            
            # Verify center color is valid
            if center_color not in standard_color_to_face:
                return CubeStateResponse(
                    is_valid=False,
                    notation="",
                    error_message=f"Invalid center color: {center_color}"
                )
            
            # Store face by its center color
            faces_by_center[center_color] = face
        
        # Verify we have all 6 center colors
        if len(faces_by_center) != 6:
            return CubeStateResponse(
                is_valid=False,
                notation="",
                error_message=f"Must have 6 unique center colors, found {len(faces_by_center)}"
            )
        
        # Build notation in Kociemba order: U, R, F, D, L, B
        # Which corresponds to colors: W, B, R, Y, G, O
        kociemba_order = ["W", "B", "R", "Y", "G", "O"]  # Colors in order U, R, F, D, L, B
        notation = ""
        
        for center_color in kociemba_order:
            face = faces_by_center.get(center_color)
            if not face:
                return CubeStateResponse(
                    is_valid=False,
                    notation="",
                    error_message=f"Missing face with center color: {center_color}"
                )
            
            # Convert each sticker color to its face notation
            for row in face.colors:
                for color in row:
                    color_value = color.value
                    color_count[color_value] = color_count.get(color_value, 0) + 1
                    
                    # Map color to face notation using standard mapping
                    if color_value in standard_color_to_face:
                        notation += standard_color_to_face[color_value]
                    else:
                        return CubeStateResponse(
                            is_valid=False,
                            notation="",
                            error_message=f"Unknown color: {color_value}"
                        )
        
        # Check color counts (should be 9 of each)
        for color, count in color_count.items():
            if count != 9:
                return CubeStateResponse(
                    is_valid=False,
                    notation="",
                    error_message=f"Invalid color count: {color} appears {count} times (should be 9)"
                )
        
        return CubeStateResponse(
            is_valid=True,
            notation=notation,
            error_message=None
        )
