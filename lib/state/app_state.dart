import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/audio_service.dart';
import '../services/supabase_service.dart';

class AppState extends ChangeNotifier {
  int _petir = 5;
  int _xp = 0; // Total XP Seumur Hidup (Tunggal & Permanen)
  int _dailyXp = 0;
  int _streak = 0;
  List<int> _completedLevels = [1, 2, 3];
  Map<int, int> _levelStars = {1: 3, 2: 3, 3: 3}; // levelId -> stars (1, 2, or 3) Candy Crush style
  List<int> _readModules = [];
  List<Map<String, dynamic>> _favorites = []; // { 'levelId': int, 'qIndex': int, 'questionText': String }
  List<String> _unlockedBadges = [];
  List<int> _claimedChests = []; // Level IDs of claimed milestone chests
  List<int> _claimedDailyDays = []; // Days claimed in current week (1-7)
  String _lastDailyClaimDate = ""; // YYYY-MM-DD
  bool _isPremium = false;
  bool _isLoggedIn = false;
  bool _isAuthLoading = true;
  String _lastActiveDate = ""; // YYYY-MM-DD
  int? _petirLastUsedTime; // timestamp in ms

  // XP Milestones Reward Track
  int _streakShields = 0; // Streak protections
  List<String> _unlockedAvatars = ["bull", "chart", "wallet"];
  List<int> _claimedXpMilestones = []; // List of claimed milestone target XPs: [50, 100, 200, ...]
  String _lastDailyGoalClaimDate = ""; // YYYY-MM-DD when daily target bonus was claimed

  String _userName = "Calon Trader";
  String _userEmail = "user@kursussaham.com";
  String _userAvatar = "bull";
  String? _userId;
  String _role = "user";

  // Paper Trading Simulator State
  double _virtualBalance = 100000000.0; // Default 100 Juta Rupiah
  List<Map<String, dynamic>> _portfolio = []; // [{ 'ticker': 'BBCA', 'lots': 10, 'totalShares': 1000, 'avgPrice': 10250.0 }]
  List<Map<String, dynamic>> _tradeHistory = []; // [{ 'ticker': 'BBCA', 'type': 'BUY', 'lots': 10, 'price': 10250.0, ... }]

  // Preferences
  bool _darkMode = true;
  bool _dailyReminder = true;
  bool _soundHaptic = true;
  bool _bgmEnabled = false;
  String _language = "id";
  String _bgmTrack = "default";

  // Getters
  int get petir => _isPremium ? 999999 : _petir;
  int get xp => _xp;
  int get totalXp => _xp;
  int get dailyXp => _dailyXp;
  int get streak => _streak;
  List<int> get completedLevels => _completedLevels;
  Map<int, int> get levelStars => _levelStars;

  int getStarsForLevel(int levelId) => _levelStars[levelId] ?? 0;
  List<int> get readModules => _readModules;
  List<Map<String, dynamic>> get favorites => _favorites;
  List<String> get unlockedBadges => _unlockedBadges;
  List<int> get claimedChests => _claimedChests;
  List<int> get claimedDailyDays => _claimedDailyDays;
  String get lastDailyClaimDate => _lastDailyClaimDate;
  bool get isPremium => _isPremium;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAuthLoading => _isAuthLoading;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userAvatar => _userAvatar;
  String? get userId => _userId;
  String get role => _role;
  bool get isAdmin => _role == 'admin' || _userEmail == 'luthfirg2502@gmail.com';
  bool get isCloudSynced => SupabaseService.isAuthenticated;
  bool get darkMode => _darkMode;
  bool get dailyReminder => _dailyReminder;
  bool get soundHaptic => _soundHaptic;
  bool get bgmEnabled => _bgmEnabled;
  String get language => _language;
  String get bgmTrack => _bgmTrack;

  // XP Milestones Reward Track Getters
  int get streakShields => _streakShields;
  List<String> get unlockedAvatars => _unlockedAvatars;
  List<int> get claimedXpMilestones => _claimedXpMilestones;
  String get lastDailyGoalClaimDate => _lastDailyGoalClaimDate;

  bool get isDailyGoalReached => _dailyXp >= 50;
  bool get canClaimDailyGoalBonus {
    final todayStr = DateTime.now().toString().split(' ')[0];
    return isDailyGoalReached && _lastDailyGoalClaimDate != todayStr;
  }
  bool get isDailyGoalClaimedToday {
    final todayStr = DateTime.now().toString().split(' ')[0];
    return _lastDailyGoalClaimDate == todayStr;
  }

  bool claimDailyGoalBonus(BuildContext context) {
    if (!canClaimDailyGoalBonus) return false;
    final todayStr = DateTime.now().toString().split(' ')[0];
    _lastDailyGoalClaimDate = todayStr;
    // Hadiah bonus target harian: +15 Bonus XP & +1 Nyawa Petir
    _xp += 15;
    if (!_isPremium) {
      _petir = (_petir + 1).clamp(0, 5);
      if (_petir >= 5) _petirLastUsedTime = null;
    }
    AudioService.playReward();
    _saveState();
    notifyListeners();
    _checkAndUnlockBadges(context);
    return true;
  }

