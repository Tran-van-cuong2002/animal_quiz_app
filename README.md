# 🐾 Animal Quiz App - Bé Học Loài Vật

Ứng dụng Flutter giáo dục giúp các bé nhận biết các loài động vật qua hình ảnh sinh động và âm thanh thực tế. Dự án kết hợp chế độ chơi Offline nhanh chóng và chế độ Online mở rộng qua Firebase.

[![GitHub Repo](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/Tran-van-cuong2002/animal_quiz_app)

## 🌟 Tính năng nổi bật

- **Chế độ chơi đa dạng:**
    - **Offline:** 6 con vật quen thuộc có sẵn trong máy (Chó, Mèo, Gà, Lợn, Vịt, Bò).
    - **Online:** Tải 20 con vật mới lạ từ Firebase Firestore (Sư tử, Cá mập, Voi, Kangaroo...).
- **Hệ thống Đăng nhập:** Hỗ trợ đăng nhập bằng Google hoặc nhập tên thủ công để lưu điểm.
- **Tương tác trực quan:**
    - Nghe âm thanh tiếng kêu thực tế khi bắt đầu mỗi câu hỏi.
    - Hình ảnh chất lượng cao từ Internet (có bộ nhớ đệm giúp tải nhanh).
- **Phần thưởng & Cạnh tranh:**
    - Hiệu ứng pháo hoa (Confetti) chúc mừng khi hoàn thành bài thi.
    - **Bảng Vàng (Leaderboard):** Xếp hạng những người chơi có số sao cao nhất toàn cầu.
- **Dữ liệu linh hoạt:** Có chức năng cập nhật dữ liệu từ xa giúp nội dung game luôn mới mẻ.

## 📂 Cấu trúc dự án

Dự án được tối ưu hóa theo phong cách tối giản, tập trung mã nguồn chính vào một file duy nhất để dễ quản lý luồng xử lý:

```text
animal_quiz_app/
├── android/                # Cấu hình Android (Chứa file google-services.json)
├── assets/                 # Tài nguyên tĩnh
│   ├── audios/             # Các file âm thanh .mp3 offline
│   └── images/             # Hình ảnh, icon ứng dụng
├── lib/                    # Mã nguồn chính
│   └── main.dart           # File DUY NHẤT chứa: Logic game, Giao diện, Models & Firebase
├── pubspec.yaml            # Khai báo thư viện (Firebase, Audioplayers, Confetti...)
└── README.md               # Hướng dẫn sử dụng dự án
🛠 Cài đặt & Sử dụng
1. Yêu cầu
Flutter SDK (phiên bản mới nhất).

Một thiết bị Android (thật hoặc máy ảo) đã cài đặt Google Play Services.

2. Các bước thiết lập
Clone dự án về máy:

Bash
git clone [https://github.com/Tran-van-cuong2002/animal_quiz_app.git](https://github.com/Tran-van-cuong2002/animal_quiz_app.git)
Cài đặt thư viện:

Bash
flutter pub get
Cấu hình Firebase:

Tạo dự án trên Firebase Console.

Thêm ứng dụng Android và tải file google-services.json bỏ vào thư mục android/app/.

Bật Firestore và Authentication (Google Sign-in).

Chạy ứng dụng:

Bash
flutter run
📦 Công nghệ sử dụng
Framework: Flutter & Dart

Backend: Firebase (Firestore, Auth)

Âm thanh: audioplayers

Hình ảnh: cached_network_image

Hiệu ứng: confetti

Lưu trữ cục bộ: shared_preferences

🔗 Link dự án
Bạn có thể xem mã nguồn và đóng góp cho dự án tại:

👉 https://github.com/Tran-van-cuong2002/animal_quiz_app

Phát triển bởi Trần Văn Cường - 2026


---

### Hướng dẫn cách cập nhật lên GitHub:

1. Mở terminal tại thư mục dự án của bạn.
2. Tạo file README: `touch README.md` (nếu chưa có).
3. Dán nội dung trên vào file.
4. Chạy các lệnh sau để đẩy lên GitHub:

```bash
git add README.md
git commit -m "Cập nhật README hoàn chỉnh với link GitHub"
git push origin main