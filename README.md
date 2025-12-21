# Rubik Cube Solver

Ứng dụng hỗ trợ nhận diện và giải Rubik's Cube 3x3 bằng camera điện thoại.

## 📱 Tính năng

- **Nhận diện tự động**: Sử dụng camera để quét 6 mặt của khối Rubik
- **Giải thuật tối ưu**: Sử dụng thuật toán Kociemba (Two-Phase Algorithm) đảm bảo giải trong tối đa 20 bước
- **Hướng dẫn từng bước**: Hiển thị chi tiết các bước giải với mô tả rõ ràng
- **Giao diện thân thiện**: UI/UX đơn giản, dễ sử dụng
- **Offline-capable**: Có thể hoạt động mà không cần kết nối internet (sau khi tải về)

## 🏗️ Kiến trúc hệ thống

```
rubik-cube-solver/
├── mobile/          # Flutter app (Frontend)
│   ├── lib/
│   │   ├── core/           # Core utilities, DI, theme
│   │   └── features/       # Feature modules
│   │       ├── cube_detection/  # Nhận diện Rubik
│   │       └── cube_solver/     # Giải Rubik
│   └── assets/
│
├── backend/         # FastAPI (Backend)
│   ├── app/
│   │   ├── api/            # REST API endpoints
│   │   ├── services/       # Business logic
│   │   └── models/         # Data models
│   └── tests/
│
└── docs/            # Documentation
```

### Công nghệ sử dụng

**Frontend (Mobile App)**
- Flutter 3.x
- Dart 3.x
- BLoC pattern (state management)
- Camera plugin
- Dio (HTTP client)

**Backend (API Server)**
- Python 3.10+
- FastAPI
- OpenCV (image processing)
- Kociemba (Rubik solver)
- Uvicorn (ASGI server)

## 🚀 Hướng dẫn cài đặt

### Yêu cầu hệ thống

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Python 3.10 hoặc cao hơn
- Android Studio / Xcode (để chạy mobile app)
- Git

### 1. Clone repository

```bash
git clone https://github.com/yourusername/rubik-cube-solver.git
cd rubik-cube-solver
```

### 2. Setup Backend

```bash
cd backend

# Tạo virtual environment
python -m venv venv

# Kích hoạt virtual environment
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Cài đặt dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env

# Chạy server
python -m app.main
```

Backend sẽ chạy tại: `http://localhost:8000`
API Docs: `http://localhost:8000/docs`

### 3. Setup Mobile App

```bash
cd mobile

# Cài đặt dependencies
flutter pub get

# Chạy code generation (nếu cần)
flutter pub run build_runner build --delete-conflicting-outputs

# Chạy app
flutter run
```

**Lưu ý**: Cập nhật URL backend trong [mobile/lib/core/constants/api_constants.dart](mobile/lib/core/constants/api_constants.dart):

```dart
static const String baseUrl = 'http://YOUR_IP:8000/api';
```

Nếu test trên emulator:
- Android emulator: `http://10.0.2.2:8000/api`
- iOS simulator: `http://localhost:8000/api`
- Real device: `http://YOUR_COMPUTER_IP:8000/api`

## 📖 Hướng dẫn sử dụng

1. **Khởi động app**: Mở ứng dụng Rubik Cube Solver
2. **Chọn "Start Scanning"**: Bắt đầu quét khối Rubik
3. **Quét 6 mặt**: Di chuyển camera theo hướng dẫn để quét 6 mặt
   - Front (Mặt trước)
   - Right (Mặt phải)
   - Back (Mặt sau)
   - Left (Mặt trái)
   - Top (Mặt trên)
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
