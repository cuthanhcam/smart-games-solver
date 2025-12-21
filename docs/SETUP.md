# Project Setup Guide

## Hướng dẫn setup chi tiết cho dự án Rubik Cube Solver

### 📋 Mục lục

1. [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
2. [Setup Backend](#setup-backend)
3. [Setup Mobile App](#setup-mobile-app)
4. [Troubleshooting](#troubleshooting)

---

## Yêu cầu hệ thống

### Backend
- Python 3.10 hoặc cao hơn
- pip (Python package manager)
- Virtual environment (recommended)

### Mobile App
- Flutter SDK 3.0.0+
- Dart SDK 3.0.0+
- Android Studio (cho Android development)
- Xcode (cho iOS development - chỉ trên macOS)

### Optional
- Docker & Docker Compose (cho containerization)
- Git

---

## Setup Backend

### 1. Cài đặt Python

**Windows:**
- Tải Python từ [python.org](https://www.python.org/downloads/)
- Chọn "Add Python to PATH" khi cài đặt
- Verify: `python --version`

**macOS:**
```bash
brew install python@3.10
```

**Linux:**
```bash
sudo apt update
sudo apt install python3.10 python3-pip python3-venv
```

### 2. Setup Backend Environment

```bash
# Navigate to backend folder
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
cp .env.example .env

# Edit .env if needed (optional)
# notepad .env  # Windows
# nano .env     # Linux/Mac
```

### 3. Run Backend Server

```bash
# Make sure virtual environment is activated
python -m app.main

# hoặc
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Truy cập:
- API: http://localhost:8000
- Swagger Docs: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

---

## Setup Mobile App

### 1. Cài đặt Flutter

**Windows:**
1. Tải Flutter SDK từ [flutter.dev](https://flutter.dev/docs/get-started/install)
2. Giải nén vào `C:\src\flutter`
3. Thêm `C:\src\flutter\bin` vào PATH
4. Chạy `flutter doctor`

**macOS:**
```bash
# Cài đặt với Homebrew
brew install flutter

# Hoặc tải manual từ flutter.dev
```

**Linux:**
```bash
# Tải Flutter SDK
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.x.x-stable.tar.xz
tar xf flutter_linux_3.x.x-stable.tar.xz

# Add to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Verify
flutter doctor
```

### 2. Cài đặt Android Studio

1. Tải Android Studio từ [developer.android.com](https://developer.android.com/studio)
2. Cài đặt Android SDK
3. Cài đặt Flutter plugin:
   - File > Settings > Plugins
   - Search "Flutter" và install

### 3. Setup Flutter Project

```bash
# Navigate to mobile folder
cd mobile

# Get dependencies
flutter pub get

# Run code generation (if needed)
flutter pub run build_runner build --delete-conflicting-outputs

# Check for issues
flutter doctor
```

### 4. Configure Backend URL

Mở file `mobile/lib/core/constants/api_constants.dart` và cập nhật:

```dart
static const String baseUrl = 'http://YOUR_BACKEND_URL:8000/api';
```

**Lưu ý:**
- Android Emulator: `http://10.0.2.2:8000/api`
- iOS Simulator: `http://localhost:8000/api`
- Real Device: `http://YOUR_COMPUTER_IP:8000/api` (cùng mạng WiFi)

Để tìm IP của máy tính:
```bash
# Windows
ipconfig

# macOS/Linux
ifconfig
```

### 5. Run Mobile App

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Run in debug mode
flutter run

# Run in release mode (faster)
flutter run --release
```

---

## Setup với Docker (Optional)

### 1. Cài đặt Docker

- Windows/Mac: [Docker Desktop](https://www.docker.com/products/docker-desktop)
- Linux: `sudo apt install docker.io docker-compose`

### 2. Run với Docker Compose

```bash
# Build and run
docker-compose up --build

# Run in background
docker-compose up -d

# Stop
docker-compose down

# View logs
docker-compose logs -f
```

---

## Troubleshooting

### Backend Issues

**Problem**: `ModuleNotFoundError`
```bash
# Solution: Reinstall dependencies
pip install -r requirements.txt
```

**Problem**: Port 8000 đã được sử dụng
```bash
# Solution: Đổi port trong .env hoặc kill process
# Windows:
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Linux/Mac:
lsof -i :8000
kill -9 <PID>
```

### Flutter Issues

**Problem**: `flutter: command not found`
```bash
# Solution: Add Flutter to PATH
# Verify installation
which flutter
```

**Problem**: Android licenses not accepted
```bash
flutter doctor --android-licenses
# Accept all licenses
```

**Problem**: Camera permission denied
- Android: Check `android/app/src/main/AndroidManifest.xml`
- iOS: Check `ios/Runner/Info.plist`

Đảm bảo có permission:
```xml
<!-- Android -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- iOS -->
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan Rubik's cube</string>
```

### Network Issues

**Problem**: Mobile app không kết nối được backend

1. Kiểm tra backend đang chạy: `curl http://localhost:8000/health`
2. Kiểm tra firewall
3. Đảm bảo mobile device và computer cùng mạng
4. Test với Postman trước

---

## Các lệnh hữu ích

### Backend
```bash
# Activate venv
venv\Scripts\activate  # Windows
source venv/bin/activate  # Mac/Linux

# Install new package
pip install package_name
pip freeze > requirements.txt

# Run tests
pytest tests/

# Format code
black app/
```

### Flutter
```bash
# Clean build
flutter clean
flutter pub get

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release

# Run tests
flutter test

# Format code
flutter format lib/

# Analyze code
flutter analyze
```

---

## Next Steps

1. ✅ Setup xong backend và mobile
2. 📖 Đọc README.md để hiểu kiến trúc
3. 🔍 Explore source code
4. 💻 Bắt đầu develop features
5. 🧪 Write tests
6. 🚀 Deploy

---

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Kociemba Algorithm](http://kociemba.org/cube.htm)
- [OpenCV Tutorial](https://docs.opencv.org/4.x/d6/d00/tutorial_py_root.html)

---

Nếu gặp vấn đề, hãy tạo issue trên GitHub hoặc liên hệ team!
