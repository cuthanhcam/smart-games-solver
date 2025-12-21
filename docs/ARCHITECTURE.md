# Kiến trúc dự án Rubik Cube Solver

## Tổng quan

Dự án Rubik Cube Solver được xây dựng theo kiến trúc Client-Server với:
- **Frontend**: Flutter mobile app (iOS & Android)
- **Backend**: FastAPI REST API server (Python)

## Sơ đồ kiến trúc tổng thể

```
┌─────────────────────────────────────────────────────────────┐
│                    MOBILE APPLICATION                        │
│                       (Flutter)                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────┐ │
│  │  Presentation  │  │  Presentation  │  │    Common    │ │
│  │    Layer       │  │    Layer       │  │   Widgets    │ │
│  │  (Camera UI)   │  │  (Solution UI) │  │              │ │
│  └────────┬───────┘  └────────┬───────┘  └──────────────┘ │
│           │                   │                             │
│  ┌────────▼───────────────────▼───────┐                    │
│  │        BLoC / State Management      │                    │
│  │     (Business Logic Component)      │                    │
│  └────────────────┬────────────────────┘                    │
│                   │                                          │
│  ┌────────────────▼────────────────────┐                    │
│  │         Domain Layer                │                    │
│  │  (Entities, Use Cases, Repositories)│                    │
│  └────────────────┬────────────────────┘                    │
│                   │                                          │
│  ┌────────────────▼────────────────────┐                    │
│  │          Data Layer                 │                    │
│  │  (API Client, Data Sources, Models) │                    │
│  └────────────────┬────────────────────┘                    │
│                   │                                          │
└───────────────────┼──────────────────────────────────────────┘
                    │
                    │ HTTP/REST
                    │
┌───────────────────▼──────────────────────────────────────────┐
│                    BACKEND API SERVER                        │
│                      (FastAPI)                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              API Endpoints                              │ │
│  │  /api/detect | /api/validate | /api/solve             │ │
│  └────────────────────┬───────────────────────────────────┘ │
│                       │                                      │
│  ┌────────────────────▼───────────────────────────────────┐ │
│  │              Business Logic                             │ │
│  │  ┌──────────────┐ ┌─────────────┐ ┌─────────────────┐ │ │
│  │  │  Detection   │ │  Validator  │ │  Solver Service │ │ │
│  │  │   Service    │ │   Service   │ │   (Kociemba)    │ │ │
│  │  └──────────────┘ └─────────────┘ └─────────────────┘ │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Core Utilities                             │ │
│  │  Config | Models | Utils                               │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Chi tiết kiến trúc Mobile App

### Clean Architecture + BLoC Pattern

```
mobile/lib/
│
├── core/                          # Core functionality
│   ├── constants/                 # App & API constants
│   ├── di/                        # Dependency Injection (GetIt)
│   ├── network/                   # HTTP client setup
│   ├── theme/                     # App theming
│   └── utils/                     # Helper functions
│
└── features/                      # Feature modules
    │
    ├── cube_detection/            # Feature: Nhận diện Rubik
    │   ├── data/
    │   │   ├── datasources/       # API calls
    │   │   │   └── cube_remote_datasource.dart
    │   │   ├── models/            # Data models (JSON)
    │   │   │   └── cube_face_model.dart
    │   │   └── repositories/      # Repository implementation
    │   │       └── cube_repository_impl.dart
    │   │
    │   ├── domain/
    │   │   ├── entities/          # Business objects
    │   │   │   ├── cube_face.dart
    │   │   │   └── cube_state.dart
    │   │   ├── repositories/      # Repository interfaces
    │   │   │   └── cube_repository.dart
    │   │   └── usecases/          # Business logic
    │   │       ├── detect_cube_face.dart
    │   │       └── validate_cube.dart
    │   │
    │   └── presentation/
    │       ├── bloc/              # State management
    │       │   ├── detection_bloc.dart
    │       │   ├── detection_event.dart
    │       │   └── detection_state.dart
    │       ├── pages/             # Screen widgets
    │       │   ├── home_page.dart
    │       │   └── camera_page.dart
    │       └── widgets/           # Reusable components
    │           └── cube_grid_widget.dart
    │
    └── cube_solver/               # Feature: Giải Rubik
        ├── data/
        ├── domain/
        └── presentation/
```

### Data Flow

1. **User Action** → Presentation Layer (UI)
2. **Event** → BLoC (State Management)
3. **Use Case** → Domain Layer (Business Logic)
4. **Repository** → Data Layer
5. **API Call** → Backend Server
6. **Response** → Back through layers
7. **State Update** → UI Re-renders

### Ví dụ: Detect Cube Face Flow

```
User takes photo
    ↓
CameraPage (Presentation)
    ↓
DetectionBloc.add(DetectFaceEvent)
    ↓
DetectCubeFaceUseCase (Domain)
    ↓
CubeRepository.detectFace() (Data)
    ↓
CubeRemoteDataSource.detectFace()
    ↓
POST /api/detect → Backend
    ↓
Response ← Backend
    ↓
CubeFaceModel → CubeFace Entity
    ↓
DetectionBloc.emit(DetectionSuccess)
    ↓
