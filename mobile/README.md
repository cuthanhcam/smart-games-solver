# Rubik Cube Solver - Mobile App

Ứng dụng Flutter hỗ trợ nhận diện và giải Rubik's Cube 3x3.

## Tính năng

- 📷 Quét Rubik Cube bằng camera
- 🎯 Nhận diện tự động các mặt của khối Rubik
- 🧩 Tính toán thuật toán giải tối ưu
- 📝 Hướng dẫn từng bước một cách chi tiết
- 🎨 Giao diện thân thiện và dễ sử dụng

## Kiến trúc

Project sử dụng **Clean Architecture** với BLoC pattern:

```
lib/
├── core/
│   ├── constants/       # Hằng số API, app
│   ├── di/             # Dependency Injection (GetIt)
│   ├── network/        # Dio client, interceptors
│   ├── theme/          # Theme và màu sắc
│   └── utils/          # Các hàm tiện ích
│
└── features/
    ├── cube_detection/  # Tính năng nhận diện Rubik
    │   ├── data/
    │   │   ├── datasources/  # Remote & Local data sources
    │   │   ├── models/       # Data models
    │   │   └── repositories/ # Repository implementations
    │   ├── domain/
    │   │   ├── entities/     # Business entities
    │   │   ├── repositories/ # Repository interfaces
    │   │   └── usecases/     # Business logic
    │   └── presentation/
    │       ├── bloc/         # BLoC (Business Logic Component)
    │       ├── pages/        # UI pages
    │       └── widgets/      # Reusable widgets
    │
    └── cube_solver/     # Tính năng giải Rubik
        ├── data/
        ├── domain/
        └── presentation/
```

## Yêu cầu hệ thống

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / Xcode
- Backend API đang chạy (xem folder `../backend`)

## Cài đặt

1. Cài đặt dependencies:
```bash
flutter pub get
```

2. Generate code (nếu cần):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. Chạy ứng dụng:
```bash
flutter run
```

## Cấu hình

Cập nhật URL backend trong file [lib/core/constants/api_constants.dart](lib/core/constants/api_constants.dart):

```dart
static const String baseUrl = 'http://YOUR_BACKEND_URL:8000/api';
```

## Dependencies chính

- **flutter_bloc**: State management
- **dio**: HTTP client
- **get_it**: Dependency injection
- **camera**: Truy cập camera
- **image**: Xử lý hình ảnh
- **equatable**: Object comparison

## Roadmap phát triển

- [x] Setup project structure
- [ ] Implement camera detection
- [ ] Integrate with backend API
- [ ] Add cube validation
- [ ] Show solution steps with animation
- [ ] Add 3D cube visualization
- [ ] Support manual input
- [ ] Add history feature
- [ ] Multilingual support

## License

MIT