  // Definisi Jalur Hadiah Milestone XP (Tunggal & Gratis)
  static const List<Map<String, dynamic>> xpMilestoneRewards = [
    {
      'targetXp': 50,
      'title': '+2 Nyawa Petir',
      'desc': 'Bantuan petir instan untuk terus belajar.',
      'type': 'petir',
      'value': 2,
      'icon': Icons.bolt_rounded,
      'color': Color(0xff10b981),
    },
    {
      'targetXp': 100,
      'title': 'Pelindung Streak',
      'desc': 'Proteksi 1 hari agar streak belajarmu tidak hangus.',
      'type': 'shield',
      'value': 1,
      'icon': Icons.security_rounded,
      'color': Color(0xff3b82f6),
    },
    {
      'targetXp': 200,
      'title': 'Avatar Breakout Trader',
      'desc': 'Buka avatar eksklusif momentum penembusan harga.',
      'type': 'avatar',
      'value': 'rocket',
      'icon': Icons.rocket_launch_rounded,
      'color': Color(0xff38bdf8),
    },
    {
      'targetXp': 350,
      'title': 'Full Refill 5 Petir',
      'desc': 'Isi penuh seluruh energi petir seketika.',
      'type': 'full_petir',
      'value': 5,
      'icon': Icons.flash_on_rounded,
      'color': Color(0xfff59e0b),
    },
    {
      'targetXp': 500,
      'title': '+2 Pelindung Streak',
      'desc': 'Simpanan proteksi ekstra untuk menjaga konsistensi.',
      'type': 'shield',
      'value': 2,
      'icon': Icons.verified_user_rounded,
      'color': Color(0xff14b8a6),
    },
    {
      'targetXp': 750,
      'title': 'Avatar Scalper Sejati',
      'desc': 'Buka avatar eksklusif pembaca volatilitas cepat.',
      'type': 'avatar',
      'value': 'fire',
      'icon': Icons.local_fire_department_rounded,
      'color': Color(0xffef4444),
    },
    {
      'targetXp': 1000,
      'title': 'Avatar Market Legend',
      'desc': 'Buka avatar legendaris bintang pasar modal.',
      'type': 'avatar',
      'value': 'star',
      'icon': Icons.stars_rounded,
      'color': Color(0xfffbbf24),
    },
    {
      'targetXp': 1500,
      'title': 'Avatar Grand Master',
      'desc': 'Buka avatar kehormatan tertinggi akademi.',
      'type': 'avatar',
      'value': 'academy',
      'icon': Icons.school_rounded,
      'color': Color(0xffec4899),
    },
  ];

  bool isMilestoneClaimed(int targetXp) => _claimedXpMilestones.contains(targetXp);
  bool canClaimMilestone(int targetXp) => _xp >= targetXp && !isMilestoneClaimed(targetXp);

  int get unclaimedMilestonesCount {
    int count = 0;
    for (final m in xpMilestoneRewards) {
      if (canClaimMilestone(m['targetXp'] as int)) count++;
    }
    return count;
  }

  bool claimXpMilestone(int targetXp) {
    if (!canClaimMilestone(targetXp)) return false;
    final milestone = xpMilestoneRewards.firstWhere((m) => m['targetXp'] == targetXp);
    final type = milestone['type'] as String;

    if (type == 'petir') {
      final add = milestone['value'] as int;
      _petir = (_petir + add).clamp(0, 5);
      if (_petir >= 5) _petirLastUsedTime = null;
    } else if (type == 'full_petir') {
      _petir = 5;
      _petirLastUsedTime = null;
    } else if (type == 'shield') {
      final add = milestone['value'] as int;
      _streakShields = (_streakShields + add).clamp(0, 5);
    } else if (type == 'avatar') {
      final avaId = milestone['value'] as String;
      if (!_unlockedAvatars.contains(avaId)) {
        _unlockedAvatars.add(avaId);
      }
    }

    _claimedXpMilestones.add(targetXp);
    AudioService.playReward();
    _saveState();
    notifyListeners();
    return true;
  }

  bool isAvatarUnlocked(String id) {
    if (id == 'vip') return _isPremium;
    return _unlockedAvatars.contains(id);
  }

  // Leaderboard State (Stage 3)
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoadingLeaderboard = false;

  List<Map<String, dynamic>> get leaderboard => _leaderboard;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;

  int get userLeaderboardRank {
    if (_leaderboard.isEmpty) return 1;
    final myId = _userId;
    for (int i = 0; i < _leaderboard.length; i++) {
      final item = _leaderboard[i];
      if ((myId != null && item['id'] == myId) || item['email'] == _userEmail || item['isCurrentUser'] == true) {
        return i + 1;
      }
    }
    // If not found in top list, estimate based on XP
    for (int i = 0; i < _leaderboard.length; i++) {
      final itemXp = (_leaderboard[i]['xp'] as num?)?.toInt() ?? 0;
      if (_xp >= itemXp) return i + 1;
    }
    return _leaderboard.length + 1;
  }

