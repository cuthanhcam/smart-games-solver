# Contributing Guidelines

Cảm ơn bạn đã quan tâm đến việc đóng góp cho dự án Rubik Cube Solver! 🎉

## Code of Conduct

- Tôn trọng lẫn nhau
- Constructive feedback
- Tập trung vào việc cải thiện dự án

## Làm thế nào để đóng góp

### 1. Fork & Clone

```bash
# Fork repo trên GitHub
# Sau đó clone về máy

git clone https://github.com/YOUR_USERNAME/rubik-cube-solver.git
cd rubik-cube-solver
```

### 2. Tạo Branch

```bash
git checkout -b feature/your-feature-name
# hoặc
git checkout -b fix/your-bug-fix
```

### 3. Coding Standards

#### Flutter/Dart
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter analyze` để check
- Format code: `flutter format lib/`
- Write tests cho features mới

#### Python
- Follow [PEP 8](https://pep8.org/)
- Use type hints
- Format với `black`
- Write docstrings

### 4. Commit Messages

Format:
```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: Feature mới
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting, etc)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

Ví dụ:
```
feat(detection): improve color detection algorithm

- Add histogram equalization
- Implement adaptive thresholding
- Increase detection accuracy by 15%

Closes #42
```

### 5. Testing

```bash
# Mobile
cd mobile
flutter test

# Backend
cd backend
pytest tests/
```

### 6. Push & Pull Request

```bash
git push origin feature/your-feature-name
```

Sau đó tạo Pull Request trên GitHub với:
- Title rõ ràng
- Description chi tiết những gì đã thay đổi
- Screenshots (nếu có UI changes)
- Link đến related issues

## Areas to Contribute

### 🎨 Frontend
- UI/UX improvements
- New features
- Performance optimization
- Bug fixes

### 🔧 Backend
- API improvements
- Algorithm optimization
- New endpoints
- Bug fixes

### 📝 Documentation
- README improvements
- Code comments
- Tutorials
- Translations

### 🧪 Testing
- Unit tests
- Integration tests
- E2E tests

### 🐛 Bug Reports

Tạo issue với:
- Mô tả bug
- Steps to reproduce
- Expected vs actual behavior
- Screenshots/logs
- Environment (OS, Flutter version, etc)

### 💡 Feature Requests

Tạo issue với:
- Mô tả feature
- Use case
- Mockups (nếu có)

## Review Process

1. Code review bởi maintainers
2. CI/CD checks pass
3. Conflict resolution (nếu có)
4. Merge vào main branch

## Questions?

Tạo issue hoặc liên hệ maintainers!

---

Cảm ơn bạn đã đóng góp! 🙏
