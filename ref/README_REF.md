# Thư Mục Tham Khảo (Reference)

Thư mục này chứa toàn bộ code logic và assets để tham khảo khi tạo project mới.

## Cấu trúc

```
ref/
├── lib/                    # Toàn bộ source code Dart
│   ├── main.dart          # Entry point
│   ├── data/              # Database logic
│   ├── minigames/         # Các minigame (Caro, Rubik, v.v.)
│   ├── models/            # Data models
│   ├── repositories/      # Data repositories
│   ├── screens/           # UI screens
│   ├── utils/             # Utilities
│   └── widgets/           # Reusable widgets
│
├── assets/                # Images, icons, và resources
│   ├── caro/
│   ├── images/
│   └── rubik_faces/
│
├── pubspec.yaml           # Dependencies và project config
├── analysis_options.yaml  # Dart analysis config
└── *.md                   # Các file documentation

```

## Các Component Chính

### 1. Rubik Solver
- **Location**: `lib/minigames/rubik/`
- **Services**: API service để giải Rubik
- **Docs**: RUBIK_SOLVER_FLOW.md, RUBIK_SOLVER_GUIDE.md

### 2. Caro Game
- **Location**: `lib/minigames/caro/`

### 3. Database
- **Location**: `lib/data/app_database.dart`
- Sử dụng sqflite

### 4. Models & Repositories
- **Models**: `lib/models/`
- **Repositories**: `lib/repositories/`

## Cách Sử Dụng

1. Copy thư mục `lib/` vào project mới
2. Copy `pubspec.yaml` và cài đặt dependencies:
   ```bash
   flutter pub get
   ```
3. Copy `assets/` và cấu hình trong pubspec.yaml
4. Tham khảo các file .md để hiểu flow và logic

## Notes

- Đảm bảo Flutter SDK đã được cài đặt
- Check các dependencies trong pubspec.yaml
- Xem các file markdown để hiểu rõ logic
