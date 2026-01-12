"""
SQLAlchemy Game models
"""
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, ForeignKey, JSON
from sqlalchemy.orm import relationship
from datetime import datetime
from ..core.database import Base


class GameScore(Base):
    __tablename__ = "game_scores"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    game_type = Column(String(20), nullable=False, index=True)  # '2048', 'sudoku', 'caro', 'rubik'
    score = Column(Integer, default=0, index=True)
    moves = Column(Integer, default=0)
    time_seconds = Column(Integer, default=0)
    completed = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    game_data = Column(JSON, nullable=True)

    # Relationships
    user = relationship("User", back_populates="game_scores")

    def __repr__(self):
        return f"<GameScore(id={self.id}, game_type='{self.game_type}', score={self.score})>"


class RubikSolution(Base):
    __tablename__ = "rubik_solutions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    cube_state = Column(Text, nullable=False)  # 54 character string
    solution = Column(Text, nullable=False)  # Solution steps
    steps_count = Column(Integer, nullable=False)
    time_to_solve_ms = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="rubik_solutions")

    def __repr__(self):
        return f"<RubikSolution(id={self.id}, steps_count={self.steps_count})>"


class SudokuPuzzle(Base):
    __tablename__ = "sudoku_puzzles"

    id = Column(Integer, primary_key=True, index=True)
    difficulty = Column(String(10), nullable=False)  # 'easy', 'medium', 'hard'
    puzzle_data = Column(Text, nullable=False)  # 81 character string
    solution_data = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f"<SudokuPuzzle(id={self.id}, difficulty='{self.difficulty}')>"


class Game2048Session(Base):
    __tablename__ = "game_2048_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    grid_state = Column(JSON, nullable=False)  # 4x4 grid state
    score = Column(Integer, default=0)
    best_score = Column(Integer, default=0)
    game_over = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def __repr__(self):
        return f"<Game2048Session(id={self.id}, score={self.score})>"


class CaroGame(Base):
    __tablename__ = "caro_games"

    id = Column(Integer, primary_key=True, index=True)
    player1_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    player2_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    board_size = Column(Integer, default=15)
    board_state = Column(JSON, nullable=False)
    current_turn = Column(String(10), nullable=False)  # 'player1' or 'player2'
    winner_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    status = Column(String(20), default='in_progress')  # 'in_progress', 'finished', 'abandoned'
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def __repr__(self):
        return f"<CaroGame(id={self.id}, status='{self.status}')>"


class UserActivityLog(Base):
    __tablename__ = "user_activity_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    activity_type = Column(String(50), nullable=False)
    activity_data = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="activity_logs")

    def __repr__(self):
        return f"<UserActivityLog(id={self.id}, activity_type='{self.activity_type}')>"


class Friendship(Base):
    __tablename__ = "friendships"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    friend_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    status = Column(String(20), default='pending')  # 'pending', 'accepted', 'rejected'
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def __repr__(self):
        return f"<Friendship(id={self.id}, user_id={self.user_id}, friend_id={self.friend_id}, status='{self.status}')>"


class Message(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    receiver_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    content = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f"<Message(id={self.id}, sender_id={self.sender_id}, receiver_id={self.receiver_id})>"


class Announcement(Base):
    __tablename__ = "announcements"

    id = Column(Integer, primary_key=True, index=True)
    admin_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(200), nullable=False)
    content = Column(Text, nullable=False)
    type = Column(String(20), default='info')  # 'info', 'warning', 'success', 'error'
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def __repr__(self):
        return f"<Announcement(id={self.id}, title='{self.title}')>"


class AnnouncementRead(Base):
    """Track which announcements have been read by which users"""
    __tablename__ = "announcement_reads"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    announcement_id = Column(Integer, ForeignKey("announcements.id", ondelete="CASCADE"), nullable=False, index=True)
    read_at = Column(DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f"<AnnouncementRead(user_id={self.user_id}, announcement_id={self.announcement_id})>"


class AnnouncementHidden(Base):
    """Track which announcements have been hidden by which users"""
    __tablename__ = "announcement_hidden"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    announcement_id = Column(Integer, ForeignKey("announcements.id", ondelete="CASCADE"), nullable=False, index=True)
    hidden_at = Column(DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f"<AnnouncementHidden(user_id={self.user_id}, announcement_id={self.announcement_id})>"
