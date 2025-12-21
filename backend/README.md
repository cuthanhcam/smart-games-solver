# Backend API for Rubik Cube Solver

Backend API được xây dựng bằng FastAPI để xử lý nhận diện và giải Rubik's Cube.

## Tính năng

- 🔍 API nhận diện màu sắc từ ảnh Rubik Cube
- ✅ Validate trạng thái Rubik Cube
- 🧩 Giải Rubik Cube bằng thuật toán Kociemba (tối ưu 20 bước)
- 📊 RESTful API với documentation tự động (Swagger/OpenAPI)
- 🚀 Performance cao với FastAPI

## Kiến trúc

```
backend/
├── app/
│   ├── api/
│   │   └── endpoints/      # API endpoints (detection, solver)
│   ├── core/              # Core config và settings
│   ├── models/            # Pydantic models (request/response)
│   ├── services/          # Business logic
│   │   ├── detection_service.py    # Xử lý nhận diện hình ảnh
│   │   ├── cube_validator.py       # Validate cube state
│   │   └── solver_service.py       # Giải thuật Rubik
│   ├── utils/             # Utility functions
│   └── main.py            # FastAPI app entry point
├── tests/                 # Unit tests
├── requirements.txt       # Python dependencies
└── .env                   # Environment variables
```

## API Endpoints

### Detection
- `POST /api/detect` - Nhận diện màu sắc từ ảnh
- `POST /api/validate` - Validate trạng thái cube

### Solver
- `POST /api/solve` - Giải Rubik Cube

### Docs
- `GET /docs` - Swagger UI
- `GET /redoc` - ReDoc
- `GET /health` - Health check

## Cài đặt

### 1. Tạo virtual environment

```bash
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
```

### 2. Cài đặt dependencies

```bash
pip install -r requirements.txt
```

### 3. Tạo file .env (optional)

```env
PROJECT_NAME=Rubik Cube Solver API
DEBUG=True
HOST=0.0.0.0
PORT=8000
```

### 4. Chạy server

```bash
# Development (with auto-reload)
python -m app.main

# hoặc
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Server sẽ chạy tại: `http://localhost:8000`

API Documentation: `http://localhost:8000/docs`

## Sử dụng API

### Detect Cube Face

```bash
curl -X POST "http://localhost:8000/api/detect" \
  -H "Content-Type: multipart/form-data" \
  -F "image=@cube_face.jpg" \
  -F "face_name=front"
```

### Solve Cube

```bash
curl -X POST "http://localhost:8000/api/solve" \
  -H "Content-Type: application/json" \
  -d '{
    "faces": [
      {
        "face_name": "front",
        "colors": [
          ["W", "W", "W"],
          ["W", "W", "W"],
          ["W", "W", "W"]
        ]
      },
      // ... 5 faces nữa
    ]
  }'
```

## Testing

```bash
pytest tests/
```

## Thuật toán giải Rubik

Sử dụng **Kociemba's Two-Phase Algorithm**:
- Phase 1: Đưa cube về trạng thái có thể giải trong phase 2
- Phase 2: Giải cube hoàn toàn
- Đảm bảo giải trong tối đa 20 bước

## Roadmap phát triển

- [x] Setup FastAPI project structure
- [x] Implement basic API endpoints
- [ ] Improve color detection algorithm
- [ ] Add ML model for better detection
- [ ] Add caching for better performance
- [ ] Add database for history
- [ ] Add WebSocket for real-time updates
- [ ] Deploy to cloud (AWS/Azure/GCP)

## Dependencies chính

- **FastAPI**: Modern web framework
- **OpenCV**: Image processing
- **Kociemba**: Rubik's Cube solver
- **Pydantic**: Data validation
- **Uvicorn**: ASGI server

## License

MIT
