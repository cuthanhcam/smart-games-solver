"""
Leaderboard Repository for managing game scores and leaderboards
"""
from sqlalchemy import func, desc, and_, Integer
from sqlalchemy.orm import Session
from typing import List, Optional, Tuple
from ..models.game import GameScore
from ..models.user import User
from datetime import datetime


class LeaderboardRepository:
    """Repository for handling leaderboard operations"""

    def __init__(self, db: Session):
        self.db = db

    def save_game_score(
        self,
        user_id: int,
        game_type: str,
        score: int,
        moves: int = 0,
        time_seconds: int = 0,
        completed: bool = False,
        game_data: Optional[dict] = None
    ) -> GameScore:
        """Save a new game score"""
        game_score = GameScore(
            user_id=user_id,
            game_type=game_type,
            score=score,
            moves=moves,
            time_seconds=time_seconds,
            completed=completed,
            game_data=game_data
        )
        self.db.add(game_score)
        self.db.commit()
        self.db.refresh(game_score)
        return game_score

    def get_leaderboard(
        self,
        game_type: str,
        limit: int = 100,
        offset: int = 0,
        completed_only: bool = True
    ) -> Tuple[List[dict], int]:
        """
        Get leaderboard for a specific game type
        Returns list of entries and total count
        """
        # Base query with user information
        query = self.db.query(
            GameScore.id,
            GameScore.user_id,
            User.username,
            GameScore.score,
            GameScore.moves,
            GameScore.time_seconds,
            GameScore.completed,
            GameScore.created_at,
            GameScore.game_data
        ).join(User, GameScore.user_id == User.id).filter(
            GameScore.game_type == game_type
        )

        # Filter only completed games if required
        if completed_only:
            query = query.filter(GameScore.completed == True)

        # Get total count
        total_count = query.count()

        # Get top scores by user (best score per user)
        # Subquery to get best score per user
        subquery = self.db.query(
            GameScore.user_id,
            func.max(GameScore.score).label('max_score')
        ).filter(GameScore.game_type == game_type)
        
        if completed_only:
            subquery = subquery.filter(GameScore.completed == True)
        
        subquery = subquery.group_by(GameScore.user_id).subquery()

        # Get full records for best scores
        leaderboard_query = self.db.query(
            GameScore.id,
            GameScore.user_id,
            User.username,
            GameScore.score,
            GameScore.moves,
            GameScore.time_seconds,
            GameScore.completed,
            GameScore.created_at,
            GameScore.game_data
        ).join(User, GameScore.user_id == User.id).join(
            subquery,
            and_(
                GameScore.user_id == subquery.c.user_id,
                GameScore.score == subquery.c.max_score
            )
        ).filter(
            GameScore.game_type == game_type
        ).order_by(desc(GameScore.score), GameScore.created_at).limit(limit).offset(offset)

        results = leaderboard_query.all()

        # Convert to list of dicts with rank
        entries = []
        for idx, result in enumerate(results):
            entries.append({
                'rank': offset + idx + 1,
                'id': result.id,
                'user_id': result.user_id,
                'username': result.username,
                'score': result.score,
                'moves': result.moves,
                'time_seconds': result.time_seconds,
                'completed': result.completed,
                'created_at': result.created_at,
                'game_data': result.game_data
            })

        return entries, total_count

    def get_user_best_score(self, user_id: int, game_type: str) -> Optional[dict]:
        """Get user's best score for a specific game type"""
        result = self.db.query(
            GameScore.id,
            GameScore.user_id,
            User.username,
            GameScore.score,
            GameScore.moves,
            GameScore.time_seconds,
            GameScore.completed,
            GameScore.created_at,
            GameScore.game_data
        ).join(User, GameScore.user_id == User.id).filter(
            GameScore.user_id == user_id,
            GameScore.game_type == game_type
        ).order_by(desc(GameScore.score)).first()

        if not result:
            return None

        return {
            'id': result.id,
            'user_id': result.user_id,
            'username': result.username,
            'score': result.score,
            'moves': result.moves,
            'time_seconds': result.time_seconds,
            'completed': result.completed,
            'created_at': result.created_at,
            'game_data': result.game_data
        }

    def get_user_rank(self, user_id: int, game_type: str) -> Optional[int]:
        """Get user's rank in leaderboard for a specific game type"""
        # Get user's best score
        user_best = self.db.query(
            func.max(GameScore.score)
        ).filter(
            GameScore.user_id == user_id,
            GameScore.game_type == game_type,
            GameScore.completed == True
        ).scalar()

        if user_best is None:
            return None

        # Count users with better scores
        better_count = self.db.query(
            func.count(func.distinct(GameScore.user_id))
        ).filter(
            GameScore.game_type == game_type,
            GameScore.completed == True,
            GameScore.score > user_best
        ).scalar()

        return better_count + 1

    def get_user_game_history(
        self,
        user_id: int,
        game_type: Optional[str] = None,
        limit: int = 50,
        offset: int = 0
    ) -> Tuple[List[GameScore], int]:
        """Get user's game history"""
        query = self.db.query(GameScore).filter(GameScore.user_id == user_id)

        if game_type:
            query = query.filter(GameScore.game_type == game_type)

        total_count = query.count()
        results = query.order_by(desc(GameScore.created_at)).limit(limit).offset(offset).all()

        return results, total_count

    def get_game_statistics(self, game_type: str) -> dict:
        """Get overall statistics for a game type"""
        stats = self.db.query(
            func.count(GameScore.id).label('total_games'),
            func.count(func.distinct(GameScore.user_id)).label('unique_players'),
            func.max(GameScore.score).label('highest_score'),
            func.avg(GameScore.score).label('average_score'),
            func.sum(func.cast(GameScore.completed, Integer)).label('completed_games')
        ).filter(GameScore.game_type == game_type).first()

        return {
            'game_type': game_type,
            'total_games': stats.total_games or 0,
            'unique_players': stats.unique_players or 0,
            'highest_score': stats.highest_score or 0,
            'average_score': float(stats.average_score) if stats.average_score else 0.0,
            'completed_games': stats.completed_games or 0
        }
