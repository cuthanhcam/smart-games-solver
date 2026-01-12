# Multi-Game Platform

Ứng dụng game đa chức năng với 4 trò chơi: 2048, Sudoku, Caro (Gomoku), và Rubik Cube Solver.

## 🎮 Tính năng

### Games
- **2048**: Classic number sliding puzzle game
- **Sudoku**: Logic-based number puzzle (Easy/Medium/Hard)
- **Caro (Gomoku)**: Five in a Row strategy game với AI
- **Rubik Cube Solver**: Giải Rubik's Cube 3x3 bằng thuật toán Kociemba

### Features
- **Authentication**: Đăng ký, đăng nhập với JWT tokens
- **Leaderboards**: Bảng xếp hạng cho từng game
- **Statistics**: Theo dõi thống kê cá nhân
- **Game History**: Lưu lịch sử chơi game
- **Admin Panel**: Quản lý users, ban/unban system
- **Clean Architecture**: Backend được thiết kế theo nguyên tắc Clean Architecture

## 🏗️ Kiến trúc hệ thống

```
rubik-cube-solver/
├── mobile/          # Flutter app (Frontend)
│   ├── lib/
│   │   ├── core/           # Core utilities, DI, theme
│   │   └── features/       # Feature modules
│   │       ├── auth/           # Authentication
│   │       ├── game_2048/      # 2048 game
│   │       ├── sudoku/         # Sudoku game
│   │       ├── caro/           # Caro game
│   │       └── rubik/          # Rubik solver
│   └── assets/
│
├── backend/         # FastAPI (Backend) - Clean Architecture
│   ├── app/
│   │   ├── api/            # Controllers (HTTP endpoints)
│   │   ├── services/       # Business logic layer
│   │   ├── repositories/   # Data access layer
│   │   ├── models/         # Domain models
│   │   ├── core/           # Config, security, exceptions
│   │   └── utils/          # Utilities
│   ├── database/
│   │   └── init.sql        # PostgreSQL schema
│   ├── Dockerfile
│   └── requirements.txt
│
├── docker-compose.yml       # Docker orchestration
├── Makefile                 # Quick commands
└── docs/                    # Documentation
```

### Công nghệ sử dụng

**Frontend (Mobile App)**
- Flutter 3.0+
- Dart 3.0+
- BLoC pattern (state management)
- Dio (HTTP client)

**Backend (API Server)**
- Python 3.11+
- FastAPI 0.109.0
- SQLAlchemy 2.0 (ORM)
- PostgreSQL 15
- JWT Authentication
- Kociemba (Rubik solver)
- Docker & Docker Compose

## 🚀 Quick Start

### Option 1: Docker Compose (Recommended) ⭐

```bash
# Start all services (Database + Backend)
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f backend

# Access services
# - API Server: http://localhost:8000
# - API Docs: http://localhost:8000/docs
# - Health Check: http://localhost:8000/health

# Stop services
docker-compose down
```

### Option 2: Local Development

#### Backend
**Linux/Mac:**
```bash
cd backend
./start_server.sh
```

**Windows:**
```powershell
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
docker-compose up -d postgres  # Database only
uvicorn app.main:app --reload
```

#### Mobile App
```bash
cd mobile
flutter pub get
flutter run
```

### Using Makefile (Optional)

```bash
make help          # Show all commands
make docker-up     # Start with Docker
make dev           # Start local development
make docker-logs   # View logs
make test          # Run tests
```

## 📚 Documentation

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Complete deployment guide
- **[DOCKER_GUIDE.md](DOCKER_GUIDE.md)** - Docker commands reference
- **[backend/ARCHITECTURE.md](backend/ARCHITECTURE.md)** - Backend architecture
- **API Docs**: http://localhost:8000/docs (when running)

## 🔧 Configuration

Copy environment file and customize:
```bash
cp backend/.env.example backend/.env
```

Key variables to change in production:
- `SECRET_KEY`: Strong random key (min 32 chars)
- `DATABASE_URL`: PostgreSQL connection string
- `DEBUG`: Set to `False`
- `ALLOWED_ORIGINS`: Your frontend URLs

## 🎯 API Endpoints

