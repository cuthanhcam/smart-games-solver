# Multi-Game Platform Backend API

Backend API được xây dựng bằng **FastAPI** theo **Clean Architecture** principles, hỗ trợ nhiều mini-games và Rubik Cube solver.

## 🎮 Tính năng

### Games
- **🎲 2048**: Trò chơi xếp số cổ điển
- **🔢 Sudoku**: Giải câu đố Sudoku với hints
- **⭕ Caro (Gomoku)**: Chơi với AI (3 độ khó)
- **🧩 Rubik Cube**: Giải Rubik với thuật toán Kociemba (tối ưu ≤20 bước)

### Core Features
- 🔐 Authentication & Authorization (JWT)
- 👤 User management với role system
- 🏆 Leaderboards cho mỗi game
- 📊 Game history tracking
- 🚀 RESTful API với auto-documentation (Swagger/OpenAPI)
- ⚡ Performance cao với FastAPI + PostgreSQL

## 🏗️ Clean Architecture

Backend được refactor hoàn toàn theo Clean Architecture với separation of concerns rõ ràng:

```
┌─────────────────────────────────────────┐
│        API/Controller Layer             │  ← HTTP Request/Response
│        (FastAPI Endpoints)              │
├─────────────────────────────────────────┤
│          Service Layer                  │  ← Business Logic
│    (AuthService, GameServices)          │
├─────────────────────────────────────────┤
│        Repository Layer                 │  ← Data Access
│   (UserRepository, GameRepositories)    │
├─────────────────────────────────────────┤
│        Models & Database                │  ← SQLAlchemy ORM
│     (Users, Games, Scores)              │
└─────────────────────────────────────────┘
```

### Benefits
✅ **Testable**: Services độc lập với HTTP và database  
✅ **Maintainable**: Mỗi layer có trách nhiệm riêng biệt  
✅ **Scalable**: Dễ dàng thêm games/features mới  
✅ **Flexible**: Có thể thay đổi database hoặc framework dễ dàng

## 📁 Project Structure

```
backend/
├── app/
│   ├── main.py                    # FastAPI app entry point
│   │
│   ├── api/                       # ⚡ Controller Layer
│   │   └── endpoints/
│   │       ├── auth.py            # Authentication endpoints
│   │       ├── rubik.py           # Rubik solver endpoints
│   │       ├── game_2048.py       # 2048 game endpoints
│   │       ├── sudoku.py          # Sudoku endpoints
│   │       └── caro.py            # Caro endpoints
│   │
│   ├── services/                  # 🧠 Business Logic Layer
│   │   ├── auth_service.py        # Auth logic, password hashing
│   │   ├── rubik_service.py       # Kociemba algorithm wrapper
│   │   ├── game_2048_service.py   # 2048 game logic
│   │   ├── sudoku_service.py      # Sudoku validation & hints
│   │   └── caro_service.py        # Caro game + AI
│   │
│   ├── repositories/              # 💾 Data Access Layer
│   │   ├── base.py                # BaseRepository interface
│   │   ├── user_repository.py     # User CRUD operations
│   │   └── game_repository.py     # Game-specific queries
│   │
│   ├── models/                    # 📊 Data Models
│   │   ├── user.py                # SQLAlchemy User model
│   │   ├── game.py                # Game models (2048, Sudoku, etc.)
│   │   └── schemas.py             # Pydantic schemas (validation)
│   │
│   ├── core/                      # 🔧 Core Utilities
│   │   ├── config.py              # Configuration management
│   │   ├── database.py            # PostgreSQL connection
│   │   ├── security.py            # JWT, password hashing
│   │   ├── exceptions.py          # Custom exceptions
│   │   ├── exception_handlers.py  # Global exception handling
│   │   └── dependencies.py        # FastAPI dependencies
│   │
│   └── utils/                     # 🛠️ Helper utilities
│
├── database/
│   └── init.sql                   # Database schema & seed data
│
├── Dockerfile                     # Multi-stage production build
├── requirements.txt               # Python dependencies
├── .env.example                   # Environment template
└── README.md                      # This file
```

## 🔄 Data Flow

### Request Flow (Inbound)
```
HTTP Request → Endpoint (Validation) → Dependencies (Auth, DB) 
→ Service (Business Logic) → Repository (Database Query) → PostgreSQL
```

