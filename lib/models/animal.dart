// Định nghĩa các mức độ khó của game
enum Difficulty { easy, medium, hard }

// Lớp Animal: Khuôn mẫu để tạo ra các đối tượng con vật
class Animal {
  final String name;      // Tên con vật (VD: "CON MÈO")
  final String imageUrl;  // Đường dẫn ảnh (local assets hoặc link mạng)
  final String soundFile; // Tên file âm thanh (VD: "cat.mp3")
  final String question;  // Câu hỏi gợi ý
  final List<String> options; // Danh sách 4 đáp án để chọn

  // Constructor (Hàm khởi tạo)
  Animal({
    required this.name,
    required this.imageUrl,
    required this.soundFile,
    required this.question,
    required this.options
  });

  // Hàm này dùng để chuyển đổi dữ liệu dạng Map (từ Firebase tải về) thành đối tượng Animal
  factory Animal.fromMap(Map<String, dynamic> data) {
    return Animal(
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      soundFile: data['soundFile'] ?? '',
      question: data['question'] ?? '',
      // Chuyển mảng dynamic từ Firebase thành List<String>
      options: List<String>.from(data['options'] ?? []),
    );
  }
}