from pydantic import BaseModel, Field
from typing import List, Optional
from enum import Enum


class FaceColor(str, Enum):
    WHITE = "W"
    YELLOW = "Y"
    RED = "R"
    ORANGE = "O"
    BLUE = "B"
    GREEN = "G"


class FaceName(str, Enum):
    FRONT = "front"
    BACK = "back"
    LEFT = "left"
    RIGHT = "right"
    TOP = "top"
    BOTTOM = "bottom"


class CubeFaceRequest(BaseModel):
    face_name: FaceName
    colors: List[List[FaceColor]] = Field(..., min_length=3, max_length=3)
    
    class Config:
        json_schema_extra = {
            "example": {
                "face_name": "front",
                "colors": [
                    ["W", "W", "W"],
                    ["W", "W", "W"],
                    ["W", "W", "W"]
                ]
            }
        }


class CubeFaceResponse(BaseModel):
    face_name: FaceName
    colors: List[List[FaceColor]]
    notation: str


class CubeStateRequest(BaseModel):
    faces: List[CubeFaceRequest] = Field(..., min_length=6, max_length=6)


class CubeStateResponse(BaseModel):
    is_valid: bool
    notation: str
    error_message: Optional[str] = None


class DetectionResponse(BaseModel):
    success: bool
    face_name: FaceName
    colors: List[List[FaceColor]]
    confidence: float
    message: Optional[str] = None
