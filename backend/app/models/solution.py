from pydantic import BaseModel, Field
from typing import List, Optional


class SolutionStep(BaseModel):
    move: str
    notation: str
    description: str


class SolutionResponse(BaseModel):
    success: bool
    steps: List[SolutionStep]
    total_moves: int
    algorithm: str
    execution_time: float
    error_message: Optional[str] = None
    
    class Config:
        json_schema_extra = {
            "example": {
                "success": True,
                "steps": [
                    {
                        "move": "U",
                        "notation": "U",
                        "description": "Turn upper face clockwise"
                    },
                    {
                        "move": "R",
                        "notation": "R",
                        "description": "Turn right face clockwise"
                    }
                ],
                "total_moves": 20,
                "algorithm": "U R U' R' U' F' U F",
                "execution_time": 0.125
            }
        }