UI updates with detected colors
```

## Chi tiết kiến trúc Backend

### Layered Architecture

```
backend/app/
│
├── api/                           # API Layer
│   └── endpoints/
│       ├── detection.py           # Detection endpoints
│       └── solver.py              # Solver endpoints
│
├── core/                          # Core config
│   └── config.py                  # Settings & env vars
│
├── models/                        # Data models (Pydantic)
│   ├── cube.py                    # Cube-related models
│   └── solution.py                # Solution models
│
├── services/                      # Business Logic
│   ├── detection_service.py       # Image processing & detection
│   ├── cube_validator.py          # Cube state validation
│   └── solver_service.py          # Solving algorithm
│
├── utils/                         # Utilities
│   └── image_processing.py        # Image helpers
│
└── main.py                        # FastAPI app entry
```

### Request Flow

```
HTTP Request
    ↓
FastAPI Router
    ↓
Endpoint Handler (api/endpoints/)
    ↓
Pydantic Validation (models/)
    ↓
Service Layer (services/)
    ↓
Business Logic Processing
    ↓
Response Model (models/)
    ↓
HTTP Response (JSON)
```

### Ví dụ: Solve Cube Flow

```
POST /api/solve
    ↓
solver.py endpoint
    ↓
Validate request (CubeStateRequest)
    ↓
SolverService.solve()
    ↓
Convert to Kociemba notation
    ↓
kociemba.solve()
    ↓
Parse solution steps
    ↓
Return SolutionResponse
    ↓
JSON response to client
```

## API Communication

### Request/Response Format

**Detect Face:**
```
Request:
POST /api/detect
Content-Type: multipart/form-data
- image: [binary]
- face_name: "front"

Response:
{
  "success": true,
  "face_name": "front",
  "colors": [["W","W","W"], ...],
  "confidence": 0.95
}
```

**Solve Cube:**
```
Request:
POST /api/solve
Content-Type: application/json
{
  "faces": [
    {"face_name": "front", "colors": [...]},
    ...
  ]
}

Response:
{
  "success": true,
  "steps": [
    {"move": "U", "notation": "U", "description": "..."},
    ...
  ],
  "total_moves": 20,
  "algorithm": "U R U' R' F' U F",
  "execution_time": 0.123
}
```

## Thuật toán Kociemba

### Two-Phase Algorithm

**Phase 1**: Đưa cube về trạng thái G1
- Tất cả edge orientation đúng
- Corner orientation đúng
- 4 middle-layer edges về vị trí

**Phase 2**: Giải hoàn toàn từ G1
- Sử dụng chỉ 18 moves của group G1
- Đảm bảo giải trong ≤ 20 moves

### Notation

Cube notation (54 ký tự):
```
UUUUUUUUU RRRRRRRRR FFFFFFFFF DDDDDDDDD LLLLLLLLL BBBBBBBBB
│         │         │         │         │         │
Up        Right     Front     Down      Left      Back
```

Color mapping:
- U = White (Up)
- D = Yellow (Down)
- R = Red (Right)
- L = Orange (Left)
- F = Blue (Front)
- B = Green (Back)

## State Management (BLoC)

### Event → State Flow

```dart
// Event
class DetectFaceEvent extends DetectionEvent {
  final File image;
  final FaceName faceName;
}

// BLoC
class DetectionBloc extends Bloc<DetectionEvent, DetectionState> {
  on<DetectFaceEvent>((event, emit) async {
    emit(DetectionLoading());
    
    final result = await detectCubeFaceUseCase(
      image: event.image,
      faceName: event.faceName,
    );
    
    result.fold(
      (failure) => emit(DetectionError(failure.message)),
      (cubeFace) => emit(DetectionSuccess(cubeFace)),
    );
  });
}

// State
abstract class DetectionState {}
class DetectionInitial extends DetectionState {}
class DetectionLoading extends DetectionState {}
class DetectionSuccess extends DetectionState {
  final CubeFace cubeFace;
}
class DetectionError extends DetectionState {
  final String message;
}
```

## Security & Best Practices

### Mobile App
- ✅ Input validation
- ✅ Secure HTTP (HTTPS in production)
- ✅ Error handling
- ✅ Loading states
- ✅ Offline capability (optional)

### Backend API
- ✅ CORS configuration
- ✅ Request validation (Pydantic)
- ✅ File upload limits
- ✅ Error handling & logging
- ✅ Rate limiting (TODO)
- ✅ Authentication (TODO for production)

## Performance Considerations

### Mobile
- Image compression trước khi upload
- Caching với `cached_network_image`
- Lazy loading
- Memory management

### Backend
- Async/await cho I/O operations
- Image processing tối ưu
- Caching solutions (Redis - optional)
- Load balancing (production)

## Testing Strategy

```
Mobile:
- Unit tests: Domain layer (use cases)
- Widget tests: Presentation layer
- Integration tests: Full flows

Backend:
- Unit tests: Services
- Integration tests: API endpoints
- E2E tests: Full scenarios
```

## Deployment

### Mobile
- Android: APK/AAB → Google Play Store
- iOS: IPA → Apple App Store

### Backend
- Docker container
- Deploy to: AWS/GCP/Azure/Heroku
- Use: Nginx + Uvicorn
- Database: PostgreSQL (nếu cần lưu history)

---

## Resources

- [Flutter Clean Architecture](https://resocoder.com/flutter-clean-architecture-tdd/)
- [BLoC Pattern](https://bloclibrary.dev/)
- [FastAPI Best Practices](https://fastapi.tiangolo.com/tutorial/)
- [Kociemba Algorithm](http://kociemba.org/cube.htm)
