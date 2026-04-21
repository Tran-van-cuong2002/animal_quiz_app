# 🐾 Animal Quiz App - Bé Học Loài Vật

Ứng dụng Flutter giáo dục giúp các bé nhận biết các loài động vật qua hình ảnh sinh động và âm thanh thực tế. Dự án kết hợp chế độ chơi Offline nhanh chóng và chế độ Online mở rộng qua Firebase.

[![GitHub Repo](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/Tran-van-cuong2002/animal_quiz_app)

## 🌟 Tính năng nổi bật (Cập nhật bản 1.0)

- **3 Chế độ chơi thử thách:**
  - **Dễ:** Trẻ nhỏ đoán hình rõ nét với 2 đáp án, không tính giờ, không giới hạn lượt sai.
  - **Vừa:** 4 đáp án, 45 giây đếm ngược, có 5 mạng (trái tim).
  - **Khó:** Hiệu ứng **LÀM MỜ ẢNH (Blur)** bí ẩn, 30 giây đếm ngược, chỉ có 3 mạng. Đoán đúng ảnh sẽ hiện rõ nét!
- **Quyền trợ giúp:** Hỗ trợ tính năng 50/50 (loại bỏ 2 đáp án sai) và Đổi câu hỏi.
- **Hệ thống Đăng nhập thông minh:** Đăng nhập an toàn qua Google Authentication. Cho phép phụ huynh **sửa lại tên hiển thị** cho bé sau khi đăng nhập.
- **Tương tác trực quan & Tối ưu UI:**
  - Nút **Bật/Tắt âm thanh (Mute)** tiện lợi khi chơi ở nơi công cộng.
  - Giao diện **Responsive (chống tràn viền)** mượt mà trên mọi kích thước màn hình điện thoại.
  - Hiệu ứng pháo giấy (Confetti) chúc mừng khi hoàn thành bài thi.
- **Bảng Vàng (Leaderboard):** Tự động đẩy điểm lên Firebase Firestore và xếp hạng những người chơi có số sao cao nhất toàn cầu theo thời gian thực.

## 📂 Cấu trúc dự án (Mô hình Module hóa)

Dự án được phân chia theo cấu trúc thư mục chuẩn trong Flutter giúp dễ dàng mở rộng và bảo trì:

```text
animal_quiz_app/
├── android/                # Cấu hình Android (Chứa file google-services.json)
├── assets/                 # Tài nguyên tĩnh (Hình ảnh, Âm thanh)
├── lib/                    # Mã nguồn chính
│   ├── models/             # Chứa cấu trúc dữ liệu
│   │   └── animal.dart     # Định nghĩa object Animal và Độ khó
│   ├── screens/            # Chứa các màn hình giao diện
│   │   ├── start_screen.dart       # Màn hình bắt đầu, Drawer Menu & Đăng nhập
│   │   ├── game_screen.dart        # Trọng tâm: Logic game, Đếm ngược, Âm thanh
│   │   ├── victory_screen.dart     # Màn hình chúc mừng kết thúc game
│   │   └── leaderboard_screen.dart # Màn hình Bảng xếp hạng từ Firebase
│   └── main.dart           # File khởi chạy ứng dụng & Theme
├── pubspec.yaml            # Khai báo thư viện (Firebase, Audioplayers...)
└── README.md               # Hướng dẫn sử dụng dự án