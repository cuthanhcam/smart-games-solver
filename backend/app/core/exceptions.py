"""
Custom Exceptions
Định nghĩa các exception riêng cho application
"""
from typing import Optional


class AppException(Exception):
    """Base exception cho tất cả app exceptions"""
    
    def __init__(
        self, 
        message: str,
        status_code: int = 500,
        error_code: Optional[str] = None
    ):
        self.message = message
        self.status_code = status_code
        self.error_code = error_code or self.__class__.__name__
        super().__init__(self.message)


# Authentication Exceptions
class AuthenticationError(AppException):
    """Lỗi xác thực"""
    def __init__(self, message: str = "Authentication failed"):
        super().__init__(message, status_code=401, error_code="AUTH_ERROR")


class UserNotFoundError(AppException):
    """User không tồn tại"""
    def __init__(self, message: str = "User not found"):
        super().__init__(message, status_code=404, error_code="USER_NOT_FOUND")


class UserAlreadyExistsError(AppException):
    """User đã tồn tại"""
    def __init__(self, message: str = "User already exists"):
        super().__init__(message, status_code=400, error_code="USER_EXISTS")


class UserBannedError(AppException):
    """User bị banned"""
    def __init__(self, message: str = "User is banned"):
        super().__init__(message, status_code=403, error_code="USER_BANNED")


class InvalidTokenError(AppException):
    """Token không hợp lệ"""
    def __init__(self, message: str = "Invalid or expired token"):
        super().__init__(message, status_code=401, error_code="INVALID_TOKEN")


class PermissionDeniedError(AppException):
    """Không có quyền"""
    def __init__(self, message: str = "Permission denied"):
        super().__init__(message, status_code=403, error_code="PERMISSION_DENIED")


# Game Exceptions
class GameNotFoundError(AppException):
    """Game không tồn tại"""
    def __init__(self, message: str = "Game not found"):
        super().__init__(message, status_code=404, error_code="GAME_NOT_FOUND")


class InvalidGameMoveError(AppException):
    """Nước đi không hợp lệ"""
    def __init__(self, message: str = "Invalid game move"):
        super().__init__(message, status_code=400, error_code="INVALID_MOVE")


class GameAlreadyFinishedError(AppException):
    """Game đã kết thúc"""
    def __init__(self, message: str = "Game already finished"):
        super().__init__(message, status_code=400, error_code="GAME_FINISHED")


# Rubik Cube Exceptions
class InvalidCubeStateError(AppException):
    """Trạng thái rubik không hợp lệ"""
    def __init__(self, message: str = "Invalid cube state"):
        super().__init__(message, status_code=400, error_code="INVALID_CUBE_STATE")


class CubeSolverError(AppException):
    """Lỗi khi giải rubik"""
    def __init__(self, message: str = "Cannot solve cube"):
        super().__init__(message, status_code=500, error_code="CUBE_SOLVER_ERROR")


# Validation Exceptions
class ValidationError(AppException):
    """Lỗi validation"""
    def __init__(self, message: str = "Validation error"):
        super().__init__(message, status_code=422, error_code="VALIDATION_ERROR")


# Database Exceptions
class DatabaseError(AppException):
    """Lỗi database"""
    def __init__(self, message: str = "Database error"):
        super().__init__(message, status_code=500, error_code="DATABASE_ERROR")