  Future<void> loadLeaderboard({bool force = false}) async {
    if (!force && _leaderboard.isNotEmpty) return;
    _isLoadingLeaderboard = true;
    notifyListeners();

    try {
      final cloudProfiles = await SupabaseService.fetchLeaderboard(limit: 20);
      final List<Map<String, dynamic>> list = [];

      final communityTraders = [
        {'id': 'c1', 'name': 'Pratama Trader', 'email': 'pratama@bei.co', 'avatar': 'chart', 'xp': 1850, 'streak': 14, 'role': 'user'},
        {'id': 'c2', 'name': 'Siti Khadijah', 'email': 'siti@invest.id', 'avatar': 'star', 'xp': 1420, 'streak': 9, 'role': 'user'},
        {'id': 'c3', 'name': 'Budi Santoso', 'email': 'budi@trader.com', 'avatar': 'bull', 'xp': 960, 'streak': 7, 'role': 'user'},
        {'id': 'c4', 'name': 'Rian Perkasa', 'email': 'rian@scalp.id', 'avatar': 'fire', 'xp': 680, 'streak': 5, 'role': 'user'},
        {'id': 'c5', 'name': 'Dewi Lestari', 'email': 'dewi@cuan.com', 'avatar': 'shield', 'xp': 420, 'streak': 4, 'role': 'user'},
        {'id': 'c6', 'name': 'Arif Wibowo', 'email': 'arif@sahambei.id', 'avatar': 'rocket', 'xp': 230, 'streak': 3, 'role': 'user'},
        {'id': 'c7', 'name': 'Nadia Putri', 'email': 'nadia@investor.id', 'avatar': 'academy', 'xp': 110, 'streak': 2, 'role': 'user'},
      ];

      // Add real profiles
      final Set<String> addedEmails = {};
      for (final p in cloudProfiles) {
        final email = p['email']?.toString() ?? '';
        if (email.isNotEmpty) addedEmails.add(email);
        final bool isMe = (p['id'] == _userId) || (email == _userEmail);
        list.add({
          'id': p['id'] ?? 'user',
          'name': isMe ? _userName : (p['name'] ?? 'Trader'),
          'email': email,
          'avatar': isMe ? _userAvatar : (p['avatar'] ?? 'bull'),
          'xp': isMe ? _xp : ((p['xp'] as num?)?.toInt() ?? 0),
          'streak': isMe ? _streak : ((p['streak'] as num?)?.toInt() ?? 1),
          'role': p['role'] ?? 'user',
          'isCurrentUser': isMe,
        });
      }

      // If current user is not in the list yet, insert current user
      if (!list.any((item) => item['isCurrentUser'] == true)) {
        list.add({
          'id': _userId ?? 'me',
          'name': _userName,
          'email': _userEmail,
          'avatar': _userAvatar,
          'xp': _xp,
          'streak': _streak,
          'role': _role,
          'isCurrentUser': true,
        });
      }

      // Blend community mock traders if total real count < 8
      for (final mock in communityTraders) {
        if (!addedEmails.contains(mock['email']) && list.length < 15) {
          list.add(Map<String, dynamic>.from(mock));
        }
      }

      // Sort strictly by XP descending
      list.sort((a, b) {
        final xpA = (a['xp'] as num?)?.toInt() ?? 0;
        final xpB = (b['xp'] as num?)?.toInt() ?? 0;
        return xpB.compareTo(xpA);
      });

      _leaderboard = list;
    } catch (e) {
      debugPrint("Error loading leaderboard: $e");
    } finally {
      _isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  // Trader Rank Progression (Tier I - V based on Total XP)
  static const List<Map<String, dynamic>> traderRanks = [
    {
      'tier': 1,
      'title': 'Investor Pemula',
      'roman': 'I',
      'minXp': 0,
      'maxXp': 150,
      'color': Color(0xff94a3b8),
      'icon': Icons.school_rounded,
      'desc': 'Memulai langkah pertama memahami fondasi pasar modal & saham.',
      'perk': 'Akses 10 level dasar & 5 Nyawa Petir',
    },
    {
      'tier': 2,
      'title': 'Trader Ritel Aktif',
      'roman': 'II',
      'minXp': 150,
      'maxXp': 450,
      'color': Color(0xfff59e0b),
      'icon': Icons.trending_up_rounded,
      'desc': 'Mulai aktif menganalisis pergerakan harga dan tren pasar.',
      'perk': 'Simpan materi favorit tanpa batas & badge perunggu',
    },
    {
      'tier': 3,
      'title': 'Analis Saham Muda',
      'roman': 'III',
      'minXp': 450,
      'maxXp': 900,
      'color': Color(0xff38bdf8),
      'icon': Icons.query_stats_rounded,
      'desc': 'Mampu membaca chart candlestick dan level Support/Resistance.',
      'perk': 'Akses analisis teknikal mendalam & badge perak',
    },
    {
      'tier': 4,
      'title': 'Swing Specialist',
      'roman': 'IV',
      'minXp': 900,
      'maxXp': 1600,
      'color': Color(0xff10b981),
      'icon': Icons.psychology_rounded,
      'desc': 'Menguasai Smart Money Concepts (SMC) & manajemen risiko.',
      'perk': 'Penguasaan instrumen institusi & badge emas',
    },
    {
      'tier': 5,
      'title': 'Market Maestro',
      'roman': 'V',
      'minXp': 1600,
      'maxXp': 2500,
      'color': Color(0xffa855f7),
      'icon': Icons.workspace_premium_rounded,
      'desc': 'Trader berpengetahuan komprehensif, disiplin dan bermental baja.',
      'perk': 'Gelar prestise tertinggi & frame profil ungu',
    },
  ];

  Map<String, dynamic> get currentRank {
    for (final r in traderRanks) {
      if (_xp < (r['maxXp'] as int)) {
        return r;
      }
    }
    return traderRanks.last;
  }

  Map<String, dynamic>? get nextRank {
    final cur = currentRank;
    final curTier = cur['tier'] as int;
    if (curTier < traderRanks.length) {
      return traderRanks[curTier];
    }
    return null;
  }

  double get rankProgress {
    final cur = currentRank;
    final min = cur['minXp'] as int;
    final max = cur['maxXp'] as int;
    if (_xp >= max) {
      if (cur['tier'] == traderRanks.length) return 1.0;
    }
    final range = max - min;
    if (range <= 0) return 1.0;
    final inRange = (_xp - min).clamp(0, range);
    return inRange / range;
  }

  int get xpToNextRank {
    final cur = currentRank;
    final max = cur['maxXp'] as int;
    return (max - _xp).clamp(0, max);
  }

  // Paper Trading Getters
  double get virtualBalance => _virtualBalance;
  List<Map<String, dynamic>> get portfolio => _portfolio;
  List<Map<String, dynamic>> get tradeHistory => _tradeHistory;

  int getHoldingLots(String ticker) {
    final idx = _portfolio.indexWhere((p) => p['ticker'] == ticker);
    if (idx != -1) {
      return (_portfolio[idx]['lots'] as num).toInt();
    }
    return 0;
  }

  double getHoldingAvgPrice(String ticker) {
    final idx = _portfolio.indexWhere((p) => p['ticker'] == ticker);
    if (idx != -1) {
      return (_portfolio[idx]['avgPrice'] as num).toDouble();
    }
    return 0.0;
  }

  Timer? _regenTimer;
  StreamSubscription<AuthState>? _authSubscription;

  AppState({SharedPreferences? initialPrefs}) {
    if (initialPrefs != null) {
      _applyInitialSyncData(initialPrefs);
    } else {
      final currentSupabaseUser = SupabaseService.currentUser;
      if (currentSupabaseUser != null) {
        _isLoggedIn = true;
        _userId = currentSupabaseUser.id;
        _userEmail = currentSupabaseUser.email ?? _userEmail;
        final metaName = currentSupabaseUser.userMetadata?['name'] as String?;
        if (metaName != null && metaName.isNotEmpty) {
          _userName = metaName;
        }
        _isAuthLoading = false;
      }
    }
    _initAndLoadState(initialPrefs: initialPrefs);
    _startRegenTimer();
    _listenAuthChanges();
  }

  void _applyInitialSyncData(SharedPreferences prefs) {
    // 1. Check Supabase Current Session synchronously
    final currentSupabaseUser = SupabaseService.currentUser;
    if (currentSupabaseUser != null) {
      _isLoggedIn = true;
      _userId = currentSupabaseUser.id;
      _userEmail = currentSupabaseUser.email ?? _userEmail;
      final metaName = currentSupabaseUser.userMetadata?['name'] as String?;
      if (metaName != null && metaName.isNotEmpty) {
        _userName = metaName;
      }
    }

    // 2. Load cached local state synchronously
    final cachedJsonStr = prefs.getString('trade_heroes_state');
    if (cachedJsonStr != null && cachedJsonStr.isNotEmpty) {
      try {
        final json = jsonDecode(cachedJsonStr);
        _applyLocalData(json);
      } catch (e) {
        debugPrint("Error parsing initial sync data: $e");
      }
    } else {
      final guestLogged = prefs.getBool('is_logged_in') ?? false;
      if (guestLogged) {
        _isLoggedIn = true;
      }
    }

    _isAuthLoading = false;
  }

  void _listenAuthChanges() {
    try {
      _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen(
        (data) async {
          final session = data.session;
          final event = data.event;
          if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
            if (session?.user != null) {
              _isLoggedIn = true;
              _userId = session!.user.id;
              _userEmail = session.user.email ?? _userEmail;
              final metaName = session.user.userMetadata?['name'] as String?;
              if (metaName != null && metaName.isNotEmpty) {
                _userName = metaName;
              }
              try {
                final cloudProfile = await SupabaseService.fetchProfile(_userId!)
                    .timeout(const Duration(seconds: 4));
                if (cloudProfile != null) {
                  _applyProfileData(cloudProfile);
                } else {
                  // Profil baru di Supabase: simpan state awal ke cloud
                  await _saveState();
                }
              } catch (e) {
                debugPrint("Profile fetch error in auth change: $e");
              }
              try {
                final prefs = await SharedPreferences.getInstance();
                await _saveToLocalCache(prefs);
              } catch (e) {
                debugPrint("Cache save error in auth change: $e");
              }
              _isAuthLoading = false;
              notifyListeners();
            }
          } else if (event == AuthChangeEvent.signedOut) {
            _isLoggedIn = false;
            _isAuthLoading = false;
            _userId = null;
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_logged_in', false);
            } catch (_) {}
            notifyListeners();
          } else if (event == AuthChangeEvent.initialSession) {
            _isAuthLoading = false;
            notifyListeners();
          }
        },
        onError: (err, stack) {
          debugPrint("Supabase onAuthStateChange stream error caught safely: $err");
          _isAuthLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint("Auth subscription error: $e");
      _isAuthLoading = false;
      notifyListeners();
    }
  }

  // Initialize state with SharedPreferences (Web + Native Safe) and Supabase Cloud Sync
  Future<void> _initAndLoadState({SharedPreferences? initialPrefs}) async {
    try {
      final prefs = initialPrefs ?? await SharedPreferences.getInstance();

      // 1. Check Supabase Current Session
      final currentSupabaseUser = SupabaseService.currentUser;
      if (currentSupabaseUser != null) {
        _isLoggedIn = true;
        _userId = currentSupabaseUser.id;
        _userEmail = currentSupabaseUser.email ?? _userEmail;
        final metaName = currentSupabaseUser.userMetadata?['name'] as String?;
        if (metaName != null && metaName.isNotEmpty) {
          _userName = metaName;
        }

        // Try load from Supabase Cloud Profile with safety timeout
        try {
          final cloudProfile = await SupabaseService.fetchProfile(currentSupabaseUser.id)
              .timeout(const Duration(seconds: 4));
          if (cloudProfile != null) {
            _applyProfileData(cloudProfile);
          } else {
            await _saveState();
          }
        } catch (e) {
          debugPrint("Profile load timeout or error: $e");
        }
        await _saveToLocalCache(prefs);
        _checkDailyReset();
        _checkPetirRegenOnLoad();
        _isAuthLoading = false;
        notifyListeners();
        return;
      }

      // 2. Fallback to Local Cache (SharedPreferences)
      final cachedJsonStr = prefs.getString('trade_heroes_state');
      if (cachedJsonStr != null && cachedJsonStr.isNotEmpty) {
        final json = jsonDecode(cachedJsonStr);
        _applyLocalData(json);
      } else {
        // If guest session was saved
        _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      }

      _isAuthLoading = false;
      _checkDailyReset();
      _checkPetirRegenOnLoad();
      notifyListeners();
    } catch (e) {
      debugPrint("Error initializing AppState: $e");
      _isAuthLoading = false;
      notifyListeners();
    }
  }

  void _applyLocalData(Map<String, dynamic> json) {
    _petir = json['petir'] ?? 5;
    _xp = json['xp'] ?? 0;
    _dailyXp = json['dailyXp'] ?? 0;
    _streak = json['streak'] ?? 0;
    _completedLevels = List<int>.from(json['completedLevels'] ?? [1, 2, 3]);
    if (_completedLevels.isEmpty) {
      _completedLevels = [1, 2, 3];
    }
    if (json['levelStars'] != null && json['levelStars'] is Map) {
      _levelStars = (json['levelStars'] as Map).map(
        (k, v) => MapEntry(int.tryParse(k.toString()) ?? 1, (v as num).toInt()),
      );
    } else {
      _levelStars = {1: 3, 2: 3, 3: 3};
    }
    _readModules = List<int>.from(json['readModules'] ?? []);
    _favorites = List<Map<String, dynamic>>.from(json['favorites'] ?? []);
    _unlockedBadges = List<String>.from(json['unlockedBadges'] ?? []);
    _claimedChests = List<int>.from(json['claimedChests'] ?? []);
    _claimedDailyDays = List<int>.from(json['claimedDailyDays'] ?? []);
    _lastDailyClaimDate = json['lastDailyClaimDate'] ?? "";
    _isPremium = json['isPremium'] ?? false;
    _isLoggedIn = json['isLoggedIn'] ?? false;
    _lastActiveDate = json['lastActiveDate'] ?? "";
    _petirLastUsedTime = json['petirLastUsedTime'];
    _streakShields = json['streakShields'] ?? 0;
    _unlockedAvatars = List<String>.from(json['unlockedAvatars'] ?? ['bull', 'chart', 'wallet']);
    _claimedXpMilestones = List<int>.from(json['claimedXpMilestones'] ?? []);
    _lastDailyGoalClaimDate = json['lastDailyGoalClaimDate'] ?? "";
    _userName = json['userName'] ?? "Calon Trader";
    _userEmail = json['userEmail'] ?? "user@kursussaham.com";
    _userAvatar = json['userAvatar'] ?? "bull";
    _userId = json['userId'];
    _darkMode = json['darkMode'] ?? true;
    _dailyReminder = json['dailyReminder'] ?? true;
    _soundHaptic = json['soundHaptic'] ?? true;
    _bgmEnabled = json['bgmEnabled'] ?? false;
    _bgmTrack = json['bgmTrack'] ?? 'default';
    AudioService.setAudioEnabled(_soundHaptic);
    AudioService.setBgmTrack(_bgmTrack);
    if (_bgmEnabled) AudioService.startBgm();
    _language = json['language'] ?? "id";
    _role = json['role'] ?? (_userEmail == 'luthfirg2502@gmail.com' ? 'admin' : 'user');
    _virtualBalance = (json['virtualBalance'] as num?)?.toDouble() ?? 100000000.0;
    if (json['portfolio'] != null && json['portfolio'] is List) {
      _portfolio = List<Map<String, dynamic>>.from(json['portfolio']);
    }
    if (json['tradeHistory'] != null && json['tradeHistory'] is List) {
      _tradeHistory = List<Map<String, dynamic>>.from(json['tradeHistory']);
    }
  }

  void _applyProfileData(Map<String, dynamic> data) {
    if (data['name'] != null) _userName = data['name'];
    if (data['email'] != null) _userEmail = data['email'];
    if (data['avatar'] != null) _userAvatar = data['avatar'];
    if (data['petir'] != null) _petir = data['petir'];
    if (data['xp'] != null) _xp = data['xp'];
    if (data['daily_xp'] != null) _dailyXp = data['daily_xp'];
    if (data['streak'] != null) _streak = data['streak'];
    if (data['is_premium'] != null) _isPremium = data['is_premium'];
    if (data['streak_shields'] != null) _streakShields = data['streak_shields'];
    if (data['unlocked_avatars'] != null && data['unlocked_avatars'] is List) {
      _unlockedAvatars = (data['unlocked_avatars'] as List).map((x) => x.toString()).toList();
    }
    if (data['claimed_xp_milestones'] != null && data['claimed_xp_milestones'] is List) {
      _claimedXpMilestones = (data['claimed_xp_milestones'] as List).map((x) => (x as num).toInt()).toList();
    }
    if (data['last_daily_goal_claim_date'] != null) {
      _lastDailyGoalClaimDate = data['last_daily_goal_claim_date'];
    }
    if (data['last_daily_claim_date'] != null) _lastDailyClaimDate = data['last_daily_claim_date'];
    if (data['petir_last_used_time'] != null) _petirLastUsedTime = data['petir_last_used_time'];
    if (data['role'] != null) _role = data['role'];
    if (data['virtual_balance'] != null) {
      _virtualBalance = (data['virtual_balance'] as num).toDouble();
    }
    if (data['portfolio'] != null && data['portfolio'] is List) {
      _portfolio = List<Map<String, dynamic>>.from(data['portfolio']);
    }
    if (data['trade_history'] != null && data['trade_history'] is List) {
      _tradeHistory = List<Map<String, dynamic>>.from(data['trade_history']);
    }

    if (data['completed_levels'] != null && data['completed_levels'] is List) {
      _completedLevels = (data['completed_levels'] as List).map((x) => (x as num).toInt()).toList();
      if (_completedLevels.isEmpty) _completedLevels = [1, 2, 3];
    }
    if (data['level_stars'] != null && data['level_stars'] is Map) {
      _levelStars = (data['level_stars'] as Map).map(
        (k, v) => MapEntry(int.tryParse(k.toString()) ?? 1, (v as num).toInt()),
      );
    }
    if (data['read_modules'] != null && data['read_modules'] is List) {
      _readModules = (data['read_modules'] as List).map((x) => (x as num).toInt()).toList();
    }
    if (data['unlocked_badges'] != null && data['unlocked_badges'] is List) {
      _unlockedBadges = (data['unlocked_badges'] as List).map((x) => x.toString()).toList();
    }
    if (data['claimed_chests'] != null && data['claimed_chests'] is List) {
      _claimedChests = (data['claimed_chests'] as List).map((x) => (x as num).toInt()).toList();
    }
    if (data['claimed_daily_days'] != null && data['claimed_daily_days'] is List) {
      _claimedDailyDays = (data['claimed_daily_days'] as List).map((x) => (x as num).toInt()).toList();
    }
    if (data['favorites'] != null) {
      if (data['favorites'] is List) {
        _favorites = List<Map<String, dynamic>>.from(data['favorites']);
      }
    }
  }

  // Save state to local storage & Supabase Cloud
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _saveToLocalCache(prefs);
      _syncToCloudBackground();
    } catch (e) {
      debugPrint("Error saving state: $e");
    }
  }

