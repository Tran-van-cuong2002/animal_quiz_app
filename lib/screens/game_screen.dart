import 'dart:async';
import 'dart:ui'; // Thư viện cần thiết để dùng hiệu ứng ImageFilter (Làm mờ ảnh)
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart' hide Source;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Import các file khác trong app
import '../models/animal.dart';
import 'start_screen.dart';
import 'victory_screen.dart';
import 'leaderboard_screen.dart';

// Màn hình GameScreen: Nơi diễn ra các thao tác chơi game chính
class GameScreen extends StatefulWidget {
  final String playerName;       // Nhận tên người chơi từ màn hình StartScreen truyền sang
  final Difficulty difficulty;   // Nhận độ khó từ màn hình StartScreen truyền sang
  const GameScreen({super.key, required this.playerName, required this.difficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // --- CÁC BIẾN QUẢN LÝ TRẠNG THÁI CỦA GAME ---
  final AudioPlayer _audioPlayer = AudioPlayer(); // Bộ điều khiển phát âm thanh (phát tiếng kêu con vật, tiếng đúng/sai, v.v.)
  Timer? _timer;            // Bộ đếm thời gian đếm ngược (dùng cho mức Vừa và Khó)
  int _timeLeft = 45;       // Thời gian đếm ngược còn lại (tính bằng giây, mặc định 45s cho mức Vừa, 30s cho mức Khó, Mức Dễ không đếm giờ)
  List<Animal> questions = []; // Danh sách câu hỏi (các con vật) đã được tải về từ Firebase và/hoặc dữ liệu Offline cài sẵn
  int currentIndex = 0;     // Vị trí câu hỏi hiện tại (bắt đầu từ 0)
  List<String> shuffledOptions = []; // Danh sách 4 đáp án đã được xáo trộn ngẫu nhiên để hiển thị dưới dạng nút bấm (Để tránh trường hợp đáp án đúng luôn ở cùng 1 vị trí)
  int currentStars = 0;     // Điểm số (số sao) đạt được tính đến cau hỏi hiện tạiasd

  bool is5050Used = false;  // Biến kiểm tra xem đã dùng quyền trợ giúp 50/50 chưa (Nếu đã dùng thì không cho dùng lại)
  bool isSkipUsed = false;  // Biến kiểm tra xem đã dùng quền trợ giúp Đổi câu chưa (Nếu đã dùng thì không cho dùng lại)
  bool isLoading = true;    // Màn hình có đang trong trạng thái tải dữ liệu hay không (true = đang tải, false = đã tải xong và sẵn sàng chơi)
  int _lives = 0;           // Số mạng sống hiện tại
  bool _isRevealed = false; // Biến kiểm tra xem ảnh đã được lật (bỏ làm mờ) chưa
  bool _isMuted = false;    // Biến kiểm tra trạng thái Bật/Tắt âm thanh

  // Hàm initState: Chạy đầu tiên 1 lần duy nhất khi màn hình Game được mở lên
  @override
  void initState() {
    super.initState();
    // Gán số mạng sống tùy theo độ khó được chọn
    if (widget.difficulty == Difficulty.medium) {
      _lives = 5; // Mức vừa: 5 mạng
    } else if (widget.difficulty == Difficulty.hard) {
      _lives = 3; // Mức khó: 3 mạng
    }
    _loadGameData(); // Bắt đầu tải dữ liệu câu hỏi
  }

  // --- HÀM TẢI DỮ LIỆU CÂU HỎI ---
  void _loadGameData() async {
    // 1. Khởi tạo một mảng dữ liệu Offline cài cứng (Đề phòng trường hợp không có mạng internet)
    List<Animal> combinedAnimals = [
      Animal(name: "CON MÈO", imageUrl: "assets/images/cat.png", soundFile: "cat.mp3", question: "Đố bé đây là bạn nào nè?", options: ["CON GÀ", "CON CHÓ", "CON MÈO", "CON THỎ"]),
      Animal(name: "CON CHÓ", imageUrl: "assets/images/dog.png", soundFile: "dog.mp3", question: "Bạn nào hay vẫy đuôi chào bé?", options: ["CON CHÓ", "CON HỔ", "CON LỢN", "CON MÈO"]),
      Animal(name: "CON GÀ", imageUrl: "assets/images/chicken.png", soundFile: "chicken.mp3", question: "Con gì gáy Ò ó o o mỗi sáng?", options: ["CON VỊT", "CON GÀ", "CON CHIM", "CON DÊ"]),
      Animal(name: "CON BÒ", imageUrl: "assets/images/cow.png", soundFile: "cow.mp3", question: "Bạn nào cho chúng ta sữa tươi uống nhỉ?", options: ["CON BÒ", "CON NGỰA", "CON DÊ", "CON CỪU"]),
      Animal(name: "CON LỢN", imageUrl: "assets/images/pig.png", soundFile: "pig.mp3", question: "Con gì kêu Ụt ịt ụt ịt?", options: ["CON CHÓ", "CON LỢN", "CON MÈO", "CON VOI"]),
      Animal(name: "CON KHỈ", imageUrl: "assets/images/monkey.png", soundFile: "monkey.mp3", question: "Bạn nào leo trèo giỏi và thích ăn chuối?", options: ["CON KHỈ", "CON HƯƠU", "CON GẤU", "CON CÁO"]),
    ];

    // 2. Thử kết nối lên Firebase để lấy thêm các con vật mới
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        // Ưu tiên tải từ Bộ nhớ đệm (Cache) của điện thoại trước cho tốc độ nhanh
        snapshot = await FirebaseFirestore.instance.collection('animals').get(const GetOptions(source: Source.cache)) as QuerySnapshot<Map<String, dynamic>>;
        if (snapshot.docs.isEmpty) {
          // Nếu bộ nhớ đệm trống thì mới gọi tải dữ liệu thật từ Server
          snapshot = await FirebaseFirestore.instance.collection('animals').get(const GetOptions(source: Source.server)) as QuerySnapshot<Map<String, dynamic>>;
        }
      } catch (e) {
        snapshot = await FirebaseFirestore.instance.collection('animals').get(const GetOptions(source: Source.server)) as QuerySnapshot<Map<String, dynamic>>;
      }

      // Nếu tải được trên Firebase về, gộp nó vào cùng với danh sách Offline ở trên
      if (snapshot.docs.isNotEmpty) {
        List<Animal> onlineAnimals = snapshot.docs.map((doc) => Animal.fromMap(doc.data())).toList();
        combinedAnimals.addAll(onlineAnimals);
      }
    } catch (e) {
      debugPrint("Lỗi kết nối mạng, đang nạp dữ liệu Offline.");
    }

    combinedAnimals.shuffle(); // Xáo trộn ngẫu nhiên thứ tự các câu hỏi
    if (mounted) { // Hàm mounted kiểm tra xem màn hình này còn đang hiển thị không (tránh lỗi khi đang tải mà user thoát app)
      setState(() {
        questions = combinedAnimals; // Chốt danh sách câu hỏi
        isLoading = false;           // Tắt trạng thái Loading (vòng tròn quay)
        _initGame();                 // Bắt đầu setup câu hỏi số 1
      });
    }
  }

