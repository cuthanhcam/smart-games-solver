# Rubik Solver - Hướng dẫn sử dụng

## Tổng quan
Rubik Solver là một mini-game trong ứng dụng giúp giải rubik cube 3x3 bằng cách sử dụng camera để nhận diện màu sắc hoặc nhập tay thông tin các mặt.

## Cách sử dụng

### 1. Truy cập Rubik Solver
- Từ màn hình chính (Home), nhấn vào nút "Rubik Solver" trong phần Mini games
- Giao diện sẽ hiển thị với 2 tab: Camera và Origami

### 2. Tab Camera
- **Mục đích**: Sử dụng camera để tự động nhận diện màu sắc của rubik
- **Cách sử dụng**:
  1. Đặt mặt rubik cần quét vào khung hình vuông trên màn hình
  2. Đảm bảo sticker góc trên-phải trùng với viền vàng để đúng hướng
  3. Nhấn nút "Chụp & phân loại" để chụp ảnh và phân tích màu
  4. Hệ thống sẽ tự động chuyển sang mặt tiếp theo sau khi phân tích thành công

- **Thứ tự quét**: U (Up) → R (Right) → F (Front) → D (Down) → L (Left) → B (Back)

### 3. Tab Origami
- **Mục đích**: Nhập tay thông tin màu sắc của 6 mặt rubik
- **Cách sử dụng**:
  1. Chọn màu từ bảng màu ở trên
  2. Nhấn vào các ô trong lưới 3x3 của từng mặt để tô màu
  3. Sticker tâm (ô giữa) đã được cố định màu theo chuẩn
  4. Mặt đang được highlight là mặt cần hoàn thành tiếp theo
  5. Có thể nhấn nút refresh để xóa và làm lại mặt đó

### 4. Giải rubik
- Sau khi hoàn thành đủ 6 mặt, nút "Tiếp tục" sẽ được kích hoạt
- Nhấn "Tiếp tục" để chuyển sang màn hình kết quả
- Hệ thống sẽ sử dụng thuật toán Kociemba để tính toán các bước giải
- Kết quả sẽ hiển thị dưới dạng các ký tự: L, R, U, D, F, B (xoay thuận) và L', R', U', D', F', B' (xoay ngược)

## Lưu ý quan trọng

### Về màu sắc
- Mỗi màu phải xuất hiện đúng 9 lần trên toàn bộ rubik
- Nếu có lỗi màu sắc, hệ thống sẽ hiển thị thông báo và yêu cầu kiểm tra lại
- Có thể chọn bất kỳ mặt nào để quét lại trong tab Origami

### Về camera
- Cần cấp quyền truy cập camera cho ứng dụng
- Đảm bảo ánh sáng đủ để camera nhận diện màu sắc chính xác
- Giữ rubik ổn định khi chụp ảnh để tránh bị mờ

### Về thuật toán giải
- Sử dụng thuật toán Kociemba (two-phase algorithm)
- Tối đa 22 bước để giải rubik
- Thời gian tính toán có thể mất vài giây

## Xử lý lỗi

### Lỗi camera
- Kiểm tra quyền truy cập camera
- Đảm bảo thiết bị có camera và hoạt động bình thường
- Thử khởi động lại ứng dụng nếu camera không hoạt động

### Lỗi màu sắc
- Kiểm tra lại các mặt đã nhập
- Đảm bảo mỗi màu xuất hiện đúng 9 lần
- Sử dụng tab Origami để sửa lại mặt có vấn đề

### Lỗi giải rubik
- Kiểm tra lại thông tin các mặt đã nhập
- Đảm bảo rubik có thể giải được (không bị lỗi cấu trúc)
- Thử nhấn "Thử lại" nếu có lỗi trong quá trình tính toán

## Tính năng nâng cao

### Calibration màu sắc
- Hệ thống sử dụng màu chuẩn để so sánh:
  - U (Up): Trắng (#F2F2F2)
  - R (Right): Đỏ (#E74C3C)
  - F (Front): Xanh lá (#2ECC71)
  - D (Down): Vàng (#F1C40F)
  - L (Left): Xanh dương (#3498DB)
  - B (Back): Tím (#9B59B6)

### Phân tích màu sắc
- Sử dụng thuật toán phân tích màu RGB
- Lấy màu trung bình trong vùng 10x10 pixel xung quanh mỗi sticker
- So sánh với màu chuẩn để xác định màu rubik

## Hỗ trợ
Nếu gặp vấn đề, vui lòng:
1. Kiểm tra lại các bước hướng dẫn
2. Thử khởi động lại ứng dụng
3. Kiểm tra quyền truy cập camera
4. Đảm bảo rubik có cấu trúc hợp lệ