```
Authentication:
POST   /api/auth/register       - Register new user
POST   /api/auth/login          - Login
POST   /api/auth/logout         - Logout

Games:
GET    /api/games/2048/new      - New 2048 game
POST   /api/games/2048/move     - Make move
GET    /api/games/2048/leaderboard

GET    /api/games/sudoku/new    - Get Sudoku puzzle
POST   /api/games/sudoku/move   - Make move
POST   /api/games/sudoku/hint   - Get hint

POST   /api/games/caro/new      - New Caro game
POST   /api/games/caro/move     - Make move
POST   /api/games/caro/ai-move  - Get AI move

POST   /api/rubik/solve         - Solve Rubik cube
GET    /api/rubik/history       - User's solutions
GET    /api/rubik/leaderboard   - Global leaderboard
```

## 🧪 Testing

```bash
# Backend tests
cd backend
pytest

# With Docker
docker-compose exec backend pytest

# API testing
curl http://localhost:8000/health
```

## 🛠️ Development

### Database Operations

```bash
# Backup
docker-compose exec postgres pg_dump -U postgres rubik_game_db > backup.sql

# Restore
cat backup.sql | docker-compose exec -T postgres psql -U postgres rubik_game_db

# Access database shell
docker-compose exec postgres psql -U postgres -d rubik_game_db

# Reset database
docker-compose down -v && docker-compose up -d
```

### Code Quality

```bash
# Format code
cd backend
black app/

# Lint
flake8 app/

# Type checking
mypy app/
```
   - Bottom (Mặt dưới)
4. **Xem kết quả**: Ứng dụng sẽ hiển thị các bước giải
5. **Làm theo hướng dẫn**: Thực hiện từng bước để giải Rubik

## 🐳 Deploy với Docker

```bash
# Build và run backend
cd backend
docker build -t rubik-solver-backend .
docker run -p 8000:8000 rubik-solver-backend
```

## 📚 API Documentation

### Endpoints

#### 1. Detect Cube Face
```
POST /api/detect
Content-Type: multipart/form-data

Parameters:
- image: File (image of cube face)
- face_name: String (front, back, left, right, top, bottom)

Response:
{
  "success": true,
  "face_name": "front",
  "colors": [
    ["W", "W", "W"],
    ["W", "W", "W"],
    ["W", "W", "W"]
  ],
  "confidence": 0.95
}
```

#### 2. Validate Cube
```
POST /api/validate
Content-Type: application/json

Body:
{
  "faces": [
    {
      "face_name": "front",
      "colors": [["W", "W", "W"], ...]
    },
    // ... 5 more faces
  ]
}

Response:
{
  "is_valid": true,
  "notation": "UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB"
}
```

#### 3. Solve Cube
```
POST /api/solve
Content-Type: application/json

Body:
{
  "faces": [...]
}

Response:
{
  "success": true,
  "steps": [
    {
      "move": "U",
      "notation": "U",
      "description": "Turn upper face clockwise"
    },
    ...
  ],
  "total_moves": 18,
  "algorithm": "U R U' R' F' U F",
  "execution_time": 0.125
}
```

## 🎯 Roadmap

### Phase 1: MVP (Current)
- [x] Project setup
- [ ] Basic camera detection
- [ ] Backend API integration
- [ ] Basic solving algorithm

### Phase 2: Enhancement
- [ ] Improve color detection accuracy
- [ ] Add ML model for better recognition
- [ ] 3D cube visualization
- [ ] Animation for solution steps
- [ ] Manual input option

### Phase 3: Advanced Features
- [ ] Multiple cube sizes (2x2, 4x4, 5x5)
- [ ] Different solving algorithms
- [ ] Timer and statistics
- [ ] Solution history
- [ ] Social features (share solutions)
- [ ] AR visualization

## 🤝 Đóng góp

Mọi đóng góp đều được chào đón! Vui lòng:

1. Fork repository
2. Tạo branch mới (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Tạo Pull Request

## 📝 License

MIT License - xem file [LICENSE](LICENSE) để biết thêm chi tiết.

## 👨‍💻 Tác giả

- **Tên của bạn** - *Initial work*

## 🙏 Acknowledgments

- [Kociemba Algorithm](http://kociemba.org/cube.htm) - Thuật toán giải Rubik hiệu quả
- Flutter & FastAPI communities
- OpenCV for computer vision capabilities

## 📧 Liên hệ

- Email: your.email@example.com
- GitHub: [@yourusername](https://github.com/yourusername)

---

⭐️ Nếu project này hữu ích, đừng quên star repository nhé!