  // Hàm dispose: Chạy khi màn hình Game này bị đóng hoàn toàn
  @override
  void dispose() {
    _timer?.cancel();       // Phải hủy bộ đếm giờ (nếu không nó đếm ngầm gây lag máy)
    _audioPlayer.dispose(); // Phải hủy bộ phát âm thanh giải phóng bộ nhớ (Chống Memory Leak)
    super.dispose();
  }

  // --- HÀM BẮT ĐẦU ĐẾM NGƯỢC THỜI GIAN TỪ ĐẦU ---
  void _startTimer() {
    _timer?.cancel();
    if (widget.difficulty == Difficulty.easy) return; // Mức dễ không đếm giờ nên dừng hàm

    // Thiết lập số giây theo độ khó (Khó: 30s, Vừa: 45s)
    _timeLeft = widget.difficulty == Difficulty.hard ? 30 : 45;

    // Timer.periodic: Chạy một lệnh lặp đi lặp lại sau mỗi 1 giây
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) _timeLeft--; // Giảm 1 giây
        else { _timer?.cancel(); _onTimeOut(); } // Hết giờ thì hủy đếm và gọi hàm TimeOut (xử lý hết giờ)
      });
    });
  }

  // --- HÀM TIẾP TỤC ĐẾM GIỜ ---
  // (Dùng khi người chơi ấn Thoát nhưng lại chọn "Chơi tiếp" -> Đồng hồ chạy tiếp thay vì đếm lại từ đầu)
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

  // --- HÀM BẬT/TẮT ÂM THANH ---
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted; // Đảo ngược trạng thái Muted (Đang tắt thành bật, đang bật thành tắt)
      if (_isMuted) {
        _audioPlayer.stop(); // Nếu Tắt âm: Chặn ngay lập tức đoạn âm thanh đang phát dở
      } else {
        _playSound(questions[currentIndex].soundFile); // Nếu Bật âm: Phát lại tiếng con vật hiện tại
      }
    });
  }

  // --- HÀM PHÁT ÂM THANH ---
  void _playSound(String fileOrUrl) async {
    if (_isMuted) return; // Nếu trạng thái đang là Tắt tiếng thì không làm gì cả
    try {
      // Hỗ trợ cả 2 định dạng: Đường dẫn trên mạng (URL) hoặc đường dẫn nội bộ (Asset)
      if (fileOrUrl.startsWith('http') || fileOrUrl.startsWith('https')) {
        await _audioPlayer.play(UrlSource(fileOrUrl));
      } else {
        await _audioPlayer.play(AssetSource('sounds/$fileOrUrl'));
      }
    } catch (e) {
      debugPrint("Lỗi âm thanh: $e");
    }
  }

  // --- HÀM XÁC NHẬN KHI ẤN NÚT THOÁT ---
  void _confirmExit() {
    _timer?.cancel(); // Tạm dừng đồng hồ không cho đếm tiếp
    showDialog(
      context: context,
      barrierDismissible: false, // Ngăn người dùng chạm ra ngoài để đóng Dialog (Bắt buộc phải bấm 1 trong 2 nút)
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
              Navigator.pop(context); // Tắt Dialog
              _resumeTimer();         // Gọi đồng hồ chạy tiếp tục thời gian hiện tại
            },
            child: const Text("Chơi tiếp", style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context); // Tắt Dialog
              // Về lại màn hình chính StartScreen, xóa toàn bộ lịch sử điểm của lần chơi này
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StartScreen()));
            },
            child: const Text("Thoát luôn", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // --- HÀM NẠP CÂU HỎI LÊN GIAO DIỆN ---
  void _initGame() {
    setState(() {
      _isRevealed = false; // Reset lại trạng thái lật ảnh (Mức Khó: Ảnh lại bị mờ đi cho câu mới)
      Animal currentQ = questions[currentIndex];

      // Mức dễ chỉ hiện 2 nút (1 đúng, 1 sai) nên ta xóa bớt 2 đáp án sai đi
      if (widget.difficulty == Difficulty.easy) {
        List<String> wrongOptions = List.from(currentQ.options)..remove(currentQ.name);
        wrongOptions.shuffle();
        shuffledOptions = [currentQ.name, wrongOptions.first];
      } else {
        shuffledOptions = List.from(currentQ.options);
      }
      shuffledOptions.shuffle(); // Xáo trộn ngẫu nhiên vị trí các đáp án
    });
    _playSound(questions[currentIndex].soundFile); // Phát tiếng kêu
    _startTimer(); // Bắt đầu tính giờ 45s hoặc 30s
  }

  // --- QUYỀN TRỢ GIÚP 50/50 ---
  void _use5050() {
    if (is5050Used || widget.difficulty == Difficulty.easy) return;
    setState(() {
      is5050Used = true; // Đánh dấu đã dùng, không cho dùng lần 2
      String correctAnswer = questions[currentIndex].name;
      // Tìm các đáp án KHÁC đáp án đúng
      List<String> wrongOptions = shuffledOptions.where((opt) => opt != correctAnswer).toList();
      wrongOptions.shuffle();
      // Xóa 2 đáp án sai ngẫu nhiên khỏi danh sách hiển thị
      shuffledOptions.remove(wrongOptions[0]);
      shuffledOptions.remove(wrongOptions[1]);
    });
  }

  // --- QUYỀN TRỢ GIÚP ĐỔI CÂU ---
  void _useSkip() {
    if (isSkipUsed) return;
    setState(() { isSkipUsed = true; _timer?.cancel(); _nextQuestion(); });
  }

  // --- CHUYỂN SANG CÂU HỎI TIẾP THEO ---
  void _nextQuestion() {
    if (currentIndex < questions.length - 1) { // Kiểm tra nếu chưa phải câu cuối cùng
      setState(() { currentIndex++; _initGame(); }); // Tăng Index và nạp câu tiếp theo
    } else {
      _saveScoreAndFinish(); // Nếu đã hết danh sách câu hỏi -> Kết thúc game
    }
  }

  // --- LƯU ĐIỂM VÀO FIREBASE VÀ KẾT THÚC ---
  void _saveScoreAndFinish() async {
    _timer?.cancel();
    _playSound('correct.mp3'); // Tiếng chúc mừng kết thúc
    User? currentUser = FirebaseAuth.instance.currentUser; // Lấy thông tin user hiện hành

    // NẾU CHƯA ĐĂNG NHẬP GOOGLE: Hiện Dialog đề xuất đăng nhập để lưu điểm
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
            // Chọn Bỏ qua -> Trả về giá trị FALSE
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Bỏ qua", style: TextStyle(fontSize: 16, color: Colors.grey)),
            ),
            // Chọn Đăng nhập -> Trả về giá trị TRUE
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.g_mobiledata, size: 30),
              label: const Text("Đăng nhập"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            )
          ],
        ),
      );

      // Nếu bấm nút đồng ý đăng nhập
      if (wantToLogin == true) {
        try {
          // Gọi hộp thoại đăng nhập của Google
          final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
          if (googleUser != null) {
            final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
            final OAuthCredential credential = GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            );
            await FirebaseAuth.instance.signInWithCredential(credential); // Đẩy qua Firebase
            currentUser = FirebaseAuth.instance.currentUser; // Gán lại biến currentUser
          }
        } catch (e) {
          debugPrint("Lỗi đăng nhập: $e");
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng nhập thất bại, không thể lưu điểm!')));
        }
      }
    }

    // NẾU CÓ TÀI KHOẢN (Đã đăng nhập trước đó hoặc vừa đăng nhập xong) -> Đẩy điểm
    if (currentUser != null) {
      // Gắn kèm mức độ khó phía sau tên (VD: Tuấn Anh (Khó))
      String diffString = widget.difficulty == Difficulty.easy ? "(Dễ)" : (widget.difficulty == Difficulty.medium ? "(Vừa)" : "(Khó)");
      String finalName = widget.playerName;

      try {
        // Hàm này đẩy 1 Document vào bảng 'leaderboard' trên Firestore
        await FirebaseFirestore.instance.collection('leaderboard').add({
          'name': '$finalName $diffString',
          'score': currentStars,
          'timestamp': FieldValue.serverTimestamp(), // serverTimestamp giúp lấy thời gian thật của máy chủ (chống hack chỉnh giờ trên điện thoại)
        });
      } catch (e) {
        debugPrint("Lỗi đẩy điểm lên Firebase: $e");
      }
    }

    // Cuối cùng: Chuyển sang màn hình Mừng chiến thắng (VictoryScreen)
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

  // --- HÀM XỬ LÝ KHI THỜI GIAN CHẠY VỀ 0 ---
  void _onTimeOut() {
    _playSound('wrong.mp3');
    // Truyền tham số isTimeout = true để xử lý riêng
    _handleWrongAnswer("Hết giờ rồi!", "Đáp án đúng là ${questions[currentIndex].name}.", isTimeout: true);
  }

  // --- HÀM XỬ LÝ KHI NGƯỜI CHƠI BẤM CHỌN 1 ĐÁP ÁN ---
  void _onOptionSelected(String selectedOption) {
    _timer?.cancel(); // Dừng ngay đồng hồ
    if (selectedOption == questions[currentIndex].name) { // So sánh tên nút bấm và tên thật của con vật
      _playSound('correct.mp3');
      setState(() {
        currentStars++;     // Cộng 1 sao
        _isRevealed = true; // HIỆU ỨNG LẬT ẢNH MỜ (Đổi true thì giao diện phía dưới sẽ gỡ bỏ bộ lọc mờ đi)
      });
      _showDialog("Tuyệt vời!", "Bé đoán đúng rồi! 🌟", Colors.green, isCorrect: true);
    } else {
      _playSound('wrong.mp3');
      _handleWrongAnswer("Chưa đúng!", "Bé thử lại nhé! 💪", isTimeout: false);
    }
  }

  // --- HÀM XỬ LÝ KHI TRẢ LỜI SAI (TRỪ MẠNG) ---
  void _handleWrongAnswer(String title, String content, {required bool isTimeout}) {
    if (widget.difficulty == Difficulty.easy) { // Mức dễ không bị trừ mạng
      _showDialog(title, content, Colors.redAccent, isCorrect: false, isTimeout: isTimeout);
    } else {
      setState(() { _lives--; }); // Trừ 1 mạng (1 trái tim)

      if (_lives <= 0) { // Nếu số mạng về 0
        _showGameOverDialog();
      } else { // Vẫn còn mạng
        _showDialog(title, "$content\nBé còn $_lives mạng nhé!", Colors.orange, isCorrect: false, isTimeout: isTimeout);
      }
    }
  }

  // Bật bảng thông báo Hết mạng
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
              Navigator.pop(context); // Tắt Dialog
              _saveScoreAndFinish();  // Trực tiếp gọi hàm Lưu Điểm và thoát
            },
            child: const Text("Xem điểm", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // Bật bảng thông báo Đúng/Sai chung
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
              Navigator.pop(context); // Tắt bảng thông báo
              if (isCorrect || isTimeout) _nextQuestion(); // Nếu đúng hoặc Hết giờ thì Chuyển câu
              else { _playSound(questions[currentIndex].soundFile); _startTimer(); } // Nếu Sai nhưng CÒN MẠNG -> Phải gọi lại âm thanh và Bật lại đồng hồ từ đầu (để cho trả lời lại câu hiện tại)
            },
            child: Text(isCorrect || isTimeout ? "Tiếp tục" : "Thử lại", style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // ===============================================
  // ===== GIAO DIỆN (UI) CỦA MÀN HÌNH CHƠI ========
  // ===============================================
  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));

    Animal currentQuestion = questions[currentIndex];
    bool isHardMode = widget.difficulty == Difficulty.hard;

    // Tự động tính chiều rộng nút: Dễ thì full chiều dài, Vừa/Khó thì chia màn hình làm đôi trừ đi viền
    double buttonWidth = widget.difficulty == Difficulty.easy
        ? double.infinity
        : (MediaQuery.of(context).size.width - 50) / 2;

    // WillPopScope: Widget chuyên dùng để đánh chặn nút Back vật lý trên điện thoại Android
    return WillPopScope(
      onWillPop: () async {
        _confirmExit(); // Hiện bảng hỏi chứ không cho thoát ngay
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF89CFF0), Color(0xFFE6E6FA)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
          ),
          child: SafeArea(
            // Khối lệnh này sẽ tính toán, nếu màn hình đủ dài nó đứng yên, nếu thiết bị quá ngắn nó biến thành dạng Scroll (Cuộn) được.
            child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [

                            // ---- KHU VỰC 1: THANH TRẠNG THÁI PHÍA TRÊN ----
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Bên Trái: Expanded ép khối này không lấn sang đồng hồ
                                  Expanded(
                                    child: Row(
                                      children: [
                                        // Nút X thoát Game
                                        IconButton(
                                          icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 32),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: _confirmExit,
                                        ),
                                        const SizedBox(width: 8),
                                        // Nút Bật/Tắt Loa
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
                                        // Cụm hiển thị Tên và Mạng (Trái tim)
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Bé: ${widget.playerName}",
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                                                overflow: TextOverflow.ellipsis, // Cắt thành "..." nếu tên dài quá
                                              ),
                                              // Vẽ Mạng (Chỉ mức Khó/Vừa mới hiện)
                                              if (widget.difficulty != Difficulty.easy)
                                                Wrap( // Dùng Wrap thay vì Row để nếu dài quá trái tim tự xuống dòng
                                                  children: List.generate(
                                                    widget.difficulty == Difficulty.medium ? 5 : 3, // Số tim max
                                                        (index) => Icon(
                                                      index < _lives ? Icons.favorite : Icons.favorite_border, // _lives còn bao nhiêu thì tim đặc màu đỏ, mất thì tim viền
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

                                  // Bên Phải: Hiển thị Giây và Số sao đạt được
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.difficulty != Difficulty.easy)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          // Giây đếm <= 3 thì ô nền tự động nhấp nháy Đỏ chữ Trắng báo động
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

                            // ---- KHU VỰC 2: CÂU HỎI HIỆN TẠI ĐANG CHƠI ----
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

                            // ---- KHU VỰC 3: HÌNH ẢNH CON VẬT TRUNG TÂM ----
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
                                    // GestureDetector để nhận diện thao tác chạm (Bấm vào cái hộp chứa ảnh thì phát tiếng)
                                    GestureDetector(
                                      onTap: () => _playSound(currentQuestion.soundFile),
                                      child: Container(
                                        height: 180, width: 240,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(24),
                                            border: Border.all(color: Colors.white, width: 8)
                                        ),
                                        child: ClipRRect( // ClipRRect giúp bo góc bức ảnh vừa vặn với cái khung Container viền trắng
                                          borderRadius: BorderRadius.circular(16),
                                          child: Builder(
                                              builder: (context) {
                                                // Kiểm tra ảnh là đường dẫn Mạng (http) hay trong Máy (assets) để load thư viện tương ứng
                                                Widget animalImage = currentQuestion.imageUrl.startsWith('http')
                                                    ? CachedNetworkImage( // Dùng CachedNetworkImage để lấy ảnh trên mạng và lưu vào cache chống giật
                                                  imageUrl: currentQuestion.imageUrl, fit: BoxFit.cover,
                                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                                                )
                                                    : Image.asset(currentQuestion.imageUrl, fit: BoxFit.cover);

                                                // LÀM MỜ ẢNH Ở MỨC KHÓ:
                                                // Nếu là mức Hard VÀ _isRevealed = false (chưa đoán đúng)
                                                // Thì bọc Widget animalImage vào trong ImageFiltered. Ngược lại hiển thị ảnh gốc.
                                                return (isHardMode && !_isRevealed)
                                                    ? ImageFiltered(
                                                  imageFilter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0), // Chỉ số sigma chỉnh độ mờ
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

                            // ---- KHU VỰC 4: NÚT QUYỀN TRỢ GIÚP (50/50 VÀ ĐỔI CÂU) ----
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Nếu đang chơi Mức dễ thì Không xuất hiện nút trợ giúp 50/50
                                  if (widget.difficulty != Difficulty.easy) ...[
                                    // Nếu đã dùng quyền thì hàm onPressed gán bằng null (Nút tự động bị vô hiệu hóa / màu xám)
                                    ElevatedButton.icon(onPressed: is5050Used ? null : _use5050, icon: const Icon(Icons.star_half_rounded), label: const Text("50/50")),
                                    const SizedBox(width: 15),
                                  ],
                                  ElevatedButton.icon(onPressed: isSkipUsed ? null : _useSkip, icon: const Icon(Icons.skip_next_rounded), label: const Text("Đổi câu")),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),

                            // ---- KHU VỰC 5: CÁC NÚT ĐÁP ÁN (DƯỚI CÙNG MÀN HÌNH) ----
                            Container(
                              width: double.infinity, padding: const EdgeInsets.all(15),
                              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                              // Wrap giúp các nút tự động rớt xuống dòng nếu tổng chiều ngang dài quá màn hình
                              child: Wrap(
                                spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
                                // Vòng lặp map: Lấy từng chữ trong mảng shuffledOptions biến thành 1 Nút ElevatedButton
                                children: shuffledOptions.map((opt) => SizedBox(
                                  width: buttonWidth, height: 60, // Kích thước này đã chia tỷ lệ ở ngay đầu khối Build
                                  child: ElevatedButton(
                                      onPressed: () => _onOptionSelected(opt), // Truyền chữ đã chọn vào hàm kiểm tra
                                      child: Text(opt, style: const TextStyle(fontSize: 18), textAlign: TextAlign.center)
                                  ),
                                )).toList(), // Tích hợp danh sách Nút lại thành mảng hiển thị
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