### Response Flow (Outbound)
```
PostgreSQL → Repository (Model Mapping) → Service (Transform) 
→ Endpoint (Schema Serialization) → HTTP Response (JSON)
```

## 🚀 Quick Start

### Local Development

**Requirements**: Python 3.12+, PostgreSQL 15+

```bash
cd backend

# Create virtual environment
python -m venv venv

# Activate
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env
# Edit .env and update DATABASE_URL with your PostgreSQL credentials

# Run server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Or use PowerShell script (Windows):
.\run_local.ps1
```

**Access API:**
- Swagger UI: http://localhost:8000/docs
- Health Check: http://localhost:8000/health
- API Base: http://localhost:8000/api

## ⚙️ Configuration

Copy `.env.example` to `.env` and customize:

```env
# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/smart_game_db

# Security
SECRET_KEY=your-super-secret-key-min-32-chars-change-this
DEBUG=True

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173

# Server
HOST=0.0.0.0
PORT=8000

# Rate Limiting
RATE_LIMIT_PER_MINUTE=100
```

## 📡 API Endpoints

### Authentication
```
POST   /api/auth/register          # Register new user
POST   /api/auth/login             # Login (returns JWT token)
POST   /api/auth/logout            # Logout
GET    /api/auth/me                # Get current user info
```

### Rubik Cube
```
POST   /api/rubik/solve            # Solve Rubik cube (Kociemba)
GET    /api/rubik/history          # User's solution history
GET    /api/rubik/leaderboard      # Top solutions (fewest moves)
```

### 2048 Game
```
GET    /api/games/2048/new         # Start new game
POST   /api/games/2048/move        # Make move (left/right/up/down)
GET    /api/games/2048/history     # User's game history
GET    /api/games/2048/leaderboard # Top scores
```

### Sudoku
```
GET    /api/games/sudoku/new       # Get puzzle (easy/medium/hard)
POST   /api/games/sudoku/move      # Place number
POST   /api/games/sudoku/hint      # Get hint
POST   /api/games/sudoku/validate  # Check solution
GET    /api/games/sudoku/leaderboard
```

### Caro (Gomoku)
```
POST   /api/games/caro/new         # Start new game
POST   /api/games/caro/move        # Player move
POST   /api/games/caro/ai-move     # Get AI move
GET    /api/games/caro/history
```

### System
```
GET    /health                     # Health check
GET    /docs                       # Swagger UI
GET    /redoc                      # ReDoc
```

## 📦 Layer Details

### 1. API/Controller Layer (`api/endpoints/`)
**Responsibility**: Handle HTTP requests and responses

- ✅ Validate request data (Pydantic)
- ✅ Call service methods
- ✅ Format responses
- ❌ NO business logic
- ❌ NO direct database access

**Example**:
```python
@router.post("/solve", response_model=RubikSolveResponse)
async def solve_rubik(
    request: RubikSolveRequest,
    current_user: Optional[User] = Depends(get_optional_user),
    db: Session = Depends(get_db)
):
    service = RubikService(db)
    result = service.solve_cube(request.cube_state, current_user.id if current_user else None)
    return RubikSolveResponse(**result)
```

### 2. Service Layer (`services/`)
**Responsibility**: Implement business logic

- ✅ Validate business rules
- ✅ Coordinate repositories
- ✅ Transform data
- ❌ NO HTTP knowledge
- ❌ NO SQLAlchemy queries

**Example**:
```python
class RubikService:
    def solve_cube(self, cube_state: str, user_id: Optional[int]) -> Dict:
        # Validate (54 chars, correct colors)
        self._validate_cube_state(cube_state)
        
        # Solve using Kociemba
        solution = kociemba.solve(cube_state)
        steps = self._parse_solution(solution)
        
        # Save if user logged in
        if user_id:
            self.repository.create_solution({
                "user_id": user_id,
                "cube_state": cube_state,
                "solution": solution,
                "move_count": len(steps)
            })
        
        return {"solution": solution, "steps": steps}
```

### 3. Repository Layer (`repositories/`)
**Responsibility**: Data access and persistence

- ✅ CRUD operations
- ✅ Complex queries
- ✅ Data mapping
- ❌ NO business logic

**Example**:
```python
class RubikSolutionRepository(BaseRepository):
    def get_leaderboard(self, limit: int = 10):
        return self.db.query(RubikSolution)\
            .join(User)\
            .order_by(RubikSolution.move_count.asc())\
            .limit(limit)\
            .all()
```

