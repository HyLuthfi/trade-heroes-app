import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class AppState extends ChangeNotifier {
  int _petir = 5;
  int _xp = 0;
  int _dailyXp = 0;
  int _streak = 0;
  List<int> _completedLevels = [1, 2, 3];
  List<int> _readModules = [];
  List<Map<String, dynamic>> _favorites = []; // { 'levelId': int, 'qIndex': int, 'questionText': String }
  List<String> _unlockedBadges = [];
  List<int> _claimedChests = []; // Level IDs of claimed milestone chests
  List<int> _claimedDailyDays = []; // Days claimed in current week (1-7)
  String _lastDailyClaimDate = ""; // YYYY-MM-DD
  bool _isPremium = false;
  bool _isLoggedIn = true;
  String _lastActiveDate = ""; // YYYY-MM-DD
  int? _petirLastUsedTime; // timestamp in ms

  String _userName = "Calon Trader";
  String _userEmail = "user@kursussaham.com";
  String _userAvatar = "bull";

  // Getters
  int get petir => _isPremium ? 999999 : _petir;
  int get xp => _xp;
  int get dailyXp => _dailyXp;
  int get streak => _streak;
  List<int> get completedLevels => _completedLevels;
  List<int> get readModules => _readModules;
  List<Map<String, dynamic>> get favorites => _favorites;
  List<String> get unlockedBadges => _unlockedBadges;
  List<int> get claimedChests => _claimedChests;
  List<int> get claimedDailyDays => _claimedDailyDays;
  String get lastDailyClaimDate => _lastDailyClaimDate;
  bool get isPremium => _isPremium;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userAvatar => _userAvatar;

  Timer? _regenTimer;

  AppState() {
    _loadState();
    _startRegenTimer();
  }

  // File Path for Local JSON Storage
  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/state.json');
  }

  // Load state from local storage
  Future<void> _loadState() async {
    try {
      final file = await _getLocalFile();
      if (await file.exists()) {
        final contents = await file.readAsString();
        final json = jsonDecode(contents);

        _petir = json['petir'] ?? 5;
        _xp = json['xp'] ?? 0;
        _dailyXp = json['dailyXp'] ?? 0;
        _streak = json['streak'] ?? 0;
        _completedLevels = List<int>.from(json['completedLevels'] ?? [1, 2, 3]);
        if (_completedLevels.isEmpty) {
          _completedLevels = [1, 2, 3];
        }
        _readModules = List<int>.from(json['readModules'] ?? []);
        _favorites = List<Map<String, dynamic>>.from(json['favorites'] ?? []);
        _unlockedBadges = List<String>.from(json['unlockedBadges'] ?? []);
        _claimedChests = List<int>.from(json['claimedChests'] ?? []);
        _claimedDailyDays = List<int>.from(json['claimedDailyDays'] ?? []);
        _lastDailyClaimDate = json['lastDailyClaimDate'] ?? "";
        _isPremium = json['isPremium'] ?? false;
        _isLoggedIn = json['isLoggedIn'] ?? true;
        _lastActiveDate = json['lastActiveDate'] ?? "";
        _petirLastUsedTime = json['petirLastUsedTime'];
        _userName = json['userName'] ?? "Calon Trader";
        _userEmail = json['userEmail'] ?? "user@kursussaham.com";
        _userAvatar = json['userAvatar'] ?? "bull";
        
        _checkDailyReset();
        _checkPetirRegenOnLoad();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading state: $e");
    }
  }

  // Save state to local storage
  Future<void> _saveState() async {
    try {
      final file = await _getLocalFile();
      final data = {
        'petir': _petir,
        'xp': _xp,
        'dailyXp': _dailyXp,
        'streak': _streak,
        'completedLevels': _completedLevels,
        'readModules': _readModules,
        'favorites': _favorites,
        'unlockedBadges': _unlockedBadges,
        'claimedChests': _claimedChests,
        'claimedDailyDays': _claimedDailyDays,
        'lastDailyClaimDate': _lastDailyClaimDate,
        'isPremium': _isPremium,
        'isLoggedIn': _isLoggedIn,
        'lastActiveDate': _lastActiveDate,
        'petirLastUsedTime': _petirLastUsedTime,
        'userName': _userName,
        'userEmail': _userEmail,
        'userAvatar': _userAvatar,
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint("Error saving state: $e");
    }
  }

  // Daily Reward Claim Handler
  bool get canClaimDailyToday {
    final todayStr = DateTime.now().toString().split(' ')[0];
    return _lastDailyClaimDate != todayStr;
  }

  void claimDailyReward(int day, {required int xpReward, required int petirReward}) {
    final todayStr = DateTime.now().toString().split(' ')[0];
    if (!_claimedDailyDays.contains(day)) {
      _claimedDailyDays.add(day);
    }
    if (_claimedDailyDays.length > 7) {
      _claimedDailyDays = [day];
    }
    _lastDailyClaimDate = todayStr;
    _xp += xpReward;
    _dailyXp += xpReward;
    if (!_isPremium) {
      _petir = (_petir + petirReward).clamp(0, 5);
    }
    _saveState();
    notifyListeners();
  }

  // Login & Logout Handlers
  void login({required String name, required String email, String avatar = "bull"}) {
    _isLoggedIn = true;
    _userName = name;
    _userEmail = email;
    _userAvatar = avatar;
    _saveState();
    notifyListeners();
  }

  void updateAvatar(String newAvatar) {
    _userAvatar = newAvatar;
    _saveState();
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _saveState();
    notifyListeners();
  }

  bool isChestClaimed(int chestLevelId) {
    return _claimedChests.contains(chestLevelId);
  }

  void claimChest(int chestLevelId, int xpReward, BuildContext context) {
    if (!_claimedChests.contains(chestLevelId)) {
      _claimedChests.add(chestLevelId);
      addXp(xpReward, context);
      _saveState();
      notifyListeners();
    }
  }

  void _checkDailyReset() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (_lastActiveDate != today) {
      if (_lastActiveDate.isNotEmpty) {
        final lastDate = DateTime.parse(_lastActiveDate);
        final diffDays = DateTime.now().difference(lastDate).inDays;
        
        if (diffDays == 1) {
          _streak += 1;
        } else if (diffDays > 1) {
          _streak = 1;
        }
      } else {
        _streak = 1;
      }
      _dailyXp = 0;
      _lastActiveDate = today;
      _saveState();
    }
  }

  void _checkPetirRegenOnLoad() {
    if (_isPremium || _petir >= 5 || _petirLastUsedTime == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedMs = now - _petirLastUsedTime!;
    const regenMs = 60000; // 1 Menit per petir untuk demo

    final earnedLives = elapsedMs ~/ regenMs;
    if (earnedLives > 0) {
      _petir = (_petir + earnedLives).clamp(0, 5);
      if (_petir >= 5) {
        _petirLastUsedTime = null;
      } else {
        _petirLastUsedTime = _petirLastUsedTime! + (earnedLives * regenMs);
      }
      _saveState();
    }
  }

  void _startRegenTimer() {
    _regenTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPremium || _petir >= 5) {
        _petirLastUsedTime = null;
        return;
      }

      if (_petirLastUsedTime == null) {
        _petirLastUsedTime = DateTime.now().millisecondsSinceEpoch;
        _saveState();
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsedMs = now - _petirLastUsedTime!;
      const regenMs = 60000;

      if (elapsedMs >= regenMs) {
        _petir = (_petir + 1).clamp(0, 5);
        if (_petir >= 5) {
          _petirLastUsedTime = null;
        } else {
          _petirLastUsedTime = now;
        }
        _saveState();
        notifyListeners();
      }
    });
  }

  // Get countdown string for petir recovery
  String getPetirRegenTime() {
    if (_isPremium || _petir >= 5 || _petirLastUsedTime == null) return "";
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedMs = now - _petirLastUsedTime!;
    final remainingMs = 60000 - elapsedMs;
    if (remainingMs <= 0) return "";
    
    final remainingSec = (remainingMs / 1000).ceil();
    return "${remainingSec}s";
  }

  // Deduct 1 petir on wrong answer
  bool deductPetir() {
    if (_isPremium) return true;
    if (_petir > 0) {
      if (_petir == 5) {
        _petirLastUsedTime = DateTime.now().millisecondsSinceEpoch;
      }
      _petir -= 1;
      _saveState();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Refill 1 petir (e.g. from watching ad)
  void refillOnePetir() {
    if (_petir < 5) {
      _petir += 1;
      if (_petir >= 5) {
        _petirLastUsedTime = null;
      } else {
        _petirLastUsedTime = DateTime.now().millisecondsSinceEpoch;
      }
      _saveState();
      notifyListeners();
    }
  }

  // Add XP and notify listeners
  void addXp(int amount, BuildContext context) {
    _xp += amount;
    _dailyXp += amount;
    _saveState();
    notifyListeners();
    _checkAndUnlockBadges(context);
  }

  // Update profile details
  void updateProfile({required String name, required String email, required String avatar}) {
    _userName = name;
    _userEmail = email;
    _userAvatar = avatar;
    _saveState();
    notifyListeners();
  }

  // Upgrade to premium plan
  void upgradeToPremium(BuildContext context) {
    _isPremium = true;
    _saveState();
    notifyListeners();
    _checkAndUnlockBadges(context);
  }

  // Toggle favorite kuis question
  void toggleFavorite(int levelId, int qIndex, String questionText) {
    final idx = _favorites.indexWhere((f) => f['levelId'] == levelId && f['qIndex'] == qIndex);
    if (idx > -1) {
      _favorites.removeAt(idx);
    } else {
      _favorites.add({
        'levelId': levelId,
        'qIndex': qIndex,
        'questionText': questionText,
      });
    }
    _saveState();
    notifyListeners();
  }

  bool isFavorited(int levelId, int qIndex) {
    return _favorites.any((f) => f['levelId'] == levelId && f['qIndex'] == qIndex);
  }

  // Complete module
  void completeModule(int moduleId, int xpReward, BuildContext context) {
    if (!_readModules.contains(moduleId)) {
      _readModules.add(moduleId);
      addXp(xpReward, context);
      _saveState();
      notifyListeners();
    }
  }

  // Level completed
  void completeLevel(int levelId) {
    if (!_completedLevels.contains(levelId)) {
      _completedLevels.add(levelId);
      _saveState();
      notifyListeners();
    }
  }

  // Award Anti Boncos if no mistakes
  void unlockAntiBoncos(BuildContext context) {
    if (!_unlockedBadges.contains("anti_boncos")) {
      _unlockedBadges.add("anti_boncos");
      _saveState();
      _triggerBadgeModal("anti_boncos", context);
      notifyListeners();
    }
  }

  // Badge Unlock logic
  void _checkAndUnlockBadges(BuildContext context) {
    List<String> newlyUnlocked = [];

    if (_completedLevels.isNotEmpty && !_unlockedBadges.contains("saham_pemula")) {
      newlyUnlocked.add("saham_pemula");
    }
    if (_streak >= 3 && !_unlockedBadges.contains("investor_setia")) {
      newlyUnlocked.add("investor_setia");
    }
    if (_favorites.length >= 3 && !_unlockedBadges.contains("kolektor_ilmu")) {
      newlyUnlocked.add("kolektor_ilmu");
    }
    if (_isPremium && !_unlockedBadges.contains("premium_member")) {
      newlyUnlocked.add("premium_member");
    }
    if (_completedLevels.length == 10 && !_unlockedBadges.contains("pakar_saham")) {
      newlyUnlocked.add("pakar_saham");
    }

    if (newlyUnlocked.isNotEmpty) {
      for (var badgeId in newlyUnlocked) {
        _unlockedBadges.add(badgeId);
        _triggerBadgeModal(badgeId, context);
      }
      _saveState();
      notifyListeners();
    }
  }

  void _triggerBadgeModal(String badgeId, BuildContext context) {
    final badgeName = _getBadgeName(badgeId);
    final badgeIcon = _getBadgeIcon(badgeId);
    final badgeDesc = _getBadgeDesc(badgeId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff131a26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xfff59e0b), width: 3),
                gradient: RadialGradient(
                  colors: [const Color(0xfff59e0b).withOpacity(0.2), const Color(0xff131a26)],
                ),
              ),
              alignment: Alignment.center,
              child: Text(badgeIcon, style: const TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 16),
            const Text(
              "Medali Didapatkan!",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xfff59e0b),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badgeName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              badgeDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xff9ca3af)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff10b981),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("HEBAT!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  String _getBadgeName(String id) {
    switch (id) {
      case "saham_pemula": return "Saham Pemula";
      case "anti_boncos": return "Anti Boncos";
      case "investor_setia": return "Investor Setia";
      case "kolektor_ilmu": return "Kolektor Ilmu";
      case "premium_member": return "Premium Member";
      case "pakar_saham": return "Pakar Saham";
      default: return "";
    }
  }

  String _getBadgeIcon(String id) {
    switch (id) {
      case "saham_pemula": return "🌱";
      case "anti_boncos": return "🛡️";
      case "investor_setia": return "🔥";
      case "kolektor_ilmu": return "📚";
      case "premium_member": return "👑";
      case "pakar_saham": return "🎓";
      default: return "🏆";
    }
  }

  String _getBadgeDesc(String id) {
    switch (id) {
      case "saham_pemula": return "Menyelesaikan kuis pertama Anda.";
      case "anti_boncos": return "Menjawab kuis 100% benar tanpa salah nyawa.";
      case "investor_setia": return "Memiliki streak belajar minimal 3 hari.";
      case "kolektor_ilmu": return "Menyimpan minimal 3 soal ke daftar favorit.";
      case "premium_member": return "Upgrade akun Anda ke Premium Plan.";
      case "pakar_saham": return "Menyelesaikan seluruh 10 level Trade Heroes.";
      default: return "";
    }
  }

  @override
  void dispose() {
    _regenTimer?.cancel();
    super.dispose();
  }
}
