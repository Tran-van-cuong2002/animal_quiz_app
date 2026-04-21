import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Thư viện để lưu dữ liệu Offline vào bộ nhớ máy
import 'package:firebase_auth/firebase_auth.dart';         // Thư viện Xác thực người dùng của Firebase
import 'package:google_sign_in/google_sign_in.dart';       // Thư viện hỗ trợ Đăng nhập bằng tài khoản Google

// Import các file khác trong app để chuyển màn hình
import '../models/animal.dart';
import 'game_screen.dart';
import 'leaderboard_screen.dart';

// Màn hình bắt đầu (StartScreen) - Nơi bé nhập tên, chọn độ khó và đăng nhập
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  // Bộ điều khiển (Controller) dùng để lấy dữ liệu từ ô nhập Tên của bé
  final TextEditingController _nameController = TextEditingController();

  // Biến lưu trữ độ khó đang được chọn (Mặc định mở app lên là mức Vừa)
  Difficulty _selectedDifficulty = Difficulty.medium;

  // Hàm initState luôn chạy ĐẦU TIÊN khi màn hình này được mở lên
  @override
  void initState() {
    super.initState();
    _loadPlayerName(); // Gọi hàm tự động lấy lại tên bé đã gõ ở lần chơi trước
  }

  // Hàm lấy tên người chơi đã lưu Offline trong điện thoại
  _loadPlayerName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedName = prefs.getString('playerName') ?? "";
    final user = FirebaseAuth.instance.currentUser;

    setState(() {
      if (savedName.isNotEmpty) {
        _nameController.text = savedName; // Ưu tiên tên bé đã gõ và lưu lần trước
      } else if (user != null) {
        _nameController.text = user.displayName ?? ""; // Nếu không có, tự lấy tên Google điền vào
      }
    });
  }

  // Hàm lưu tên người chơi vào bộ nhớ Offline của điện thoại
  _savePlayerName(String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('playerName', name);
  }

  // Hàm hiển thị Bảng (Dialog) Hướng dẫn chơi
  void _showHowToPlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.menu_book_rounded, color: Colors.blue), SizedBox(width: 10), Text("Hướng dẫn chơi")]),
        content: const Text(
          "⭐ Mức DỄ: Trẻ nhỏ đoán hình rõ nét với 2 đáp án, không tính giờ. Chơi thoải mái không sợ thua.\n\n"
              "⭐ Mức VỪA: 4 đáp án, có 45 giây để suy nghĩ. Bé có 5 mạng.\n\n"
              "⭐ Mức KHÓ: Màn hình hiện ảnh bị làm mờ, nghe tiếng kêu và đoán trong 30 giây! Khi đoán đúng hình nét sẽ hiện ra. Bé có 3 mạng.\n\n"
              "💡 Mẹo: Dùng quyền trợ giúp 50/50 hoặc Đổi câu nếu thấy khó nhé!",
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("ĐÃ HIỂU", style: TextStyle(fontSize: 18)))],
      ),
    );
  }

  // Hàm hiển thị Bảng (Dialog) Thông tin ứng dụng
  void _showAboutApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.info_outline, color: Colors.orange), SizedBox(width: 10), Text("Thông tin")]),
        content: const Text(
          "Ứng dụng: Đoán Tên Loài Vật\nPhiên bản: 1.0.0 \n\nMột trò chơi giáo dục vui nhộn giúp bé khám phá thế giới động vật.",
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("ĐÓNG", style: TextStyle(fontSize: 18)))],
      ),
    );
  }

  // --- QUY TRÌNH ĐĂNG NHẬP GOOGLE KẾT HỢP FIREBASE ---
  void _login() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);

        User? user = FirebaseAuth.instance.currentUser;
        setState(() {
          // Khi vừa đăng nhập thành công, tự động điền tên Google vào ô trống để bé thấy
          // Nhưng bé HOÀN TOÀN CÓ THỂ xóa đi và gõ tên khác
          if (user != null && user.displayName != null) {
            _nameController.text = user.displayName!;
          }
        });

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng nhập thành công! 🌟')));
      }
    } catch (e) {
      debugPrint("Lỗi đăng nhập: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng nhập thất bại, vui lòng thử lại!')));
    }
  }

  // --- QUY TRÌNH ĐĂNG XUẤT KHỎI GOOGLE VÀ FIREBASE ---
  void _logout() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    setState(() {
      _nameController.clear(); // Xóa trống tên vừa hiển thị
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đăng xuất tài khoản Google')));
  }

  // === PHẦN GIAO DIỆN (UI) CỦA MÀN HÌNH BẮT ĐẦU ===
  @override
  Widget build(BuildContext context) {
    // Lấy thông tin người dùng đang đăng nhập hiện tại trên điện thoại
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.indigo, size: 35),
      ),

      // Drawer: Ngăn kéo trượt từ bên trái sang, chứa Menu của ứng dụng
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.orange, Colors.deepOrange], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                child: user?.photoURL == null ? const Icon(Icons.person, size: 40, color: Colors.orange) : null,
              ),
              accountName: Text(user?.displayName ?? "Chưa đăng nhập Google", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              accountEmail: Text(user?.email ?? "Chơi ngay không cần đăng nhập"),
            ),

            ListTile(
              leading: const Icon(Icons.home_rounded, color: Colors.green, size: 30),
              title: const Text('Màn hình chính', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 30),
              title: const Text('Bảng xếp hạng Online', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded, color: Colors.blue, size: 30),
              title: const Text('Hướng dẫn chơi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _showHowToPlay();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_rounded, color: Colors.grey, size: 30),
              title: const Text('Thông tin ứng dụng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _showAboutApp();
              },
            ),
            const Divider(),

            if (user != null)
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 30),
                title: const Text('Đăng xuất', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.login_rounded, color: Colors.green, size: 30),
                title: const Text('Đăng nhập Google', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                onTap: () {
                  Navigator.pop(context);
                  _login();
                },
              ),
          ],
        ),
      ),

      // Phần thân (Body) của Màn hình Bắt Đầu
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF89CFF0), Color(0xFFE6E6FA)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                  child: const Icon(Icons.pets_rounded, size: 70, color: Colors.orange),
                ),
                const SizedBox(height: 15),
                const Text("Chào mừng bé!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 15),

                // MỚI: LUÔN LUÔN HIỂN THỊ Ô NHẬP TÊN ĐỂ CÓ THỂ CHỈNH SỬA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
                    decoration: InputDecoration(
                      hintText: "Nhập tên bé vào đây nhé", filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      // Đổi icon cái bút thành Ngôi sao nếu đã đăng nhập để nhìn đẹp hơn
                      prefixIcon: Icon(user != null ? Icons.stars_rounded : Icons.edit, color: user != null ? Colors.amber : Colors.orange),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Khối Chọn Độ Khó: DỄ - VỪA - KHÓ
                const Text("Bé chọn độ khó nào?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDifficultyButton("DỄ", Colors.green, Difficulty.easy),
                      _buildDifficultyButton("VỪA", Colors.orange, Difficulty.medium),
                      _buildDifficultyButton("KHÓ", Colors.red, Difficulty.hard),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Nút "VÀO CHƠI" khổng lồ màu cam
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800), padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 5,
                  ),
                  onPressed: () {
                    // Logic khi ấn Nút vào chơi mới: Luôn lấy tên từ Ô nhập chữ
                    String name = _nameController.text.trim();

                    // Nếu bé xóa trắng ô và không nhập gì:
                    if (name.isEmpty) {
                      name = "Bạn nhỏ ẩn danh";
                    }

                    // Lưu tên bé vừa gõ vào bộ nhớ (để lần sau vào app không phải gõ lại)
                    _savePlayerName(name);

                    // Chuyển sang màn hình GameScreen với Tên đã nhập
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => GameScreen(playerName: name, difficulty: _selectedDifficulty)));
                  },
                  child: const Text("VÀO CHƠI", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HÀM XÂY DỰNG GIAO DIỆN NÚT CHỌN ĐỘ KHÓ ---
  Widget _buildDifficultyButton(String title, Color color, Difficulty level) {
    bool isSelected = _selectedDifficulty == level;
    return GestureDetector(
      onTap: () => setState(() => _selectedDifficulty = level),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 3),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))] : [],
        ),
        child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : color)),
      ),
    );
  }
}