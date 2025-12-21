# Rubik Cube Solver - Hướng dẫn Chạy Ứng dụng

## Bước 1: Chuẩn bị Backend (Python FastAPI)

### 1.1. Cài đặt Python Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 1.2. Kiểm tra Kociemba Library

Chạy script kiểm tra:
```bash
python test_kociemba.py
```

Kết quả mong đợi:
```
✓✓✓ Kociemba library is working correctly! ✓✓✓
```

### 1.3. Chạy Backend Server

```bash
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Server sẽ chạy tại: `http://localhost:8000`

API Documentation: `http://localhost:8000/docs`

## Bước 2: Chuẩn bị Mobile App (Flutter)

### 2.1. Cài đặt Flutter Dependencies

```bash
cd mobile
flutter pub get
```

### 2.2. Cấu hình API Endpoint

Mở file `mobile/lib/core/constants/api_constants.dart` và update baseUrl:

```dart
class ApiConstants {
  // Nếu chạy trên Android Emulator
  static const String baseUrl = 'http://10.0.2.2:8000';
  
  // Nếu chạy trên iOS Simulator
  // static const String baseUrl = 'http://localhost:8000';
  
  // Nếu chạy trên thiết bị thật (thay YOUR_IP bằng IP máy tính)
  // static const String baseUrl = 'http://YOUR_IP:8000';
}
```

### 2.3. Chạy Mobile App

**Trên Android Emulator:**
```bash
cd mobile
flutter run
```

**Trên iOS Simulator (macOS only):**
```bash
cd mobile
flutter run -d ios
```

**Trên thiết bị thật:**
```bash
cd mobile
flutter run -d <device-id>
```

Kiểm tra danh sách devices:
```bash
flutter devices
```

## Bước 3: Sử dụng Ứng dụng

### 3.1. Luồng Hoạt động

1. **Màn hình Home**: Nhấn "Start Scanning" để bắt đầu
2. **Màn hình Camera**: 
   - Quét 6 mặt của Rubik Cube theo thứ tự: Front → Right → Back → Left → Up → Down
   - Mỗi lần chụp, ứng dụng sẽ gửi ảnh lên backend để nhận diện màu
   - Progress bar sẽ hiển thị tiến độ (1/6, 2/6, ...)
3. **Validation**: Sau khi quét đủ 6 mặt, ứng dụng sẽ validate cube state
4. **Màn hình Solution**: 
   - Hiển thị các bước giải chi tiết
   - Sử dụng nút Next/Previous để xem từng bước
   - Mỗi bước có mô tả rõ ràng (ví dụ: "Turn top face clockwise")

### 3.2. Tips để Quét Tốt

- ✅ Giữ khối Rubik trong khung hình 3x3
- ✅ Đảm bảo ánh sáng đầy đủ
- ✅ Tránh bóng đổ lên mặt cube
- ✅ Giữ camera song song với mặt cube
- ✅ Đặt cube ở khoảng cách vừa phải (20-30cm)

### 3.3. Giải thích Ký hiệu

| Ký hiệu | Mặt | Ý nghĩa |
|---------|-----|---------|
| U | Up | Mặt trên |
| D | Down | Mặt dưới |
| F | Front | Mặt trước |
| B | Back | Mặt sau |
| L | Left | Mặt trái |
| R | Right | Mặt phải |

| Modifier | Ý nghĩa |
|----------|---------|
| (không) | Xoay 90° theo chiều kim đồng hồ |
| ' | Xoay 90° ngược chiều kim đồng hồ |
| 2 | Xoay 180° |

Ví dụ:
- `U`: Xoay mặt trên 90° theo chiều kim đồng hồ
- `U'`: Xoay mặt trên 90° ngược chiều kim đồng hồ
- `U2`: Xoay mặt trên 180°

## Bước 4: Kiểm tra Lỗi

### 4.1. Backend không chạy

**Lỗi:** `Connection refused` hoặc `Network error`