  Future<void> _saveToLocalCache(SharedPreferences prefs) async {
    final data = {
      'petir': _petir,
      'xp': _xp,
      'dailyXp': _dailyXp,
      'streak': _streak,
      'completedLevels': _completedLevels,
      'levelStars': _levelStars.map((k, v) => MapEntry(k.toString(), v)),
      'readModules': _readModules,
      'favorites': _favorites,
      'unlockedBadges': _unlockedBadges,
      'claimedChests': _claimedChests,
      'claimedDailyDays': _claimedDailyDays,
      'lastDailyClaimDate': _lastDailyClaimDate,
      'streakShields': _streakShields,
      'unlockedAvatars': _unlockedAvatars,
      'claimedXpMilestones': _claimedXpMilestones,
      'lastDailyGoalClaimDate': _lastDailyGoalClaimDate,
      'isPremium': _isPremium,
      'isLoggedIn': _isLoggedIn,
      'lastActiveDate': _lastActiveDate,
      'petirLastUsedTime': _petirLastUsedTime,
      'userName': _userName,
      'userEmail': _userEmail,
      'userAvatar': _userAvatar,
      'userId': _userId,
      'role': _role,
      'darkMode': _darkMode,
      'dailyReminder': _dailyReminder,
      'soundHaptic': _soundHaptic,
      'bgmEnabled': _bgmEnabled,
      'bgmTrack': _bgmTrack,
      'language': _language,
      'virtualBalance': _virtualBalance,
      'portfolio': _portfolio,
      'tradeHistory': _tradeHistory,
    };
    await prefs.setString('trade_heroes_state', jsonEncode(data));
    await prefs.setBool('is_logged_in', _isLoggedIn);
  }

