import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart'; // Thư viện bắn pháo giấy
import 'start_screen.dart';
import 'leaderboard_screen.dart';

class VictoryScreen extends StatefulWidget {
  final String playerName; // Tên người chơi
  final int stars;         // Số sao (điểm) đạt được
  final int total;         // Tổng số câu hỏi

  const VictoryScreen({super.key, required this.playerName, required this.stars, required this.total});

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen> {
  // Bộ điều khiển (Controller) để quản lý hiệu ứng pháo giấy
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // Khởi tạo pháo giấy với thời lượng 3 giây và bắt
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    // Dọn dẹp bộ nhớ khigit
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFACD),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // UI Hiển thị chúc mừng và điểm số
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("CHÚC MỪNG BÉ\n${widget.playerName.toUpperCase()}!", textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              const SizedBox(height: 20), const Icon(Icons.stars_rounded, size: 100, color: Colors.amber),
              Text("${widget.stars} / ${widget.total} Sao", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),

              // Cụm Nút bấm: Chơi lại / Xem bảng xếp hạng
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StartScreen())),
                      child: const Text("CHƠI LẠI")
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, foregroundColor: Colors.white),
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StartScreen()));
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardScreen()));
                    },
                    child: const Text("XEM BẢNG VÀNG"),
                  ),
                ],
              )
            ],
          ),
          // Widget bắn pháo giấy đặt đè lên trên cùng (căn giữa trên)
          Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive)
          ),
        ],
      ),
    );
  }
}