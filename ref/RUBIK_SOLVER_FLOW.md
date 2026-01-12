# Luồng hoạt động Rubik Solver

## 1. Khởi tạo
```
Home Screen → Rubik Solver Button → RubikSolverScreen
```

## 2. Giao diện chính
```
RubikSolverScreen
├── AppBar với 2 tabs: Camera | Origami
├── Tab Camera: CameraPreview + Grid Overlay
├── Tab Origami: 6 FaceGrid + Color Picker
└── Bottom: Continue Button (enabled khi đủ 6 mặt)
```

## 3. Tab Camera Flow
```
Camera Initialization
├── availableCameras() → CameraController
├── CameraPreview hiển thị
└── Grid Overlay (3x3 + góc vàng)

User Action: "Chụp & phân loại"
├── takePicture() → XFile
├── ColorAnalyzer.analyzeFaceColors()
│   ├── Chia ảnh thành 9 vùng (3x3)
│   ├── Lấy màu trung bình mỗi vùng
│   └── Map màu RGB → RubikColor
├── Kiểm tra tính hợp lệ (mỗi màu 9 lần)
├── Cập nhật state.faces[current]
└── Chuyển sang mặt tiếp theo
```

## 4. Tab Origami Flow
```
Color Picker Row
├── 6 màu chuẩn: U(RGB), R(RGB), F(RGB), D(RGB), L(RGB), B(RGB)
└── User chọn màu → _picked

FaceGrid (6 mặt)
├── Hiển thị lưới 3x3
├── Sticker tâm cố định màu theo mặt
├── User tap cell → gán màu _picked
├── Highlight mặt đang làm việc
└── Auto chuyển mặt khi hoàn thành

Validation
├── Kiểm tra đủ 6 mặt (mỗi mặt 9 sticker)
├── Kiểm tra mỗi màu xuất hiện đúng 9 lần
└── Enable Continue Button
```

## 5. Giải Rubik Flow
```
Continue Button Pressed
├── facesToFacelets() → String (54 ký tự)
├── Cube.fromFacelets() → Cube object
├── cube.solve(maxDepth: 21) → Solution
└── Navigate to RubikSolutionScreen

RubikSolutionScreen
├── Hiển thị solution dạng chips
├── ListView với từng bước giải
└── Error handling nếu không giải được
```

## 6. Color Analysis Algorithm
```
Image Analysis Pipeline
├── File → Uint8List → ui.Image
├── Chia ảnh thành 9 vùng (3x3 grid)
├── Mỗi vùng: lấy màu trung bình 10x10 pixel
├── RGB → RubikColor mapping:
│   ├── Tính khoảng cách màu với 6 màu chuẩn
│   └── Chọn màu có khoảng cách nhỏ nhất
└── Validation: mỗi màu đúng 9 lần
```

## 7. Error Handling
```
Camera Errors
├── Permission denied → Show message
├── Camera not available → Show placeholder
└── Capture failed → Show error snackbar

Color Analysis Errors
├── Invalid color counts → Show dialog
├── Analysis failed → Fallback to mock data
└── File not found → Show error message

Solving Errors
├── Invalid cube state → Show error
├── Timeout → Show retry button
└── No solution → Show error message
```

## 8. State Management
```
ScanState
├── current: Face (mặt đang highlight)
├── faces: Map<Face, List<RubikColor>>
├── isComplete: bool (đủ 6 mặt)
└── basicValidCounts(): bool (mỗi màu 9 lần)

UI State
├── _picked: RubikColor (màu đang chọn)
├── _isCameraInitialized: bool
├── _isCapturing: bool
└── _cameraController: CameraController?
```

## 9. Navigation Flow
```
Home Screen
└── Rubik Solver Button
    └── RubikSolverScreen
        ├── Tab Camera (scan faces)
        ├── Tab Origami (manual input)
        └── Continue Button
            └── RubikSolutionScreen
                ├── Show solution
                ├── Error handling
                └── Back to RubikSolverScreen
```

## 10. Dependencies
```
Flutter Packages
├── camera: ^0.10.5+9 (Camera functionality)
├── cuber: ^0.4.0 (Kociemba algorithm)
├── flutter/material.dart (UI components)
└── dart:ui (Image processing)

Custom Classes
├── RubikSolverScreen (Main screen)
├── ScanState (State management)
├── ColorAnalyzer (Color analysis)
├── FaceGrid (Face display)
├── RubikSolutionScreen (Solution display)
└── RubikTypes (Enums and utilities)
```