  void _syncToCloudBackground() {
    if (!SupabaseService.isAuthenticated) return;
    final user = SupabaseService.currentUser;
    if (user == null) return;

    final cloudPayload = {
      'name': _userName,
      'email': _userEmail,
      'avatar': _userAvatar,
      'petir': _petir,
      'xp': _xp,
      'daily_xp': _dailyXp,
      'streak': _streak,
      'completed_levels': _completedLevels,
      'level_stars': _levelStars.map((k, v) => MapEntry(k.toString(), v)),
      'read_modules': _readModules,
      'favorites': _favorites,
      'unlocked_badges': _unlockedBadges,
      'claimed_chests': _claimedChests,
      'claimed_daily_days': _claimedDailyDays,
      'last_daily_claim_date': _lastDailyClaimDate,
      'streak_shields': _streakShields,
      'unlocked_avatars': _unlockedAvatars,
      'claimed_xp_milestones': _claimedXpMilestones,
      'last_daily_goal_claim_date': _lastDailyGoalClaimDate,
      'is_premium': _isPremium,
      'petir_last_used_time': _petirLastUsedTime,
      'virtual_balance': _virtualBalance,
      'portfolio': _portfolio,
      'trade_history': _tradeHistory,
      'role': _role,
    };

    SupabaseService.saveProfile(user.id, cloudPayload).then((success) {
      if (kDebugMode && success) {
        debugPrint("Successfully synced state to Supabase");
      }
    });
  }

