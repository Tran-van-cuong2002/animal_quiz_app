import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart' hide Source;
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ==========================================
// HÀM MAIN
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AnimalQuizApp());
}

class AnimalQuizApp extends StatelessWidget {
  const AnimalQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đoán tên loài vật',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'ComicSans'),
      home: const StartScreen(),
    );
  }
}

// ==========================================
// --- KIỂU DỮ LIỆU ---
// ==========================================
enum Difficulty { easy, medium, hard }

class Animal {
  final String name;
  final String imageUrl;
  final String soundFile;
  final String question;
  final List<String> options;

  Animal({
    required this.name,
    required this.imageUrl,
    required this.soundFile,
    required this.question,
    required this.options
  });

  factory Animal.fromMap(Map<String, dynamic> data) {
    return Animal(
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      soundFile: data['soundFile'] ?? '',
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
    );
  }
}

// ==========================================
// --- MÀN HÌNH BẮT ĐẦU ---
// ==========================================
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final TextEditingController _nameController = TextEditingController();
  Difficulty _selectedDifficulty = Difficulty.medium;

  @override
  void initState() {
    super.initState();
    _loadPlayerName();
  }

  _loadPlayerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _nameController.text = (prefs.getString('playerName') ?? "");
      });
    }
  }

  _savePlayerName(String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('playerName', name);
  }

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

  void _showAboutApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.info_outline, color: Colors.orange), SizedBox(width: 10), Text("Thông tin")]),
        content: const Text(
          "Ứng dụng: Đoán Tên Loài Vật\nPhiên bản: 3.0.0 (Tối ưu UI & Tính năng)\n\nMột trò chơi giáo dục vui nhộn giúp bé khám phá thế giới động vật.",
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("ĐÓNG", style: TextStyle(fontSize: 18)))],
      ),
    );
  }

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
        setState(() {});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng nhập thành công! 🌟')));
      }
    } catch (e) {
      debugPrint("Lỗi đăng nhập: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng nhập thất bại, vui lòng thử lại!')));
    }
  }

  void _logout() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    setState(() {
      _nameController.clear();
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đăng xuất tài khoản Google')));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.indigo, size: 35),
      ),
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
              accountEmail: Text(user?.email ?? "Bé có thể chơi ngay không cần đăng nhập"),
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
                if (user != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange, width: 3),
                      boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.amber, size: 35),
                        const SizedBox(width: 10),
                        Text(
                          user.displayName ?? "Bạn nhỏ",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
                      decoration: InputDecoration(
                        hintText: "Nhập tên bé vào đây nhé", filled: true, fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.edit, color: Colors.orange),
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800), padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 5,
                  ),
                  onPressed: () {
                    String name = "";
                    if (user != null) { name = user.displayName ?? "Bạn nhỏ ẩn danh"; }
                    else {
                      name = _nameController.text.trim();
                      if (name.isEmpty) name = "Bạn nhỏ ẩn danh";
                      _savePlayerName(name);
                    }
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

// ==========================================
// --- MÀN HÌNH BẢNG XẾP HẠNG FIREBASE ---
// ==========================================
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('leaderboard')
            .orderBy('score', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));
          if (snapshot.hasError) return const Center(child: Text("Lỗi kết nối mạng!", style: TextStyle(color: Colors.red, fontSize: 18)));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Chưa có ai chơi cả. Bé hãy là người đầu tiên nhé!", style: TextStyle(fontSize: 18, color: Colors.grey)));

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var player = docs[index].data() as Map<String, dynamic>;
              Color medalColor = index == 0 ? Colors.amber : (index == 1 ? Colors.blueGrey[300]! : (index == 2 ? Colors.brown[400]! : Colors.indigo[100]!));
              return Card(
                elevation: 4, margin: const EdgeInsets.only(bottom: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: medalColor, child: index < 3 ? const Icon(Icons.military_tech_rounded, color: Colors.white) : Text("#${index + 1}")),
                  title: Text(player['name'] ?? "Ẩn danh", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
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

// ==========================================
// --- MÀN HÌNH TRÒ CHƠI CHÍNH ---
// ==========================================
class GameScreen extends StatefulWidget {
  final String playerName;
  final Difficulty difficulty;
  const GameScreen({super.key, required this.playerName, required this.difficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  int _timeLeft = 45;
  List<Animal> questions = [];
  int currentIndex = 0;
  List<String> shuffledOptions = [];
  int currentStars = 0;
  bool is5050Used = false;
  bool isSkipUsed = false;
  bool isLoading = true;
  int _lives = 0;
  bool _isRevealed = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();

    if (widget.difficulty == Difficulty.medium) {
      _lives = 5;
    } else if (widget.difficulty == Difficulty.hard) {
      _lives = 3;
    }

    _loadGameData();
  }

  void _loadGameData() async {
    List<Animal> combinedAnimals = [
      Animal(name: "CON MÈO", imageUrl: "assets/images/cat.png", soundFile: "cat.mp3", question: "Đố bé đây là bạn nào nè?", options: ["CON GÀ", "CON CHÓ", "CON MÈO", "CON THỎ"]),
      Animal(name: "CON CHÓ", imageUrl: "assets/images/dog.png", soundFile: "dog.mp3", question: "Bạn nào hay vẫy đuôi chào bé?", options: ["CON CHÓ", "CON HỔ", "CON LỢN", "CON MÈO"]),
      Animal(name: "CON GÀ", imageUrl: "assets/images/chicken.png", soundFile: "chicken.mp3", question: "Con gì gáy Ò ó o o mỗi sáng?", options: ["CON VỊT", "CON GÀ", "CON CHIM", "CON DÊ"]),
      Animal(name: "CON BÒ", imageUrl: "assets/images/cow.png", soundFile: "cow.mp3", question: "Bạn nào cho chúng ta sữa tươi uống nhỉ?", options: ["CON BÒ", "CON NGỰA", "CON DÊ", "CON CỪU"]),
      Animal(name: "CON LỢN", imageUrl: "assets/images/pig.png", soundFile: "pig.mp3", question: "Con gì kêu Ụt ịt ụt ịt?", options: ["CON CHÓ", "CON LỢN", "CON MÈO", "CON VOI"]),
      Animal(name: "CON KHỈ", imageUrl: "assets/images/monkey.png", soundFile: "monkey.mp3", question: "Bạn nào leo trèo giỏi và thích ăn chuối?", options: ["CON KHỈ", "CON HƯƠU", "CON GẤU", "CON CÁO"]),
    ];

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await FirebaseFirestore.instance.collection('animals').get(const GetOptions(source: Source.cache)) as QuerySnapshot<Map<String, dynamic>>;
        if (snapshot.docs.isEmpty) {
          snapshot = await FirebaseFirestore.instance.collection('animals').get(const GetOptions(source: Source.server)) as QuerySnapshot<Map<String, dynamic>>;
        }
      } catch (e) {
        snapshot = await FirebaseFirestore.instance.collection('animals').get(const GetOptions(source: Source.server)) as QuerySnapshot<Map<String, dynamic>>;
      }

      if (snapshot.docs.isNotEmpty) {
        List<Animal> onlineAnimals = snapshot.docs.map((doc) => Animal.fromMap(doc.data())).toList();
        combinedAnimals.addAll(onlineAnimals);
      }
    } catch (e) {
      debugPrint("Lỗi kết nối mạng, đang nạp dữ liệu Offline.");
    }

    combinedAnimals.shuffle();
    if (mounted) {
      setState(() {
        questions = combinedAnimals;
        isLoading = false;
        _initGame();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.difficulty == Difficulty.easy) return;

    _timeLeft = widget.difficulty == Difficulty.hard ? 30 : 45;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) _timeLeft--;
        else { _timer?.cancel(); _onTimeOut(); }
      });
    });
  }

  void _resumeTimer() {
    _timer?.cancel();
    if (widget.difficulty == Difficulty.easy) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) _timeLeft--;
        else { _timer?.cancel(); _onTimeOut(); }
      });
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_isMuted) {
        _audioPlayer.stop();
      } else {
        _playSound(questions[currentIndex].soundFile);
      }
    });
  }

  void _playSound(String fileOrUrl) async {
    if (_isMuted) return;

    try {
      if (fileOrUrl.startsWith('http') || fileOrUrl.startsWith('https')) {
        await _audioPlayer.play(UrlSource(fileOrUrl));
      } else {
        await _audioPlayer.play(AssetSource('sounds/$fileOrUrl'));
      }
    } catch (e) {
      debugPrint("Lỗi âm thanh: $e");
    }
  }

  void _confirmExit() {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 35),
            SizedBox(width: 10),
            Text("Thoát trò chơi?", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 24)),
          ],
        ),
        content: const Text(
            "Bé có chắc chắn muốn thoát game không?\nĐiểm số hiện tại sẽ không được lưu nhé!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18)
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeTimer();
            },
            child: const Text("Chơi tiếp", style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StartScreen()));
            },
            child: const Text("Thoát luôn", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _initGame() {
    setState(() {
      _isRevealed = false;
      Animal currentQ = questions[currentIndex];
      if (widget.difficulty == Difficulty.easy) {
        List<String> wrongOptions = List.from(currentQ.options)..remove(currentQ.name);
        wrongOptions.shuffle();
        shuffledOptions = [currentQ.name, wrongOptions.first];
      } else {
        shuffledOptions = List.from(currentQ.options);
      }
      shuffledOptions.shuffle();
    });
    _playSound(questions[currentIndex].soundFile);
    _startTimer();
  }

  void _use5050() {
    if (is5050Used || widget.difficulty == Difficulty.easy) return;
    setState(() {
      is5050Used = true;
      String correctAnswer = questions[currentIndex].name;
      List<String> wrongOptions = shuffledOptions.where((opt) => opt != correctAnswer).toList();
      wrongOptions.shuffle();
      shuffledOptions.remove(wrongOptions[0]);
      shuffledOptions.remove(wrongOptions[1]);
    });
  }

  void _useSkip() {
    if (isSkipUsed) return;
    setState(() { isSkipUsed = true; _timer?.cancel(); _nextQuestion(); });
  }

  void _nextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() { currentIndex++; _initGame(); });
    } else {
      _saveScoreAndFinish();
    }
  }

  void _saveScoreAndFinish() async {
    _timer?.cancel();
    _playSound('correct.mp3');
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      bool? wantToLogin = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Lưu điểm lên Bảng Vàng! 🏆", textAlign: TextAlign.center, style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          content: const Text("Bé có muốn đăng nhập Google để lưu thành tích tuyệt vời này không?", textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Bỏ qua", style: TextStyle(fontSize: 16, color: Colors.grey)),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.g_mobiledata, size: 30),
              label: const Text("Đăng nhập"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            )
          ],
        ),
      );

      if (wantToLogin == true) {
        try {
          final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
          if (googleUser != null) {
            final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
            final OAuthCredential credential = GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            );
            await FirebaseAuth.instance.signInWithCredential(credential);
            currentUser = FirebaseAuth.instance.currentUser;
          }
        } catch (e) {
          debugPrint("Lỗi đăng nhập: $e");
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng nhập thất bại, không thể lưu điểm!')));
        }
      }
    }

    if (currentUser != null) {
      String diffString = widget.difficulty == Difficulty.easy ? "(Dễ)" : (widget.difficulty == Difficulty.medium ? "(Vừa)" : "(Khó)");
      String finalName = widget.playerName;

      try {
        await FirebaseFirestore.instance.collection('leaderboard').add({
          'name': '$finalName $diffString',
          'score': currentStars,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint("Lỗi đẩy điểm lên Firebase: $e");
      }
    }

    if (mounted) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => VictoryScreen(
                  playerName: widget.playerName,
                  stars: currentStars,
                  total: questions.length
              )
          )
      );
    }
  }

  void _onTimeOut() {
    _playSound('wrong.mp3');
    _handleWrongAnswer("Hết giờ rồi!", "Đáp án đúng là ${questions[currentIndex].name}.", isTimeout: true);
  }

  void _onOptionSelected(String selectedOption) {
    _timer?.cancel();
    if (selectedOption == questions[currentIndex].name) {
      _playSound('correct.mp3');
      setState(() {
        currentStars++;
        _isRevealed = true;
      });
      _showDialog("Tuyệt vời!", "Bé đoán đúng rồi! 🌟", Colors.green, isCorrect: true);
    } else {
      _playSound('wrong.mp3');
      _handleWrongAnswer("Chưa đúng!", "Bé thử lại nhé! 💪", isTimeout: false);
    }
  }

  void _handleWrongAnswer(String title, String content, {required bool isTimeout}) {
    if (widget.difficulty == Difficulty.easy) {
      _showDialog(title, content, Colors.redAccent, isCorrect: false, isTimeout: isTimeout);
    } else {
      setState(() { _lives--; });

      if (_lives <= 0) {
        _showGameOverDialog();
      } else {
        _showDialog(title, "$content\nBé còn $_lives mạng nhé!", Colors.orange, isCorrect: false, isTimeout: isTimeout);
      }
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Hết mạng rồi!", textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 26)),
        content: const Text("Rất tiếc bé đã hết lượt chơi.\nCùng xem điểm số bé đạt được nhé!", textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _saveScoreAndFinish();
            },
            child: const Text("Xem điểm", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showDialog(String title, String content, Color color, {required bool isCorrect, bool isTimeout = false}) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 26)),
        content: Text(content, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: () {
              Navigator.pop(context);
              if (isCorrect || isTimeout) _nextQuestion();
              else { _playSound(questions[currentIndex].soundFile); _startTimer(); }
            },
            child: Text(isCorrect || isTimeout ? "Tiếp tục" : "Thử lại", style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));

    Animal currentQuestion = questions[currentIndex];
    bool isHardMode = widget.difficulty == Difficulty.hard;

    // Tính toán chiều rộng nút bấm để không bị tràn ngang
    double buttonWidth = widget.difficulty == Difficulty.easy
        ? double.infinity
        : (MediaQuery.of(context).size.width - 50) / 2;

    return WillPopScope(
      onWillPop: () async {
        _confirmExit();
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF89CFF0), Color(0xFFE6E6FA)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
          ),
          child: SafeArea(
            // KHẮC PHỤC BOTTOM OVERFLOW: Cho phép màn hình cuộn nếu thiết bị quá ngắn
            child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [

                            // --- 1. THANH TRẠNG THÁI (KHẮC PHỤC RIGHT OVERFLOW) ---
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Khối bên trái: Nút thoát, Tắt âm, Tên và Mạng (Dùng Expanded để ép không lấn sang phải)
                                  Expanded(
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 32),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: _confirmExit,
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(
                                            _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                            color: _isMuted ? Colors.grey : Colors.indigo,
                                            size: 32,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: _toggleMute,
                                        ),
                                        const SizedBox(width: 8),
                                        // Expanded bọc Text để nếu tên dài sẽ hiện "..."
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Bé: ${widget.playerName}",
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                                                overflow: TextOverflow.ellipsis, // Giới hạn tên dài
                                              ),
                                              if (widget.difficulty != Difficulty.easy)
                                                Wrap( // Dùng Wrap cho trái tim lỡ màn hình quá bé
                                                  children: List.generate(
                                                    widget.difficulty == Difficulty.medium ? 5 : 3,
                                                        (index) => Icon(
                                                      index < _lives ? Icons.favorite : Icons.favorite_border,
                                                      color: Colors.redAccent,
                                                      size: 18,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // Khối bên phải: Đồng hồ và Điểm
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.difficulty != Difficulty.easy)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(color: _timeLeft <= 3 ? Colors.red : Colors.white, borderRadius: BorderRadius.circular(20)),
                                          child: Text("$_timeLeft s", style: TextStyle(fontWeight: FontWeight.bold, color: _timeLeft <= 3 ? Colors.white : Colors.indigo)),
                                        ),
                                      const SizedBox(width: 10),
                                      Row(children: [const Icon(Icons.star, color: Colors.amber), Text("$currentStars", style: const TextStyle(fontWeight: FontWeight.bold))]),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // --- 2. CÂU HỎI HIỆN TẠI ---
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                  "Câu ${currentIndex + 1} / ${questions.length}",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)
                              ),
                            ),

                            // --- 3. KHU VỰC HÌNH ẢNH (Ép dãn tối đa khoảng trống giữa) ---
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                          isHardMode ? "Nhìn ảnh mờ, nghe tiếng kêu và đoán xem!" : currentQuestion.question,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    GestureDetector(
                                      onTap: () => _playSound(currentQuestion.soundFile),
                                      child: Container(
                                        height: 180, width: 240,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(24),
                                            border: Border.all(color: Colors.white, width: 8)
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Builder(
                                              builder: (context) {
                                                Widget animalImage = currentQuestion.imageUrl.startsWith('http')
                                                    ? CachedNetworkImage(
                                                  imageUrl: currentQuestion.imageUrl, fit: BoxFit.cover,
                                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                                                )
                                                    : Image.asset(currentQuestion.imageUrl, fit: BoxFit.cover);

                                                return (isHardMode && !_isRevealed)
                                                    ? ImageFiltered(
                                                  imageFilter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                                                  child: animalImage,
                                                )
                                                    : animalImage;
                                              }
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ),

                            // --- 4. QUYỀN TRỢ GIÚP ---
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (widget.difficulty != Difficulty.easy) ...[
                                    ElevatedButton.icon(onPressed: is5050Used ? null : _use5050, icon: const Icon(Icons.star_half_rounded), label: const Text("50/50")),
                                    const SizedBox(width: 15),
                                  ],
                                  ElevatedButton.icon(onPressed: isSkipUsed ? null : _useSkip, icon: const Icon(Icons.skip_next_rounded), label: const Text("Đổi câu")),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),

                            // --- 5. KHU VỰC ĐÁP ÁN ---
                            Container(
                              width: double.infinity, padding: const EdgeInsets.all(15),
                              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                              child: Wrap(
                                spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, // Thu nhỏ spacing một chút để an toàn
                                children: shuffledOptions.map((opt) => SizedBox(
                                  width: buttonWidth, height: 60,
                                  child: ElevatedButton(
                                      onPressed: () => _onOptionSelected(opt),
                                      child: Text(opt, style: const TextStyle(fontSize: 18), textAlign: TextAlign.center)
                                  ),
                                )).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// --- MÀN HÌNH CHIẾN THẮNG ---
// ==========================================
class VictoryScreen extends StatefulWidget {
  final String playerName;
  final int stars;
  final int total;

  const VictoryScreen({super.key, required this.playerName, required this.stars, required this.total});

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("CHÚC MỪNG BÉ\n${widget.playerName.toUpperCase()}!", textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              const SizedBox(height: 20), const Icon(Icons.stars_rounded, size: 100, color: Colors.amber),
              Text("${widget.stars} / ${widget.total} Sao", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
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
          Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive)
          ),
        ],
      ),
    );
  }
}