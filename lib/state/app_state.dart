import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/locale_resolver.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';

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
  bool _isLoggedIn = false;
  String _lastActiveDate = ""; // YYYY-MM-DD
  int? _petirLastUsedTime; // timestamp in ms

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
  int _reminderHour = 19;
  String _lastReminderSentDate = "";
  String _lastDailyRewardReminderDate = "";
  bool _petirFullNotified = true;
  bool _soundHaptic = true;
  bool _bgmEnabled = false;
  String _language = "id";
  String _bgmTrack = "default";

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
  String? get userId => _userId;
  String get role => _role;
  bool get isAdmin => _role == 'admin' || _userEmail == 'luthfirg2502@gmail.com';
  bool get isCloudSynced => SupabaseService.isAuthenticated;
  bool get darkMode => _darkMode;
  bool get dailyReminder => _dailyReminder;
  int get reminderHour => _reminderHour;
  bool get soundHaptic => _soundHaptic;
  bool get bgmEnabled => _bgmEnabled;
  String get language => _language;
  String get bgmTrack => _bgmTrack;

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

  AppState() {
    _initAndLoadState();
    _startRegenTimer();
    _listenAuthChanges();
  }

  void _listenAuthChanges() {
    try {
      _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen((data) async {
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
            final cloudProfile = await SupabaseService.fetchProfile(_userId!);
            if (cloudProfile != null) {
              _applyProfileData(cloudProfile);
            }
            final prefs = await SharedPreferences.getInstance();
            await _saveToLocalCache(prefs);
            notifyListeners();
          }
        } else if (event == AuthChangeEvent.signedOut) {
          _isLoggedIn = false;
          _userId = null;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', false);
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint("Auth subscription error: $e");
    }
  }

  // Initialize state with SharedPreferences (Web + Native Safe) and Supabase Cloud Sync
  Future<void> _initAndLoadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Check Supabase Current Session
      if (SupabaseService.isInitialized) {
        final currentSupabaseUser = SupabaseService.currentUser;
        if (currentSupabaseUser != null) {
          _isLoggedIn = true;
          _userId = currentSupabaseUser.id;
          _userEmail = currentSupabaseUser.email ?? _userEmail;
          final metaName = currentSupabaseUser.userMetadata?['name'] as String?;
          if (metaName != null && metaName.isNotEmpty) {
            _userName = metaName;
          }

          // Try load from Supabase Cloud Profile
          final cloudProfile = await SupabaseService.fetchProfile(currentSupabaseUser.id);
          if (cloudProfile != null) {
            _applyProfileData(cloudProfile);
            final dedicatedLanguage = prefs.getString('app_language');
            String? cloudLanguage;
            if (cloudProfile['language'] is String) {
              cloudLanguage = cloudProfile['language'] as String;
            }
            _language = resolveLanguageCode(
              savedLanguage: dedicatedLanguage,
              fallbackSavedLanguage: cloudLanguage,
              deviceLocales: PlatformDispatcher.instance.locales,
            );
            await _saveToLocalCache(prefs);
            _checkDailyReset();
            _checkPetirRegenOnLoad();
            notifyListeners();
            return;
          }
        }
      }

      // 2. Fallback to Local Cache (SharedPreferences)
      String? legacyLanguage;
      final cachedJsonStr = prefs.getString('trade_heroes_state');
      if (cachedJsonStr != null && cachedJsonStr.isNotEmpty) {
        try {
          final json = jsonDecode(cachedJsonStr);
          if (json is Map<String, dynamic>) {
            _applyLocalData(json);
            if (json['language'] is String) {
              legacyLanguage = json['language'] as String;
            }
          }
        } catch (e) {
          debugPrint("Error parsing cached state: $e");
        }
      } else {
        // If guest session was saved
        _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      }

      final dedicatedLanguage = prefs.getString('app_language');
      _language = resolveLanguageCode(
        savedLanguage: dedicatedLanguage,
        fallbackSavedLanguage: legacyLanguage,
        deviceLocales: PlatformDispatcher.instance.locales,
      );

      _checkDailyReset();
      _checkPetirRegenOnLoad();
      _checkDailyNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint("Error initializing AppState: $e");
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
    _userName = json['userName'] ?? "Calon Trader";
    _userEmail = json['userEmail'] ?? "user@kursussaham.com";
    _userAvatar = json['userAvatar'] ?? "bull";
    _userId = json['userId'];
    _darkMode = json['darkMode'] ?? true;
    _dailyReminder = json['dailyReminder'] ?? true;
    _reminderHour = json['reminderHour'] ?? 19;
    _lastReminderSentDate = json['lastReminderSentDate'] ?? "";
    _lastDailyRewardReminderDate = json['lastDailyRewardReminderDate'] ?? "";
    NotificationService.setNotificationsEnabled(_dailyReminder);
    _soundHaptic = json['soundHaptic'] ?? true;
    _bgmEnabled = json['bgmEnabled'] ?? false;
    _bgmTrack = json['bgmTrack'] ?? 'default';
    AudioService.setAudioEnabled(_soundHaptic);
    AudioService.setBgmTrack(_bgmTrack);
    if (_bgmEnabled) AudioService.startBgm();
    final localLang = json['language'];
    if (localLang is String) {
      final clean = cleanSupportedLanguage(localLang);
      if (clean != null) {
        _language = clean;
      }
    }
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
    if (data['last_daily_claim_date'] != null) _lastDailyClaimDate = data['last_daily_claim_date'];
    if (data['petir_last_used_time'] != null) _petirLastUsedTime = data['petir_last_used_time'];
    if (data['role'] != null) _role = data['role'];
    final cloudLang = data['language'];
    if (cloudLang is String) {
      final clean = cleanSupportedLanguage(cloudLang);
      if (clean != null) {
        _language = clean;
      }
    }
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
      _completedLevels = List<int>.from(data['completed_levels']);
      if (_completedLevels.isEmpty) _completedLevels = [1, 2, 3];
    }
    if (data['read_modules'] != null && data['read_modules'] is List) {
      _readModules = List<int>.from(data['read_modules']);
    }
    if (data['unlocked_badges'] != null && data['unlocked_badges'] is List) {
      _unlockedBadges = List<String>.from(data['unlocked_badges']);
    }
    if (data['claimed_chests'] != null && data['claimed_chests'] is List) {
      _claimedChests = List<int>.from(data['claimed_chests']);
    }
    if (data['claimed_daily_days'] != null && data['claimed_daily_days'] is List) {
      _claimedDailyDays = List<int>.from(data['claimed_daily_days']);
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
      'userId': _userId,
      'role': _role,
      'darkMode': _darkMode,
      'dailyReminder': _dailyReminder,
      'reminderHour': _reminderHour,
      'lastReminderSentDate': _lastReminderSentDate,
      'lastDailyRewardReminderDate': _lastDailyRewardReminderDate,
      'soundHaptic': _soundHaptic,
      'bgmEnabled': _bgmEnabled,
      'bgmTrack': _bgmTrack,
      'language': _language,
      'virtualBalance': _virtualBalance,
      'portfolio': _portfolio,
      'tradeHistory': _tradeHistory,
    };
    await prefs.setString('trade_heroes_state', jsonEncode(data));
    await prefs.setString('app_language', _language);
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
      'language': _language,
      'petir': _petir,
      'xp': _xp,
      'daily_xp': _dailyXp,
      'streak': _streak,
      'completed_levels': _completedLevels,
      'read_modules': _readModules,
      'favorites': _favorites,
      'unlocked_badges': _unlockedBadges,
      'claimed_chests': _claimedChests,
      'claimed_daily_days': _claimedDailyDays,
      'last_daily_claim_date': _lastDailyClaimDate,
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
        
        await _saveState();
        notifyListeners();
        return null; // success
      }
      return "Pendaftaran gagal, silakan coba lagi.";
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
    NotificationService.setNotificationsEnabled(val);
    _saveState();
    notifyListeners();
  }

  void setReminderHour(int hour) {
    _reminderHour = hour;
    _saveState();
    notifyListeners();
  }

  Future<bool> requestNotificationPermission() async {
    final granted = await NotificationService.requestPermission();
    if (granted) {
      _dailyReminder = true;
      NotificationService.setNotificationsEnabled(true);
      _saveState();
      notifyListeners();
      NotificationService.sendTestNotification(language: _language);
    }
    return granted;
  }

  void testNotification() {
    NotificationService.sendTestNotification(language: _language);
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
    final clean = lang.toLowerCase().split(RegExp(r'[-_]')).first;
    if (clean != 'id' && clean != 'en') return;
    if (_language == clean) return;
    _language = clean;
    notifyListeners();
    _saveState();
  }

  void setBgmTrack(String track) {
    _bgmTrack = track;
    AudioService.setBgmTrack(track);
    _saveState();
    notifyListeners();
  }

  void resetProgress() {
    _completedLevels = [1, 2, 3];
    _readModules = [];
    _favorites = [];
    _unlockedBadges = [];
    _claimedChests = [];
    _claimedDailyDays = [];
    _lastDailyClaimDate = "";
    _xp = 0;
    _dailyXp = 0;
    _streak = 0;
    _petir = 5;
    _petirLastUsedTime = null;
    _virtualBalance = 100000000.0;
    _portfolio = [];
    _tradeHistory = [];
    _saveState();
    _syncToCloudBackground();
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

  void _checkDailyNotifications() {
    if (!_dailyReminder) return;
    final now = DateTime.now();
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // 1. Daily Streak Reminder (Pukul _reminderHour WIB ke atas jika belum ada daily XP hari ini)
    if (now.hour >= _reminderHour && _lastReminderSentDate != today) {
      if (_dailyXp == 0) {
        final sent = NotificationService.sendDailyStreakReminder(
          streak: _streak > 0 ? _streak : 1,
          language: _language,
        );
        if (sent) {
          _lastReminderSentDate = today;
          _saveState();
        }
      } else {
        // Smart scheduling: User already practiced today, no nagging needed!
        _lastReminderSentDate = today;
        _saveState();
      }
    }

    // 2. Daily Reward Reminder (Pukul 10:00 WIB ke atas jika belum klaim hari ini)
    if (now.hour >= 10 &&
        _lastDailyRewardReminderDate != today &&
        canClaimDailyToday) {
      final sent =
          NotificationService.sendDailyRewardReminder(language: _language);
      if (sent) {
        _lastDailyRewardReminderDate = today;
        _saveState();
      }
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
    _regenTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPremium || _petir >= 5) {
        _petirLastUsedTime = null;
        if (DateTime.now().second % 30 == 0) {
          _checkDailyNotifications();
        }
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
          if (_dailyReminder && !_petirFullNotified) {
            _petirFullNotified = true;
            NotificationService.sendPetirFullReminder(language: _language);
          }
        } else {
          _petirLastUsedTime = now;
        }
        _saveState();
        notifyListeners();
      }

      if (DateTime.now().second % 30 == 0) {
        _checkDailyNotifications();
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
        _petirFullNotified = false;
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
    _syncToCloudBackground();
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
    _authSubscription?.cancel();
    super.dispose();
  }
}
