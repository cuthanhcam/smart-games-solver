"""
Pydantic schemas for request/response validation
"""
from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional, List
from datetime import datetime


# ============= Auth Schemas =============
class UserRegisterRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=6)

    @validator('username')
    def username_alphanumeric(cls, v):
        if not v.isalnum() and '_' not in v:
            raise ValueError('Username must be alphanumeric or contain underscore')
        return v


class UserLoginRequest(BaseModel):
    username_or_email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"


class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    is_admin: bool
    created_at: datetime
    is_banned: bool
    ban_reason: Optional[str] = None

    class Config:
        from_attributes = True


# ============= Rubik Solver Schemas =============
class FaceColors(BaseModel):
    face_name: str = Field(..., pattern="^(front|back|left|right|top|bottom|U|R|F|D|L|B)$")
    colors: List[List[str]] = Field(..., min_items=3, max_items=3)

    @validator('colors')
    def validate_colors(cls, v):
        for row in v:
            if len(row) != 3:
                raise ValueError('Each row must have exactly 3 colors')
            for color in row:
                if color not in ['W', 'R', 'G', 'Y', 'B', 'O', 'w', 'r', 'g', 'y', 'b', 'o']:
                    raise ValueError(f'Invalid color: {color}')
        return v


class RubikSolveRequest(BaseModel):
    faces: List[FaceColors] = Field(..., min_items=6, max_items=6)
    user_id: Optional[int] = None


class RubikSolveResponse(BaseModel):
    solution: str
    steps_count: int
    time_to_solve_ms: int
    cube_state: str
    success: bool
    message: Optional[str] = None


# ============= Game 2048 Schemas =============
class Game2048NewRequest(BaseModel):
    user_id: int


class Game2048MoveRequest(BaseModel):
    session_id: int
    direction: str = Field(..., pattern="^(up|down|left|right)$")


class Game2048StateResponse(BaseModel):
    session_id: int
    grid_state: List[List[int]]
    score: int
    best_score: int
    game_over: bool
    message: Optional[str] = None

    class Config:
        from_attributes = True


# ============= Sudoku Schemas =============
class SudokuNewGameRequest(BaseModel):
    difficulty: str = Field(..., pattern="^(easy|medium|hard)$")
    user_id: int


class SudokuMoveRequest(BaseModel):
    puzzle_id: int
    row: int = Field(..., ge=0, le=8)
    col: int = Field(..., ge=0, le=8)
    value: int = Field(..., ge=0, le=9)  # 0 means clear cell


class SudokuPuzzleResponse(BaseModel):
    puzzle_id: int
    difficulty: str
    puzzle_data: str  # 81 characters
    solution_data: str  # 81 characters

    class Config:
        from_attributes = True


class SudokuValidateRequest(BaseModel):
    puzzle_id: int
    user_solution: str = Field(..., min_length=81, max_length=81)


class SudokuValidateResponse(BaseModel):
    is_correct: bool
    errors: List[dict] = []
    completion_percentage: float


# ============= Caro Schemas =============
class CaroNewGameRequest(BaseModel):
    player1_id: int
    player2_id: Optional[int] = None  # None for AI opponent
    board_size: int = Field(default=15, ge=10, le=20)


class CaroMoveRequest(BaseModel):
    game_id: int
    player_id: int
    row: int
    col: int


class CaroAIMoveRequest(BaseModel):
    game_id: int
    difficulty: str = Field(default="medium", pattern="^(easy|medium|hard)$")


class CaroGameStateResponse(BaseModel):
    game_id: int
    board_state: List[List[int]]  # 0: empty, 1: player1, 2: player2
    current_turn: str
    status: str
    winner_id: Optional[int] = None
    message: Optional[str] = None

    class Config:
        from_attributes = True


# ============= 2048 Game Schemas =============
class Game2048NewRequest(BaseModel):
    pass  # No params needed for new game


class Game2048MoveRequest(BaseModel):
    game_id: Optional[int] = None
    grid: List[List[int]]
    score: int
    direction: str = Field(..., pattern="^(up|down|left|right)$")


class Game2048StateResponse(BaseModel):
    game_id: Optional[int] = None
    grid: List[List[int]]
    score: int
    game_over: bool
    won: bool
    can_move: bool

    class Config:
        from_attributes = True


# ============= Leaderboard Schemas =============
class LeaderboardEntry(BaseModel):
    rank: int
    username: str
    game_type: str
    score: int
    completed: bool
    created_at: datetime

    class Config:
        from_attributes = True


class LeaderboardResponse(BaseModel):
    game_type: str
    entries: List[LeaderboardEntry]
    total_count: int


# ============= User Activity Schemas =============
class UserActivityRequest(BaseModel):
    user_id: int
    activity_type: str
    activity_data: Optional[dict] = None


class UserActivityResponse(BaseModel):
    id: int
    activity_type: str
    activity_data: Optional[dict]
    created_at: datetime

    class Config:
        from_attributes = True


# Update forward references
TokenResponse.model_rebuild()

# ============= Friend Schemas =============
class FriendshipResponse(BaseModel):
    id: int
    user_id: int
    friend_id: int
    status: str  # 'pending', 'accepted', 'rejected'
    created_at: datetime

    class Config:
        from_attributes = True


class UserSearchResponse(BaseModel):
    id: int
    username: str
    email: str
    is_admin: bool
    created_at: datetime

    class Config:
        from_attributes = True


class FriendListResponse(BaseModel):
    id: int
    username: str
    email: str
    friend_id: int
    created_at: datetime

    class Config:
        from_attributes = True


class SendFriendRequestRequest(BaseModel):
    receiver_id: int


class AcceptFriendRequestRequest(BaseModel):
    friendship_id: int


class RejectFriendRequestRequest(BaseModel):
    friendship_id: int


class RemoveFriendRequest(BaseModel):
    friend_id: int


# ============= Message Schemas =============
class SendMessageRequest(BaseModel):
    receiver_id: int
    content: str = Field(..., min_length=1, max_length=1000)


class MessageResponse(BaseModel):
    id: int
    sender_id: int
    receiver_id: int
    content: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True


class ChatListResponse(BaseModel):
    user_id: int
    username: str
    email: str
    last_message: Optional[str] = None
    last_message_time: Optional[datetime] = None
    is_read: bool = False
    is_sent_by_me: bool = False
    unread_count: int = 0


class MarkMessageAsReadRequest(BaseModel):
    message_id: int


# ============= Announcement Schemas =============
class CreateAnnouncementRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    content: str = Field(..., min_length=1)
    type: str = Field(default='info', pattern="^(info|warning|success|error)$")


class AnnouncementResponse(BaseModel):
    id: int
    admin_id: int
    title: str
    content: str
    type: str
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class UpdateAnnouncementRequest(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    type: Optional[str] = None
    is_active: Optional[bool] = None


# ============= Game Score Save Schemas =============
class Game2048SaveScoreRequest(BaseModel):
    score: int
    moves: int
    won: bool = False


class SudokuSaveScoreRequest(BaseModel):
    puzzle_id: int
    time_seconds: int
    hints_used: int
    difficulty: str


class CaroSaveScoreRequest(BaseModel):
    moves: int
    board_size: int
    difficulty: str
    player_color: str  # "X" or "O"
    opponent_type: str  # "human" or "ai"