# 🎮 Ứng dụng Hỗ trợ Giải các Trò chơi Trí tuệ trên Thiết bị Di động

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109-009688?logo=fastapi)](https://fastapi.tiangolo.com/)
[![Python](https://img.shields.io/badge/Python-3.11%2B-3776AB?logo=python)](https://www.python.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-336791?logo=postgresql)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

*Một nền tảng giải trí và rèn luyện trí tuệ toàn diện với 4 trò chơi kinh điển, hệ thống AI thông minh, và tính năng xã hội phong phú*

[Tính năng](#-tính-năng-chính) • [Cài đặt](#-cài-đặt-nhanh) • [Kiến trúc](#️-kiến-trúc-hệ-thống) • [API](#-api-endpoints) • [Đóng góp](#-đóng-góp)

</div>

---

## 📖 Giới thiệu

**Smart Games Solver** là ứng dụng mobile toàn diện được xây dựng bằng Flutter và FastAPI, cung cấp trải nghiệm chơi game trí tuệ với các thuật toán thông minh và hệ thống xã hội tương tác. Dự án được thiết kế theo **Clean Architecture**, đảm bảo tính mở rộng và bảo trì dễ dàng.

### 🎯 Mục tiêu

- ✅ Cung cấp trải nghiệm chơi game mượt mà và thú vị
- ✅ Tích hợp AI và thuật toán tối ưu để hỗ trợ người chơi
- ✅ Xây dựng cộng đồng người chơi với tính năng xã hội
- ✅ Theo dõi tiến trình và thống kê chi tiết
- ✅ Kiến trúc sạch, dễ bảo trì và mở rộng

---

## 🎮 Tính năng chính

### 🎲 Bốn trò chơi kinh điển

<table>
<tr>
<td width="25%">

#### 🔢 2048
- Trò chơi ghép số kinh điển
- Theo dõi điểm cao
- Hoàn tác và gợi ý nước đi
- Bảng xếp hạng toàn cầu

</td>
<td width="25%">

#### 🧩 Sudoku
- 4 độ khó: Easy, Medium, Hard, Expert
- Hệ thống gợi ý thông minh
- Validation theo thời gian thực
- Ghi chú và đánh dấu ô
- Theo dõi thời gian hoàn thành

</td>
<td width="25%">

#### ⭕ Caro (Gomoku)
- **PvE Mode**: Đấu với AI (4 độ khó)
- **EvE Mode**: Xem AI đấu với AI
- Thuật toán Minimax với Alpha-Beta Pruning
- Hệ thống đánh giá heuristic
- Lịch sử nước đi và phân tích

</td>
<td width="25%">

#### 🧊 Rubik Cube Solver
- Giải Rubik 3x3 tối ưu
- Thuật toán Kociemba (≤20 bước)
- Nhập liệu thủ công hoặc scan camera
- Hướng dẫn từng bước
- Visualization 3D

</td>
</tr>
</table>

### 🌟 Tính năng nổi bật

#### 🔐 Xác thực & Bảo mật
- Đăng ký/Đăng nhập với JWT Authentication
- Mã hóa mật khẩu với Bcrypt
- Quản lý phiên đăng nhập an toàn
- Hệ thống phân quyền (User/Admin)

#### 🏆 Hệ thống Leaderboard
- Bảng xếp hạng cho từng game
- Lọc theo độ khó (Sudoku: Easy/Medium/Hard/Expert, Caro: Easy/Medium/Hard/Expert)
- Xếp hạng theo thời gian (Sudoku, Caro) hoặc điểm số (2048)
- Cập nhật thời gian thực

#### 👥 Tính năng Xã hội
- **Hệ thống bạn bè**: Gửi/nhận lời mời kết bạn
- **Chat realtime**: Nhắn tin 1-1 với bạn bè
- **Thông báo**: Nhận thông báo về hoạt động, tin nhắn mới
- **Thông báo hệ thống**: Admin gửi announcement cho tất cả users

#### 📊 Thống kê & Lịch sử
- Theo dõi tiến trình cá nhân
- Lịch sử các ván chơi
- Thống kê chi tiết theo từng game
- Biểu đồ hiệu suất

#### 👨‍💼 Admin Panel
- Quản lý users (tạo, xóa, cập nhật quyền)
- Hệ thống ban/unban user (1 phút, 5 phút, vĩnh viễn)
- Gửi thông báo cho toàn hệ thống
- Theo dõi hoạt động người dùng
- Dashboard thống kê tổng quan

---

## 🏗️ Kiến trúc hệ thống

### 📐 Tổng quan Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        MOBILE APP (Flutter)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Features   │  │     Core     │  │    Shared    │          │
│  │  - Auth      │  │  - Config    │  │  - Widgets   │          │
│  │  - Games     │  │  - DI        │  │  - Services  │          │
│  │  - Social    │  │  - Theme     │  │  - Models    │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTP/WebSocket
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BACKEND API (FastAPI)                         │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │           API Layer (Controllers/Endpoints)              │   │
│  │    /auth  /games  /social  /admin  /leaderboard         │   │
│  └──────────────────┬───────────────────────────────────────┘   │
│                     │                                            │
│  ┌──────────────────▼───────────────────────────────────────┐   │
│  │              Service Layer (Business Logic)              │   │
│  │  AuthService  GameServices  SocialService  AdminService  │   │
│  └──────────────────┬───────────────────────────────────────┘   │
│                     │                                            │
│  ┌──────────────────▼───────────────────────────────────────┐   │
│  │          Repository Layer (Data Access)                  │   │
│  │   UserRepo  GameRepo  LeaderboardRepo  FriendRepo       │   │
│  └──────────────────┬───────────────────────────────────────┘   │
└────────────────────┬┘                                            │
                     │ SQLAlchemy ORM                              │
                     ▼                                             │
┌─────────────────────────────────────────────────────────────────┐
│                    PostgreSQL Database                           │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐           │
│  │  Users  │  │  Games  │  │ Friends │  │ Messages│           │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

### 🎯 Clean Architecture Benefits

| Lợi ích | Mô tả |
|---------|-------|
| **🧪 Testable** | Các service độc lập với HTTP và database, dễ dàng unit test |
| **🔧 Maintainable** | Mỗi layer có trách nhiệm rõ ràng, dễ bảo trì |
| **📈 Scalable** | Thêm game hoặc feature mới không ảnh hưởng code cũ |
| **🔄 Flexible** | Thay đổi database hoặc framework với impact tối thiểu |
| **👥 Team-friendly** | Nhiều dev có thể làm việc song song trên các layer khác nhau |

### 📁 Cấu trúc thư mục

```
smart-games-solver/
├── 📱 mobile/                    # Flutter Application
│   ├── lib/
│   │   ├── core/                 # Core configuration & DI
│   │   │   ├── config/           # App configuration
│   │   │   ├── di/               # Dependency injection
│   │   │   └── theme/            # App theme & styling
│   │   │
│   │   ├── features/             # Feature-based modules
│   │   │   ├── auth/             # Authentication
│   │   │   │   ├── screens/      # Login, Register screens
│   │   │   │   └── repositories/ # Auth API calls
│   │   │   │
│   │   │   ├── games/            # Games module
│   │   │   │   ├── game_2048/    # 2048 game
│   │   │   │   ├── sudoku/       # Sudoku game
│   │   │   │   ├── caro/         # Caro game
│   │   │   │   └── rubik/        # Rubik solver
│   │   │   │
│   │   │   ├── social/           # Social features
│   │   │   │   ├── screens/      # Friends, Chat screens
│   │   │   │   └── repositories/ # Social API
│   │   │   │
│   │   │   ├── leaderboard/      # Leaderboard system
│   │   │   ├── admin/            # Admin panel
│   │   │   ├── profile/          # User profile & stats
│   │   │   ├── announcement/     # Notifications
│   │   │   └── home/             # Home screen
│   │   │
│   │   └── shared/               # Shared components
│   │       ├── widgets/          # Reusable widgets
│   │       ├── services/         # API client, storage
│   │       └── models/           # Data models
│   │
│   └── assets/                   # Images, fonts, etc.
│
├── 🐍 backend/                   # FastAPI Backend
│   ├── app/
│   │   ├── api/                  # 🌐 Controller Layer
│   │   │   └── endpoints/
│   │   │       ├── auth.py       # Authentication endpoints
│   │   │       ├── game_2048.py  # 2048 API
│   │   │       ├── sudoku.py     # Sudoku API
│   │   │       ├── caro.py       # Caro API
│   │   │       ├── rubik.py      # Rubik solver API
│   │   │       ├── leaderboard.py # Leaderboard API
│   │   │       ├── social.py     # Social features API
│   │   │       └── admin.py      # Admin API
│   │   │
│   │   ├── services/             # 🧠 Business Logic Layer
│   │   │   ├── auth_service.py   # JWT, password hashing
│   │   │   ├── game_2048_service.py
│   │   │   ├── sudoku_service.py # Sudoku validation & hints
│   │   │   ├── caro_service.py   # Minimax AI algorithm
│   │   │   ├── solver_service.py # Rubik Kociemba solver
│   │   │   └── detection_service.py # Image detection
│   │   │
│   │   ├── repositories/         # 💾 Data Access Layer
│   │   │   ├── base.py           # Base repository
│   │   │   ├── user_repository.py
│   │   │   ├── game_repository.py
│   │   │   └── leaderboard_repository.py
│   │   │
│   │   ├── models/               # 📊 Database Models
│   │   │   ├── user.py           # SQLAlchemy models
│   │   │   ├── game.py
│   │   │   ├── cube.py
│   │   │   ├── solution.py
│   │   │   └── schemas.py        # Pydantic schemas
│   │   │
│   │   ├── core/                 # ⚙️ Core utilities
│   │   │   ├── config.py         # Configuration
│   │   │   ├── database.py       # DB connection
│   │   │   ├── security.py       # JWT & encryption
│   │   │   ├── exceptions.py     # Custom exceptions
│   │   │   └── dependencies.py   # FastAPI dependencies
│   │   │
│   │   └── utils/                # 🛠️ Helper functions
│   │
│   ├── database/
│   │   ├── init.sql              # Database schema
│   │   └── seed_sudoku_puzzles.sql # Sample data
│   │
│   ├── requirements.txt          # Python dependencies
│   └── Dockerfile               # Container config
│
├── 🐳 docker-compose.yml         # Docker orchestration
└── 📄 README.md                  # This file
```

---

## � Công nghệ sử dụng

### Frontend (Mobile)
| Công nghệ | Version | Mục đích |
|-----------|---------|----------|
| **Flutter** | 3.0+ | Cross-platform mobile framework |
| **Dart** | 3.0+ | Programming language |
| **Provider/Bloc** | Latest | State management |
| **Dio** | Latest | HTTP client |
| **SharedPreferences** | Latest | Local storage |
| **Flutter Secure Storage** | Latest | Secure token storage |

### Backend (API Server)
| Công nghệ | Version | Mục đích |
|-----------|---------|----------|
| **Python** | 3.11+ | Programming language |
| **FastAPI** | 0.109.0 | Web framework |
| **SQLAlchemy** | 2.0 | ORM (Object-Relational Mapping) |
| **PostgreSQL** | 15 | Relational database |
| **Pydantic** | Latest | Data validation |
| **JWT** | Latest | Authentication |
| **Bcrypt** | Latest | Password hashing |
| **Kociemba** | Latest | Rubik's Cube solver |
| **OpenCV** | Latest | Image processing |

### DevOps & Tools
- **Docker** & **Docker Compose**: Containerization
- **Git**: Version control
- **VS Code**: IDE
- **Postman**: API testing

---

## 🚀 Cài đặt nhanh

### Yêu cầu hệ thống

**Mobile App:**
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / Xcode
- Android device/emulator or iOS device/simulator

**Backend:**
- Python 3.11+
- PostgreSQL 15+
- Docker & Docker Compose (khuyến nghị)

### Option 1: Docker Compose (Khuyến nghị) ⭐

Cách nhanh nhất để chạy backend và database:

```bash
# Clone repository
git clone https://github.com/cuthanhcam/smart-games-solver.git
cd smart-games-solver

# Khởi động tất cả services (Database + Backend)
docker-compose up -d

# Kiểm tra trạng thái
docker-compose ps

# Xem logs
docker-compose logs -f backend

# Truy cập services
# - API Server: http://localhost:8000
# - API Docs: http://localhost:8000/docs
# - Health Check: http://localhost:8000/health

# Dừng services
docker-compose down

# Xóa hoàn toàn (bao gồm volumes)
docker-compose down -v
```

### Option 2: Cài đặt thủ công

#### 1️⃣ Backend Setup

**Linux/Mac:**
```bash
cd backend

# Tạo virtual environment
python3 -m venv venv
source venv/bin/activate

# Cài dependencies
pip install -r requirements.txt

# Cấu hình database
cp .env.example .env
# Chỉnh sửa .env với thông tin PostgreSQL của bạn

# Khởi động database (nếu dùng Docker)
docker-compose up -d postgres

# Chạy server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Windows:**
```powershell
cd backend

# Tạo virtual environment
python -m venv venv
.\venv\Scripts\activate

# Cài dependencies
pip install -r requirements.txt

# Cấu hình database
copy .env.example .env
# Chỉnh sửa .env với thông tin PostgreSQL của bạn

# Chạy server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

#### 2️⃣ Database Setup

```bash
# Khởi chạy PostgreSQL (nếu chưa có)
docker-compose up -d postgres

# Truy cập database shell
docker-compose exec postgres psql -U postgres -d smart_games_db

# Hoặc restore từ backup
cat database/init.sql | docker-compose exec -T postgres psql -U postgres -d smart_games_db

# Seed dữ liệu Sudoku (optional)
cat database/seed_sudoku_puzzles.sql | docker-compose exec -T postgres psql -U postgres -d smart_games_db
```

#### 3️⃣ Mobile App Setup

```bash
cd mobile

# Cài dependencies
flutter pub get

# Kiểm tra devices
flutter devices

# Chạy app trên emulator/device
flutter run

# Build cho production
# Android
flutter build apk --release
# iOS
flutter build ios --release
```

### ⚙️ Cấu hình

**Backend (.env file):**
```env
# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/smart_games_db

# Security
SECRET_KEY=your-super-secret-key-change-this-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Environment
DEBUG=True
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8000

# Server
HOST=0.0.0.0
PORT=8000
```

**Mobile (lib/core/config/api_config.dart):**
```dart
class ApiConfig {
  // Development
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android Emulator
  // static const String baseUrl = 'http://localhost:8000'; // iOS Simulator
  // static const String baseUrl = 'http://YOUR_IP:8000'; // Physical device
  
  // Production
  // static const String baseUrl = 'https://api.yourdomain.com';
}
```

---

## 📡 API Endpoints

### 🔐 Authentication
```http
POST   /api/auth/register              # Đăng ký tài khoản mới
POST   /api/auth/login                 # Đăng nhập
POST   /api/auth/logout                # Đăng xuất
GET    /api/auth/me                    # Lấy thông tin user hiện tại
PUT    /api/auth/profile               # Cập nhật profile
```

### 🎲 Game 2048
```http
GET    /api/games/2048/new             # Tạo game mới
POST   /api/games/2048/move            # Thực hiện nước đi
POST   /api/games/2048/save            # Lưu trạng thái game
GET    /api/games/2048/leaderboard     # Bảng xếp hạng 2048
```

### 🧩 Sudoku
```http
GET    /api/games/sudoku/new           # Lấy puzzle mới (theo difficulty)
POST   /api/games/sudoku/validate      # Validate nước đi
POST   /api/games/sudoku/hint          # Lấy gợi ý
POST   /api/games/sudoku/complete      # Hoàn thành game
GET    /api/games/sudoku/leaderboard   # Bảng xếp hạng Sudoku
```

### ⭕ Caro (Gomoku)
```http
POST   /api/games/caro/new             # Tạo game mới (PvE/EvE)
POST   /api/games/caro/move            # Người chơi đi
POST   /api/games/caro/ai-move         # AI tính nước đi
POST   /api/games/caro/complete        # Kết thúc game
GET    /api/games/caro/leaderboard     # Bảng xếp hạng Caro
```

### 🧊 Rubik Cube
```http
POST   /api/rubik/detect               # Nhận diện mặt Rubik từ ảnh
POST   /api/rubik/validate             # Validate cấu hình Rubik
POST   /api/rubik/solve                # Giải Rubik (Kociemba)
GET    /api/rubik/history              # Lịch sử giải của user
GET    /api/rubik/leaderboard          # Bảng xếp hạng Rubik
```

### 🏆 Leaderboard
```http
GET    /api/leaderboard                # Leaderboard tổng hợp
GET    /api/leaderboard/{game_type}    # Leaderboard theo game
  # game_type: 2048, sudoku, caro
  # Query params: difficulty, limit, offset
```

### 👥 Social Features
```http
# Friends
GET    /api/social/friends             # Danh sách bạn bè
POST   /api/social/friends/request     # Gửi lời mời kết bạn
POST   /api/social/friends/accept      # Chấp nhận lời mời
POST   /api/social/friends/reject      # Từ chối lời mời
DELETE /api/social/friends/{user_id}   # Hủy kết bạn
GET    /api/social/users/search        # Tìm kiếm user

# Messages
GET    /api/social/messages            # Danh sách tin nhắn
GET    /api/social/messages/{user_id}  # Tin nhắn với 1 user
POST   /api/social/messages            # Gửi tin nhắn
DELETE /api/social/messages/{msg_id}   # Xóa tin nhắn

# Notifications
GET    /api/social/notifications       # Danh sách thông báo
PUT    /api/social/notifications/{id}/read  # Đánh dấu đã đọc
DELETE /api/social/notifications/{id}  # Xóa thông báo
```

### 👨‍💼 Admin APIs
```http
GET    /api/admin/users                # Danh sách tất cả users
PUT    /api/admin/users/{id}/admin     # Cấp/thu hồi quyền admin
POST   /api/admin/users/{id}/ban       # Ban user
POST   /api/admin/users/{id}/unban     # Unban user
DELETE /api/admin/users/{id}           # Xóa user
POST   /api/admin/announcements        # Gửi thông báo hệ thống
GET    /api/admin/statistics           # Thống kê tổng quan
```

### 🔍 Utility
```http
GET    /health                         # Health check
GET    /docs                           # Swagger UI documentation
GET    /redoc                          # ReDoc documentation
```

**📖 Chi tiết đầy đủ:** Truy cập `http://localhost:8000/docs` khi chạy server để xem API documentation tương tác.

---

## 🎯 Thuật toán Game

### 🧩 Sudoku
- **Validation**: Kiểm tra constraint theo hàng/cột/ô 3x3
- **Hint System**: Truy xuất solution từ database hoặc generate local
- **Generator**: Backtracking algorithm tạo puzzle với unique solution
- **Difficulty**: Điều chỉnh số ô trống (Easy: 40, Medium: 50, Hard: 55, Expert: 60+)

### ⭕ Caro AI
- **Algorithm**: Minimax với Alpha-Beta Pruning
- **Heuristic Evaluation**:
  - Đánh giá pattern: 5 liên tiếp, 4 liên tiếp, 3 liên tiếp
  - Phát hiện threat (defensive moves)
  - Tính điểm tấn công và phòng thủ
- **Difficulty Levels**:
  - **Easy**: Depth 1, random factor cao
  - **Medium**: Depth 2, balanced heuristic
  - **Hard**: Depth 3, optimal strategy
  - **Expert**: Depth 4, perfect play
- **Optimization**: Transposition table, move ordering

### 🧊 Rubik Cube
- **Detection**: OpenCV color detection từ ảnh camera
- **Validation**: Kiểm tra cấu hình hợp lệ (9 stickers mỗi màu)
- **Solver**: Kociemba's Two-Phase Algorithm
  - Phase 1: Đưa về sub-group G1 (≤12 moves)
  - Phase 2: Giải trong G1 (≤18 moves)
  - Total: ≤20 moves (God's Number: 20)
- **Output**: Notation string (U, R, F, B, L, D, U', R', ...)

### 🎲 2048
- **Game Logic**: Merge cells theo 4 hướng (Up, Down, Left, Right)
- **Score**: Tổng các số merge được
- **Win Condition**: Đạt tile 2048 (có thể chơi tiếp)
- **Algorithm**: Matrix manipulation với sliding và merging

---

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

## 🙏 Acknowledgments

- [Kociemba Algorithm](http://kociemba.org/cube.htm) - Thuật toán giải Rubik hiệu quả
- Flutter & FastAPI communities
- OpenCV for computer vision capabilities

## 📧 Liên hệ

- Email: cuthanhcam04@gmail.com
- GitHub: [@cuthanhcam](https://github.com/cuthanhcam)