  // --- AUTHENTICATION METHODS ---

  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final res = await SupabaseService.signUp(
        email: email,
        password: password,
        name: name,
      );

      final user = res.user;
      if (user != null) {
        _isLoggedIn = true;
        _userId = user.id;
        _userEmail = user.email ?? email;
        _userName = name ?? (email.contains('@') ? email.split('@')[0] : email);
        
        try {
          final cloudProfile = await SupabaseService.fetchProfile(user.id);
          if (cloudProfile != null) {
            _applyProfileData(cloudProfile);
          }
        } catch (_) {}

        await _saveState();
        notifyListeners();
        return null; // success
      }
      return "Pendaftaran gagal, silakan coba lagi.";
    } on AuthException catch (e) {
      if (e.message.contains("already registered")) {
        return "Email ini sudah terdaftar. Silakan masuk menggunakan kata sandi Anda.";
      }
      if (e.message.contains("Password should be at least")) {
        return "Kata sandi minimal harus 6 karakter.";
      }
      return e.message;
    } catch (e) {
      return e.toString().replaceAll("Exception: ", "");
    }
  }

  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user != null) {
        _isLoggedIn = true;
        _userId = user.id;
        _userEmail = user.email ?? email;
        
        final metaName = user.userMetadata?['name'] as String?;
        if (metaName != null && metaName.isNotEmpty) {
          _userName = metaName;
        } else {
          _userName = email.contains('@') ? email.split('@')[0] : email;
        }

        // Fetch user data from cloud
        final cloudProfile = await SupabaseService.fetchProfile(user.id);
        if (cloudProfile != null) {
          _applyProfileData(cloudProfile);
        }

        await _saveState();
        notifyListeners();
        return null; // success
      }
      return "Login gagal, silakan periksa email dan kata sandi.";
    } on AuthException catch (e) {
      if (e.message.contains("Invalid login credentials")) {
        return "Email atau kata sandi tidak cocok. Silakan periksa kembali.";
      }
      if (e.message.contains("Email not confirmed")) {
        return "Email belum dikonfirmasi. Silakan periksa kotak masuk email Anda.";
      }
      return e.message;
    } catch (e) {
      return e.toString().replaceAll("Exception: ", "");
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      await SupabaseService.signInWithGoogle();
      return null;
    } catch (e) {
      return e.toString().replaceAll("Exception: ", "");
    }
  }

  void loginAsGuest({String name = "Tamu Trader"}) {
    _isLoggedIn = true;
    _userName = name;
    _userEmail = "guest@tradeheroes.local";
    _userAvatar = "bull";
    _userId = null;
    _saveState();
    notifyListeners();
  }

  void login({required String name, required String email, String avatar = "bull"}) {
    _isLoggedIn = true;
    _userName = name;
    _userEmail = email;
    _userAvatar = avatar;
    _saveState();
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      if (SupabaseService.isAuthenticated) {
        await SupabaseService.signOut();
      }
    } catch (e) {
      debugPrint("Logout error: $e");
    }
    _isLoggedIn = false;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    notifyListeners();
  }

  void updateAvatar(String newAvatar) {
    _userAvatar = newAvatar;
    _saveState();
    notifyListeners();
  }

  Future<bool> uploadAndSetCustomAvatar(Uint8List bytes, String fileExt) async {
    try {
      if (SupabaseService.isAuthenticated && _userId != null) {
        final publicUrl = await SupabaseService.uploadAvatar(
          userId: _userId!,
          bytes: bytes,
          fileExt: fileExt,
        );
        if (publicUrl != null) {
          _userAvatar = publicUrl;
          await _saveState();
          notifyListeners();
          return true;
        }
      }
      final b64 = base64Encode(bytes);
      _userAvatar = 'data:image/$fileExt;base64,$b64';
      await _saveState();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error setting custom avatar: $e");
      return false;
    }
  }

  // Settings & Preferences Handlers
  void toggleDarkMode(bool val) {
    _darkMode = val;
    _saveState();
    notifyListeners();
  }

  void toggleDailyReminder(bool val) {
    _dailyReminder = val;
    _saveState();
    notifyListeners();
  }

  void toggleSoundHaptic(bool val) {
    _soundHaptic = val;
    AudioService.setAudioEnabled(val);
    _saveState();
    notifyListeners();
  }

  void toggleBgm(bool val) {
    _bgmEnabled = val;
    if (val) {
      AudioService.startBgm();
    } else {
      AudioService.stopBgm();
    }
    _saveState();
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    _saveState();
    notifyListeners();
  }

  void setBgmTrack(String track) {
    _bgmTrack = track;
    AudioService.setBgmTrack(track);
    _saveState();
    notifyListeners();
  }

  // --- PAPER TRADING SIMULATOR LOGIC ---

  Map<String, dynamic> buyStock({
    required String ticker,
    required double price,
    required int lots,
  }) {
    if (lots <= 0) {
      return {'success': false, 'message': 'Jumlah lot harus lebih dari 0'};
    }
    final int totalShares = lots * 100;
    final double subtotal = price * totalShares;
    final double fee = subtotal * 0.0015; // 0.15% fee beli BEI
    final double totalCost = subtotal + fee;

    if (_virtualBalance < totalCost) {
      return {
        'success': false,
        'message': 'Saldo kas virtual tidak cukup untuk beli $lots Lot $ticker',
      };
    }

    _virtualBalance -= totalCost;

    final existingIdx = _portfolio.indexWhere((p) => p['ticker'] == ticker);
    if (existingIdx != -1) {
      final oldLots = (_portfolio[existingIdx]['lots'] as num).toInt();
      final oldShares = oldLots * 100;
      final oldAvg = (_portfolio[existingIdx]['avgPrice'] as num).toDouble();

      final newTotalShares = oldShares + totalShares;
      final newAvg = ((oldAvg * oldShares) + subtotal) / newTotalShares;
      final newLots = oldLots + lots;

      _portfolio[existingIdx]['lots'] = newLots;
      _portfolio[existingIdx]['totalShares'] = newTotalShares;
      _portfolio[existingIdx]['avgPrice'] = double.parse(newAvg.toStringAsFixed(1));
    } else {
      _portfolio.add({
        'ticker': ticker,
        'lots': lots,
        'totalShares': totalShares,
        'avgPrice': double.parse(price.toStringAsFixed(1)),
      });
    }

    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    _tradeHistory.insert(0, {
      'ticker': ticker,
      'type': 'BUY',
      'lots': lots,
      'shares': totalShares,
      'price': price,
      'fee': fee,
      'total': totalCost,
      'timestamp': timeStr,
    });

    AudioService.playTrade();
    _saveState();
    notifyListeners();
    return {
      'success': true,
      'message': 'Berhasil beli $lots Lot $ticker @ Rp ${price.toInt()}',
    };
  }

  Map<String, dynamic> sellStock({
    required String ticker,
    required double price,
    required int lots,
  }) {
    if (lots <= 0) {
      return {'success': false, 'message': 'Jumlah lot harus lebih dari 0'};
    }

    final existingIdx = _portfolio.indexWhere((p) => p['ticker'] == ticker);
    if (existingIdx == -1) {
      return {'success': false, 'message': 'Anda belum memiliki portofolio saham $ticker'};
    }

    final currentLots = (_portfolio[existingIdx]['lots'] as num).toInt();
    if (currentLots < lots) {
      return {
        'success': false,
        'message': 'Lot tidak cukup (Anda hanya memiliki $currentLots Lot $ticker)',
      };
    }

    final avgPrice = (_portfolio[existingIdx]['avgPrice'] as num).toDouble();
    final int totalShares = lots * 100;
    final double subtotal = price * totalShares;
    final double fee = subtotal * 0.0025; // 0.25% fee jual BEI
    final double netProceeds = subtotal - fee;
    final double realizedPnl = (price - avgPrice) * totalShares - fee;

    _virtualBalance += netProceeds;

    if (currentLots == lots) {
      _portfolio.removeAt(existingIdx);
    } else {
      _portfolio[existingIdx]['lots'] = currentLots - lots;
      _portfolio[existingIdx]['totalShares'] = (currentLots - lots) * 100;
    }

    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    _tradeHistory.insert(0, {
      'ticker': ticker,
      'type': 'SELL',
      'lots': lots,
      'shares': totalShares,
      'price': price,
      'fee': fee,
      'total': netProceeds,
      'realizedPnl': realizedPnl,
      'timestamp': timeStr,
    });

    AudioService.playTrade();
    _saveState();
    notifyListeners();
    return {
      'success': true,
      'message': 'Berhasil jual $lots Lot $ticker @ Rp ${price.toInt()}',
      'pnl': realizedPnl,
    };
  }

  void resetVirtualTrading() {
    _virtualBalance = 100000000.0;
    _portfolio = [];
    _tradeHistory = [];
    _saveState();
    notifyListeners();
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
    AudioService.playReward();
    _saveState();
    notifyListeners();
  }

  bool isChestClaimed(int chestLevelId) {
    return _claimedChests.contains(chestLevelId);
  }

  void claimChest(int chestLevelId, int xpReward, BuildContext context) {
    if (!_claimedChests.contains(chestLevelId)) {
      _claimedChests.add(chestLevelId);
      AudioService.playReward();
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
          if (_streakShields > 0) {
            _streakShields -= 1;
            // Streak diselamatkan oleh Pelindung Streak!
          } else {
            _streak = 1;
          }
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
    const regenMs = 60000;

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
    int tickCount = 0;
    _regenTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      tickCount++;
      // Auto-check midnight rollover every 30 seconds
      if (tickCount % 30 == 0) {
        _checkDailyReset();
      }

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
    final oldTier = currentRank['tier'] as int;
    _xp += amount;
    _dailyXp += amount;
    _saveState();
    notifyListeners();

    // Check Level Up / Tier Up celebration
    final newTier = currentRank['tier'] as int;
    if (newTier > oldTier) {
      _triggerTierUpModal(currentRank, context);
    }

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

  // Level completed with Candy Crush style Stars (1, 2, or 3)
  void completeLevel(int levelId, {int stars = 3}) {
    if (!_completedLevels.contains(levelId)) {
      _completedLevels.add(levelId);
    }
    final curStars = _levelStars[levelId] ?? 0;
    if (stars > curStars) {
      _levelStars[levelId] = stars;
    }
    _saveState();
    notifyListeners();
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
    // XP Milestones
    if (_xp >= 150 && !_unlockedBadges.contains("trader_tier_2")) {
      newlyUnlocked.add("trader_tier_2");
    }
    if (_xp >= 450 && !_unlockedBadges.contains("trader_tier_3")) {
      newlyUnlocked.add("trader_tier_3");
    }
    if (_xp >= 900 && !_unlockedBadges.contains("trader_tier_4")) {
      newlyUnlocked.add("trader_tier_4");
    }
    if (_xp >= 1600 && !_unlockedBadges.contains("trader_tier_5")) {
      newlyUnlocked.add("trader_tier_5");
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

  void _triggerTierUpModal(Map<String, dynamic> rankData, BuildContext context) {
    AudioService.playReward();
    final Color rColor = rankData['color'] as Color;
    final IconData rIcon = rankData['icon'] as IconData;
    final String rTitle = rankData['title'] as String;
    final String rRoman = rankData['roman'] as String;
    final String rDesc = rankData['desc'] as String;
    final String rPerk = rankData['perk'] as String;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff0f172a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: rColor, width: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: rColor, width: 3.5),
                color: const Color(0xff1e293b),
                boxShadow: [
                  BoxShadow(
                    color: rColor.withOpacity(0.55),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(rIcon, color: rColor, size: 46),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: rColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: rColor.withOpacity(0.5)),
              ),
              child: Text(
                "NAIK PANGKAT • TIER $rRoman",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: rColor,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              rTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              rDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xffcbd5e1), height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xff161f30),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xfffbbf24), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Keistimewaan Baru Terbuka:",
                          style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xff94a3b8)),
                        ),
                        Text(
                          rPerk,
                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: rColor,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                "AMBIL GELAR SAYA 👑",
                style: TextStyle(fontFamily: 'Outfit', color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
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
      case "trader_tier_2": return "Trader Ritel Aktif";
      case "trader_tier_3": return "Analis Saham Muda";
      case "trader_tier_4": return "Swing Specialist";
      case "trader_tier_5": return "Market Maestro";
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
      case "trader_tier_2": return "📈";
      case "trader_tier_3": return "📊";
      case "trader_tier_4": return "🧠";
      case "trader_tier_5": return "💎";
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
      case "trader_tier_2": return "Mencapai 150 XP dan naik pangkat ke Tier II.";
      case "trader_tier_3": return "Mencapai 450 XP dan naik pangkat ke Tier III.";
      case "trader_tier_4": return "Mencapai 900 XP dan naik pangkat ke Tier IV.";
      case "trader_tier_5": return "Mencapai 1.600 XP dan meraih gelar tertinggi Tier V!";
      default: return "";
    }
  }

  @override
  void dispose() {
    _regenTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