**Giải pháp:**
1. Kiểm tra backend có đang chạy không: `curl http://localhost:8000/health`
2. Kiểm tra firewall có chặn port 8000 không
3. Với Android Emulator, dùng `10.0.2.2` thay vì `localhost`

### 4.2. Kociemba không hoạt động

**Lỗi:** `ModuleNotFoundError: No module named 'kociemba'`

**Giải pháp:**
```bash
pip install kociemba
python test_kociemba.py
```

### 4.3. Camera không hoạt động

**Lỗi:** `Camera permission denied`

**Giải pháp:**
- **Android**: Thêm quyền trong `AndroidManifest.xml` (đã có sẵn)
- **iOS**: Thêm quyền trong `Info.plist` (đã có sẵn)
- Kiểm tra cài đặt quyền trong Settings của thiết bị

### 4.4. Nhận diện màu không chính xác

**Nguyên nhân:**
- Ánh sáng kém
- Bóng đổ lên cube
- Camera không song song với mặt cube

**Giải pháp:**
- Cải thiện điều kiện ánh sáng
- Thử chụp lại mặt bị lỗi
- Điều chỉnh góc camera

## Bước 5: Development

### 5.1. Cấu trúc Project

```
rubik-cube-solver/
├── backend/              # FastAPI backend
│   ├── app/
│   │   ├── api/         # API endpoints
│   │   ├── services/    # Business logic
│   │   └── models/      # Pydantic models
│   └── requirements.txt
│
└── mobile/              # Flutter app
    ├── lib/
    │   ├── core/        # Core utilities
    │   └── features/    # Feature modules
    │       ├── cube_detection/
    │       └── cube_solver/
    └── pubspec.yaml
```

### 5.2. Testing Backend API

**Health Check:**
```bash
curl http://localhost:8000/health
```

**Test Detection API:**
```bash
curl -X POST "http://localhost:8000/api/v1/detect" \
  -F "image=@test_image.jpg" \
  -F "face=F"
```

**Test Solver API:**
```bash
curl -X POST "http://localhost:8000/api/v1/solve" \
  -H "Content-Type: application/json" \
  -d '{
    "cube_string": "UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB"
  }'
```

### 5.3. Hot Reload

Flutter hỗ trợ hot reload trong development:
- Nhấn `r` trong terminal để reload
- Nhấn `R` để restart app
- Nhấn `q` để thoát

### 5.4. Debug Mode

**Backend debug:**
```bash
uvicorn app.main:app --reload --log-level debug
```

**Flutter debug:**
```bash
flutter run --debug
```

## Bước 6: Build Production

### 6.1. Build Android APK

```bash
cd mobile
flutter build apk --release
```

APK file: `mobile/build/app/outputs/flutter-apk/app-release.apk`

### 6.2. Build Android App Bundle (for Google Play)

```bash
cd mobile
flutter build appbundle --release
```

### 6.3. Deploy Backend

**Docker:**
```bash
cd backend
docker build -t rubik-solver-api .
docker run -p 8000:8000 rubik-solver-api
```

**Heroku/Railway/Render:** Xem file SETUP.md

## Troubleshooting

### Issue: "Cube validation failed"

**Nguyên nhân:** Cube state không hợp lệ (sai số lượng màu, cấu hình không thể giải)

**Giải pháp:**
1. Kiểm tra lại các mặt đã quét
2. Đảm bảo quét đúng thứ tự: F → R → B → L → U → D
3. Chụp lại các mặt bị nhận diện sai màu

### Issue: "Solution not found"

**Nguyên nhân:** Kociemba không thể tìm giải pháp

**Giải pháp:**
1. Cube state có thể không hợp lệ
2. Thử validation lại
3. Check backend logs: `docker logs <container-id>`

## Liên hệ & Hỗ trợ

- Repository: [GitHub Link]
- Issues: [GitHub Issues]
- Email: your-email@example.com

## License

MIT License - Xem file LICENSE để biết thêm chi tiết.