### 4. Models (`models/`)

**SQLAlchemy Models**: Database tables
```python
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    username = Column(String, unique=True)
    email = Column(String, unique=True)
    # ...
```

**Pydantic Schemas**: Request/Response validation
```python
class RubikSolveRequest(BaseModel):
    cube_state: str = Field(..., min_length=54, max_length=54)
    
class RubikSolveResponse(BaseModel):
    solution: str
    steps: List[str]
    move_count: int
```

### 5. Core (`core/`)

**Dependencies**: FastAPI dependency injection
```python
# Database session
db: Session = Depends(get_db)

# Authentication (required)
current_user: User = Depends(get_current_user)

# Authentication (optional - allows guests)
current_user: Optional[User] = Depends(get_optional_user)

# Admin only
admin_user: User = Depends(get_current_admin_user)

# Rate limiting
_: None = Depends(RateLimiter(max_requests=100, window_seconds=60))
```

**Security**:
- JWT tokens (HS256)
- Password hashing (SHA-256 + salt)
- Auto-unban expired bans
- Role-based access control

**Exceptions**:
```python
# Custom exceptions
raise UserNotFoundException(user_id)
raise InvalidCredentialsException()
raise GameNotFoundException(game_id)

# Auto-mapped to HTTP status codes
400 Bad Request
401 Unauthorized
403 Forbidden
404 Not Found
500 Internal Server Error
```

## 🎮 Game Services

### AuthService
- User registration with validation
- Login with JWT tokens
- Password hashing (SHA-256 + salt)
- Ban/unban system with auto-expiry
- Activity logging

### RubikService
- Validate cube state (54 chars, 9 of each color)
- Solve using Kociemba algorithm (≤20 moves)
- Track solution history
- Leaderboard (fewest moves)

### Game2048Service
- Initialize 4x4 grid with 2 random tiles
- Move logic (left, right, up, down)
- Tile merging (2+2=4, 4+4=8, ...)
- Win detection (2048 tile)
- Lose detection (no valid moves)
- Score calculation

### SudokuService
- Puzzle retrieval by difficulty
- Move validation (row/column/box rules)
- Hint system (progressive reveals)
- Solution checking
- Score with time penalties

### CaroService
- Customizable board size
- Move validation
- Win detection (5 in a row - horizontal/vertical/diagonal)
- AI opponent:
  - **Easy**: Random moves
  - **Medium**: Block player wins
  - **Hard**: Minimax algorithm

## 🧪 Testing

```bash
# Install test dependencies
pip install pytest pytest-asyncio pytest-cov

# Run all tests
pytest

# With coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/test_auth_service.py

# With verbose output
pytest -v
```

## 🔐 Authentication Flow

```
1. User registers → POST /api/auth/register
   - Validate email/username/password
   - Hash password (SHA-256 + salt)
   - Save to database

2. User logs in → POST /api/auth/login
   - Verify credentials
   - Generate JWT token (expires in 7 days)
   - Return token

3. Client includes token in requests
   - Header: Authorization: Bearer <token>

4. get_current_user dependency validates token
   - Decode JWT
   - Fetch user from database
   - Check if banned (auto-unban if expired)
   - Return User object

5. Endpoint accesses current_user
   - Use user.id for database queries
   - Check user.role for authorization
```

## 🚀 Development Guidelines

### Adding a New Game

1. **Create Schema** (`models/schemas.py`)
```python
class NewGameRequest(BaseModel):
    difficulty: str
    
class NewGameResponse(BaseModel):
    game_id: int
    state: Dict
```

2. **Create Service** (`services/new_game_service.py`)
```python
class NewGameService:
    def __init__(self, db: Session):
        self.db = db
        self.repository = GameRepository(db)
    
    def create_game(self, user_id: int, difficulty: str) -> Dict:
        # Business logic here
        pass
```

3. **Create Endpoint** (`api/endpoints/new_game.py`)
```python
@router.post("/new", response_model=NewGameResponse)
async def create_game(
    request: NewGameRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = NewGameService(db)
    result = service.create_game(current_user.id, request.difficulty)
    return NewGameResponse(**result)
```

4. **Register Router** (`main.py`)
```python
from app.api.endpoints import new_game
app.include_router(new_game.router, prefix="/api/games/newgame", tags=["newgame"])
```

