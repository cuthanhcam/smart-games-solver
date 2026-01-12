"""
Game Repository
Xử lý data access cho game scores và sessions
"""
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from datetime import datetime

from ..models.game import (
    GameScore, SudokuPuzzle, 
    Game2048Session, CaroGame, UserActivityLog
)
from .base import BaseRepository


class GameScoreRepository(BaseRepository[GameScore, dict, dict]):
    """Repository cho GameScore"""
    
    def __init__(self):
        super().__init__(GameScore)
    
    def get_by_id(self, db: Session, id: int) -> Optional[GameScore]:
        return db.query(GameScore).filter(GameScore.id == id).first()
    
    def get_all(
        self, 
        db: Session, 
        skip: int = 0, 
        limit: int = 100
    ) -> List[GameScore]:
        return db.query(GameScore).offset(skip).limit(limit).all()
    
    def create(self, db: Session, obj_in: dict) -> GameScore:
        db_obj = GameScore(**obj_in)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj
    
    def update(self, db: Session, db_obj: GameScore, obj_in: dict) -> GameScore:
        for field, value in obj_in.items():
            if hasattr(db_obj, field):
                setattr(db_obj, field, value)
        db.commit()
        db.refresh(db_obj)
        return db_obj
    
    def delete(self, db: Session, id: int) -> bool:
        obj = self.get_by_id(db, id)
        if obj:
            db.delete(obj)
            db.commit()
            return True
        return False
    
    def count(self, db: Session) -> int:
        return db.query(func.count(GameScore.id)).scalar()
    
    def get_by_user(
        self, 
        db: Session, 
        user_id: int,
        game_type: Optional[str] = None,
        limit: int = 10
    ) -> List[GameScore]:
        """Lấy game scores của user"""
        query = db.query(GameScore).filter(GameScore.user_id == user_id)
        if game_type:
            query = query.filter(GameScore.game_type == game_type)
        return query.order_by(desc(GameScore.created_at)).limit(limit).all()
    
    def get_leaderboard(
        self,
        db: Session,
        game_type: str,
        limit: int = 10
    ) -> List[dict]:
        """Lấy bảng xếp hạng theo game type"""
        from ..models.user import User
        
        results = db.query(
            User.username,
            func.max(GameScore.score).label("best_score"),
            func.count(GameScore.id).label("total_games")
        ).join(GameScore).filter(
            GameScore.game_type == game_type
        ).group_by(User.id, User.username).order_by(
            desc("best_score")
        ).limit(limit).all()
        
        return [
            {
                "rank": idx + 1,
                "username": r.username,
                "best_score": r.best_score,
                "total_games": r.total_games
            }
            for idx, r in enumerate(results)
        ]





class SudokuPuzzleRepository(BaseRepository[SudokuPuzzle, dict, dict]):
    """Repository cho Sudoku puzzles"""
    
    def __init__(self):
        super().__init__(SudokuPuzzle)
    
    def get_by_id(self, db: Session, id: int) -> Optional[SudokuPuzzle]:
        return db.query(SudokuPuzzle).filter(SudokuPuzzle.id == id).first()
    
    def get_all(
        self, 
        db: Session, 
        skip: int = 0, 
        limit: int = 100
    ) -> List[SudokuPuzzle]:
        return db.query(SudokuPuzzle).offset(skip).limit(limit).all()
    
    def create(self, db: Session, obj_in: dict) -> SudokuPuzzle:
        db_obj = SudokuPuzzle(**obj_in)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj
    
    def update(
        self, 
        db: Session, 
        db_obj: SudokuPuzzle, 
        obj_in: dict
    ) -> SudokuPuzzle:
        for field, value in obj_in.items():
            if hasattr(db_obj, field):
                setattr(db_obj, field, value)
        db.commit()
        db.refresh(db_obj)
        return db_obj
    
    def delete(self, db: Session, id: int) -> bool:
        obj = self.get_by_id(db, id)
        if obj:
            db.delete(obj)
            db.commit()
            return True
        return False
    
    def count(self, db: Session) -> int:
        return db.query(func.count(SudokuPuzzle.id)).scalar()
    
    def get_by_difficulty(
        self, 
        db: Session, 
        difficulty: str
    ) -> List[SudokuPuzzle]:
        """Lấy puzzles theo difficulty"""
        return db.query(SudokuPuzzle).filter(
            SudokuPuzzle.difficulty == difficulty
        ).all()


# Singleton instances
game_score_repository = GameScoreRepository()

sudoku_puzzle_repository = SudokuPuzzleRepository()
