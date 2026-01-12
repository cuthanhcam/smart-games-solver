# Contributing to Smart Games Solver

Chúng tôi hoan nghênh mọi đóng góp từ cộng đồng! 🎉

## 🤝 Cách thức đóng góp

### 1. Fork và Clone

```bash
# Fork repository này về tài khoản GitHub của bạn (nhấn nút Fork trên GitHub)

# Clone repository đã fork về máy local
git clone https://github.com/cuthanhcam/smart-games-solver.git
cd smart-games-solver
```

### 2. Tạo Branch mới

```bash
# Tạo branch cho tính năng mới
git checkout -b feature/ten-tinh-nang

# Hoặc tạo branch cho bugfix
git checkout -b fix/ten-bug
```

### 3. Thực hiện thay đổi

- Viết code theo code style guide (xem bên dưới)
- Test kỹ các thay đổi của bạn
- Commit với message rõ ràng

```bash
git add .
git commit -m "feat: Thêm tính năng XYZ"
```

### 4. Push và tạo Pull Request

```bash
# Push branch lên GitHub
git push origin feature/ten-tinh-nang

# Truy cập GitHub và tạo Pull Request từ branch của bạn về branch `develop`
```

---

## 📝 Quy tắc Commit Message

Chúng tôi sử dụng [Conventional Commits](https://www.conventionalcommits.org/) để dễ dàng theo dõi lịch sử thay đổi.

### Format:

```
<type>: <description>

[optional body]

[optional footer]
```

### Types:

- `feat:` - Thêm tính năng mới
- `fix:` - Sửa bug
- `docs:` - Cập nhật documentation
- `style:` - Format code, không ảnh hưởng logic (white-space, formatting, missing semi-colons)
- `refactor:` - Refactor code (không phải bug fix hay thêm feature)
- `perf:` - Cải thiện performance
- `test:` - Thêm hoặc sửa tests
- `chore:` - Cập nhật dependencies, config, build tasks
- `ci:` - Thay đổi CI configuration files và scripts

### Ví dụ:

```bash
feat: Thêm chế độ chơi multiplayer cho Sudoku

fix: Sửa lỗi tính điểm sai trong game 2048

docs: Cập nhật hướng dẫn cài đặt trong README

refactor: Tối ưu hóa thuật toán Minimax trong Caro AI

test: Thêm unit tests cho AuthService
```

---

## 💻 Code Style Guidelines

### Python (Backend)

- **Style Guide**: Tuân thủ [PEP 8](https://peps.python.org/pep-0008/)
- **Formatter**: Sử dụng [Black](https://github.com/psf/black)
- **Linter**: Sử dụng [Flake8](https://flake8.pycqa.org/)
- **Type Hints**: Sử dụng type hints khi có thể
- **Naming Convention**:
  - `snake_case` cho functions, methods, variables
  - `PascalCase` cho classes
  - `UPPER_SNAKE_CASE` cho constants

```python
# ✅ Good
def calculate_score(user_id: int, game_type: str) -> int:
    total_score = 0
    # ...
    return total_score

# ❌ Bad
def CalculateScore(userId, gameType):
    TotalScore = 0
    return TotalScore
```

**Format code trước khi commit:**

```bash
cd backend
black app/
flake8 app/
```

### Dart/Flutter (Mobile)

- **Style Guide**: Tuân thủ [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- **Formatter**: Sử dụng `dart format`
- **Linter**: Cấu hình trong `analysis_options.yaml`
- **Naming Convention**:
  - `camelCase` cho functions, methods, variables
  - `PascalCase` cho classes, enums, typedefs
  - `lowerCamelCase` cho constants

```dart
// ✅ Good
class GameService {
  Future<GameResult> calculateScore(String userId) async {
    final score = 0;
    // ...
    return GameResult(score: score);
  }
}

// ❌ Bad
class game_service {
  calculate_score(user_id) {
    var Score = 0;
    return Score;
  }
}
```

**Format code trước khi commit:**

```bash
cd mobile
dart format lib/
flutter analyze
```

### Comments

- Viết comments bằng **tiếng Việt** hoặc **tiếng Anh** (nhất quán trong cùng một file)
- Comment phải giải thích **WHY** (tại sao), không phải **WHAT** (cái gì)
- Sử dụng docstrings cho functions/methods public

```python
# ✅ Good
def calculate_minimax_score(board, depth):
    """
    Tính điểm Minimax cho nước đi hiện tại.
    
    Sử dụng Alpha-Beta Pruning để tối ưu hóa performance.
    Depth được giới hạn để tránh timeout trên mobile devices.
    """
    # Limit depth để tránh timeout trên thiết bị yếu
    if depth > MAX_DEPTH:
        return evaluate_heuristic(board)

# ❌ Bad
def calculate_minimax_score(board, depth):
    # Tính điểm
    if depth > MAX_DEPTH:  # Check depth
        return evaluate_heuristic(board)  # Return score
```

---

## 🧪 Testing

### Backend Tests

```bash
cd backend

# Chạy tất cả tests
pytest

# Chạy với coverage
pytest --cov=app --cov-report=html

# Chạy specific test file
pytest tests/test_auth.py
```

### Mobile Tests

```bash
cd mobile

# Chạy unit tests
flutter test

# Chạy integration tests
flutter test integration_test/
```

**Yêu cầu:** Pull Request phải có tests cho code mới (trừ UI changes nhỏ).

---

## 🔄 Quy trình Review

1. **Tự review code của bạn** trước khi tạo PR
2. **Pull Request sẽ được review** bởi maintainers trong vòng 48 giờ
3. **Thảo luận và cải thiện**: Có thể có yêu cầu thay đổi
4. **Approve và Merge**: Sau khi approve, PR sẽ được merge vào `develop`
5. **Testing**: Code sẽ được test kỹ trước khi merge vào `main`

### Checklist trước khi tạo PR:

- [ ] Code đã được format (Black/Dart format)
- [ ] Không có linter errors
- [ ] Tests đã pass
- [ ] Commit messages tuân thủ Conventional Commits
- [ ] Đã test thủ công trên thiết bị/emulator
- [ ] Documentation đã được cập nhật (nếu cần)
- [ ] CHANGELOG.md đã được cập nhật (nếu là feature lớn)

---

## 🐛 Báo cáo Bug

Phát hiện bug? Tạo [GitHub Issue](https://github.com/cuthanhcam/smart-games-solver/issues) với template sau:

### Template:

```markdown
## 🐛 Mô tả Bug
[Giải thích rõ ràng và ngắn gọn bug là gì]

## 📋 Các bước tái hiện
1. Mở màn hình '...'
2. Nhấn vào '...'
3. Cuộn xuống '...'
4. Thấy lỗi

## ✅ Kết quả mong đợi
[Mô tả điều đáng lẽ phải xảy ra]

## ❌ Kết quả thực tế
[Mô tả điều thực sự xảy ra]

## 📸 Screenshots
[Nếu có thể, đính kèm ảnh chụp màn hình]

## 🖥️ Môi trường
- **OS**: [e.g. Android 13, iOS 16]
- **Device**: [e.g. Samsung Galaxy S23, iPhone 14]
- **App Version**: [e.g. 1.0.0]
- **Flutter Version**: [e.g. 3.16.0]

## ℹ️ Thông tin bổ sung
[Bất kỳ context nào khác về vấn đề]
```

---

## 💡 Đề xuất Tính năng

Có ý tưởng tính năng mới? Tạo [GitHub Issue](https://github.com/cuthanhcam/smart-games-solver/issues) với label `enhancement`:

### Template:

```markdown
## 🚀 Tính năng đề xuất
[Mô tả rõ ràng tính năng bạn muốn thêm]

## 🎯 Vấn đề cần giải quyết
[Giải thích vấn đề hiện tại và tại sao tính năng này hữu ích]

## 💭 Giải pháp đề xuất
[Mô tả cách tính năng nên hoạt động]

## 🎨 Alternatives (Optional)
[Các giải pháp thay thế khác bạn đã cân nhắc]

## 📎 Mock-up / Wireframe (Optional)
[Nếu có, đính kèm hình ảnh minh họa]

## ℹ️ Thông tin bổ sung
[Context khác về tính năng]
```

---

## 📚 Tài nguyên hữu ích

### Documentation:
- [Flutter Documentation](https://docs.flutter.dev/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

### Coding Standards:
- [PEP 8 – Style Guide for Python Code](https://peps.python.org/pep-0008/)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Conventional Commits](https://www.conventionalcommits.org/)

### Tools:
- [Black - Python Code Formatter](https://black.readthedocs.io/)
- [Flake8 - Python Linter](https://flake8.pycqa.org/)
- [Dart Format](https://dart.dev/tools/dart-format)

---

## ❓ Câu hỏi?

Nếu bạn có bất kỳ câu hỏi nào, đừng ngại:

- 💬 Tạo [GitHub Discussion](https://github.com/cuthanhcam/smart-games-solver/discussions)
- 📧 Email: cuthanhcam04@gmail.com
- 🐛 Tạo [GitHub Issue](https://github.com/cuthanhcam/smart-games-solver/issues)

---

## 🙏 Cảm ơn!

Cảm ơn bạn đã quan tâm đến việc đóng góp cho Smart Games Solver! Mọi đóng góp, dù lớn hay nhỏ, đều được trân trọng. 

**Happy coding! 🚀**

---

<div align="center">

[⬆ Về đầu trang](#contributing-to-smart-games-solver)

</div>