## 📊 Database Schema

```sql
-- Users
users (
    id SERIAL PRIMARY KEY,
    username VARCHAR UNIQUE,
    email VARCHAR UNIQUE,
    password_hash VARCHAR,
    role VARCHAR DEFAULT 'user',
    is_banned BOOLEAN DEFAULT false,
    ban_expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
)

-- Rubik Solutions
rubik_solutions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    cube_state VARCHAR(54),
    solution TEXT,
    move_count INTEGER,
    solved_at TIMESTAMP DEFAULT NOW()
)

-- 2048 Games
game_2048 (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    grid JSONB,
    score INTEGER,
    status VARCHAR, -- 'active', 'won', 'lost'
    created_at TIMESTAMP
)

-- Similar for Sudoku, Caro...
```

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| Framework | FastAPI 0.109.0 |
| Language | Python 3.12+ |
| ORM | SQLAlchemy 2.0.23 |
| Database | PostgreSQL 15 |
| Validation | Pydantic V2 |
| Authentication | JWT (HS256) |
| Password Hashing | SHA-256 + salt |
| ASGI Server | Uvicorn |
| Rubik Solver | Kociemba |
| Container | Docker + Docker Compose |

## 📈 Performance Optimizations

- ✅ Connection pooling (SQLAlchemy)
- ✅ Database indexes on foreign keys
- ✅ Async/await for I/O operations
- ✅ Efficient queries with joins
- ✅ Response caching headers
- ✅ Multi-stage Docker build (smaller images)
- ✅ Rate limiting per endpoint

## 🔒 Security Best Practices

- ✅ JWT authentication
- ✅ Password hashing (SHA-256 + salt)
- ✅ CORS configuration
- ✅ Rate limiting
- ✅ Input validation (Pydantic)
- ✅ SQL injection prevention (ORM)
- ✅ Non-root user in Docker
- ✅ Environment variable secrets
- ✅ Auto-ban system

## 📚 Documentation

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

All endpoints auto-documented with:
- Request/response schemas
- Example values
- Status codes
- Authentication requirements

## 🐛 Debugging

### Enable Debug Logs
```env
DEBUG=True
LOG_LEVEL=DEBUG
```

### View Logs
```bash
# Docker
docker-compose logs -f backend

# Local
# Logs to console with uvicorn --reload
```

### Database Shell
```bash
# Connect to PostgreSQL database
psql -U postgres -d smart_game_db

# Query users
SELECT * FROM users;

# Query games
SELECT * FROM game_scores ORDER BY score DESC LIMIT 10;
```

## 🚀 Deployment

### Production Checklist

- [ ] Change `SECRET_KEY` to strong random value (min 32 chars)
- [ ] Set `DEBUG=False`
- [ ] Configure `ALLOWED_ORIGINS` for your frontend
- [ ] Use production database credentials
- [ ] Enable HTTPS
- [ ] Set up database backups
- [ ] Configure logging to file/service
- [ ] Set up monitoring (health checks)
- [ ] Use environment variables for secrets
- [ ] Review rate limiting settings

## 🤝 Contributing

1. Follow Clean Architecture principles
2. Write tests for new features
3. Use type hints (`def func(x: int) -> str:`)
4. Add docstrings to public methods
5. Keep services focused and single-purpose
6. Never put business logic in controllers
7. Never put HTTP logic in services

## 📝 Code Style

- **Formatter**: Black
- **Linter**: Flake8
- **Type Checking**: mypy
- **Imports**: isort

```bash
# Format code
black app/

# Lint
flake8 app/

# Type check
mypy app/

# Sort imports
isort app/
```

## 🎯 Roadmap

- [x] Clean Architecture implementation
- [x] Multiple games (2048, Sudoku, Caro, Rubik)
- [x] Authentication & Authorization
- [x] Leaderboards
- [ ] WebSocket for real-time multiplayer
- [ ] Image-based Rubik detection (OpenCV + ML)
- [ ] Redis caching layer
- [ ] GraphQL API
- [ ] Admin dashboard
- [ ] Email verification
- [ ] OAuth2 (Google, Facebook)
- [ ] Comprehensive test coverage (>80%)

## 📄 License

MIT License - see LICENSE file for details

---

**Built with ❤️ using FastAPI and Clean Architecture**
