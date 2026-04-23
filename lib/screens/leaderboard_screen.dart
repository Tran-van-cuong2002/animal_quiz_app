import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: const Text("🏆 Bảng Vàng Đua Top 🏆", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.amber,
        centerTitle: true,
      ),
      // StreamBuilder giúp tự động cập nhật UI mỗi khi dữ liệu trên Firebase thay đổi (Realtime)
      body: StreamBuilder<QuerySnapshot>(
        // Truy vấn: Lấy từ bảng 'leaderboard', sắp xếp theo 'score' giảm dần, lấy top 10
        stream: FirebaseFirestore.instance
            .collection('leaderboard')
            .orderBy('score', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          // Trạng thái đang tải dữ liệu
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));
          // Trạng thái lỗi mạng
          if (snapshot.hasError) return const Center(child: Text("Lỗi kết nối mạng!", style: TextStyle(color: Colors.red, fontSize: 18)));
          // Trạng thái chưa có ai chơi (danh sách trống)
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Chưa có ai chơi cả. Bé hãy là người đầu tiên nhé!", style: TextStyle(fontSize: 18, color: Colors.grey)));

          // Lấy danh sách tài liệu (documents) từ snapshot
          final docs = snapshot.data!.docs;

          // Dùng ListView.builder để vẽ danh sách top 10 người chơi
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              // Ép kiểu dữ liệu của mỗi tài liệu thành Map<String, dynamic> để dễ truy cập
              var player = docs[index].data() as Map<String, dynamic>;

              // Chia màu huy chương cho top 3: vàng, bạc, đồng; những người còn lại sẽ có màu xanh nhạt
              Color medalColor = index == 0 ? Colors.amber : (index == 1 ? Colors.blueGrey[300]! : (index == 2 ? Colors.brown[400]! : Colors.indigo[100]!));

              return Card(
                elevation: 4, margin: const EdgeInsets.only(bottom: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: ListTile(
                  // Biểu tượng bên trái: Huy chương cho top 3, số thứ hạng cho những người còn lại
                  leading: CircleAvatar(backgroundColor: medalColor, child: index < 3 ? const Icon(Icons.military_tech_rounded, color: Colors.white) : Text("#${index + 1}")),
                  // Tên người chơi
                  title: Text(player['name'] ?? "Ẩn danh", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  // Điểm số và ico`n sao ở bên phải
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text("${player['score']}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)), const Icon(Icons.star_rounded, color: Colors.amber)]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}