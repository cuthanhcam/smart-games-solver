from fastapi import APIRouter, UploadFile, File, HTTPException
from app.models.cube import DetectionResponse, CubeStateRequest, CubeStateResponse
from app.services.detection_service import DetectionService
from app.services.cube_validator import CubeValidator

router = APIRouter()
detection_service = DetectionService()
cube_validator = CubeValidator()


@router.post("/detect", response_model=DetectionResponse)
async def detect_cube_face(
    image: UploadFile = File(...),
    face_name: str = "front"
):
    """
    Detect Rubik's cube face colors from an uploaded image.
    
    Args:
        image: Image file containing a Rubik's cube face
        face_name: Name of the face being scanned (front, back, left, right, top, bottom)
    
    Returns:
        DetectionResponse with detected colors and confidence score
    """
    # Validate file type
    if not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    # Read image
    contents = await image.read()
    
    # Detect colors
    result = await detection_service.detect_face(contents, face_name)
    
    return result


@router.post("/validate", response_model=CubeStateResponse)
async def validate_cube_state(cube_state: CubeStateRequest):
    """
    Validate if the scanned cube state is valid and solvable.
    
    Args:
        cube_state: Complete cube state with all 6 faces
    
    Returns:
        CubeStateResponse indicating if the cube is valid
    """
    result = cube_validator.validate(cube_state)
    return result
