import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/start_screen.dart';

// Hàm main: Nơi chương trình bắt đầu chạy
void main() async {
  // Đảm bảo các thư viện Widget của Flutter được nạp xong
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo kết nối với Server Firebase trước khi chạy App
  await Firebase.initializeApp();

  // Chạy ứng dụng
  runApp(const AnimalQuizApp());
}

class AnimalQuizApp extends StatelessWidget {
  const AnimalQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đoán tên loài vật',
      debugShowCheckedModeBanner: false, // Tắt chữ "DEBUG" màu đỏ góc phải
      theme: ThemeData(
          primarySwatch: Colors.green,
          fontFamily: 'ComicSans' // Đổi Font chữ ngộ nghĩnh cho trẻ em
      ),
      // home: Định nghĩa màn hình đầu tiên khi mở app
      home: const StartScreen(),
    );
  }
}