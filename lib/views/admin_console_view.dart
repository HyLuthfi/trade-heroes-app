import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_translations.dart';
import '../services/supabase_service.dart';
import '../state/app_state.dart';

const Map<String, String> _adminTranslationsId = {
  'admin.header_title': 'Admin Console & CMS',
  'admin.header_subtitle': 'Kelola trader, status VIP, kurikulum, & metrik',
  'admin.trader_badge': 'Trader',
  'admin.tab_users': 'Daftar Pengguna',
  'admin.tab_curriculum': 'Manajemen Kurikulum',
  'admin.stat_total_traders': 'Total Trader',
  'admin.stat_vip_members': 'Member VIP',
  'admin.stat_free_users': 'User Free',
  'admin.stat_admins': 'Admin',
  'admin.stats_total_traders': 'Total Trader',
  'admin.stats_vip_members': 'Member VIP',
  'admin.stats_free_users': 'User Free',
  'admin.stats_admins': 'Admin',
  'admin.search_hint': 'Cari nama, email, atau ID trader...',
  'admin.filter_all': 'Semua',
  'admin.filter_vip': 'VIP',
  'admin.filter_free': 'Free',
  'admin.filter_admin': 'Admin',
  'admin.empty_traders': 'Belum ada data trader',
  'admin.empty_search_results': 'Tidak ada hasil yang sesuai',
  'admin.role_admin': 'ADMIN',
  'admin.badge_vip': 'VIP GOLD',
  'admin.badge_free': 'FREE',
  'admin.stat_cash': 'Kas',
  'admin.stat_xp': 'XP',
  'admin.stat_petir': 'Petir',
  'admin.stat_streak': 'Streak',
  'admin.stat_joined': 'Bergabung',
  'admin.days': 'Hari',
  'admin.streak_days': 'Hari',
  'admin.action_grant_vip': 'Beri VIP',
  'admin.action_revoke_vip': 'Cabut VIP',
  'admin.action_refill_petir': 'Isi Petir',
  'admin.action_add_balance': '+Rp 50M',
  'admin.vip_enabled': 'diaktifkan',
  'admin.vip_disabled': 'dinonaktifkan',
  'admin.vip_toggle_snack': 'VIP Gold {status} untuk {name}',
  'admin.petir_refill_snack': 'Nyawa petir {name} diisi penuh (5 Petir)',
  'admin.balance_adjust_snack': 'Saldo kas {name} disetel ke {balance}',
  'admin.curriculum_title': 'Struktur Kurikulum Pasar Modal',
  'admin.curriculum_subtitle': '10 Level terverifikasi • 30 Soal terdistribusi ke 3 zona edukasi',
  'admin.status_verified': 'Terverifikasi',
  'admin.status_active': 'Aktif',
  'admin.levels_summary': 'Daftar Level',
  'admin.zone_1_title': 'Zona 1 — Fondasi Utama',
  'admin.zone_1_levels': 'Level 1 s/d 3 (9 Soal)',
  'admin.zone_1_desc': 'Pengenalan Saham, Bursa Efek Indonesia (BEI), Dividen & Capital Gain.',
  'admin.zone_2_title': 'Zona 2 — Analisis Teknikal',
  'admin.zone_2_levels': 'Level 4 s/d 7 (12 Soal)',
  'admin.zone_2_desc': 'Candlestick Dasar, Support & Resistance, Trendlines, Indikator Teknikal.',
  'admin.zone_3_title': 'Zona 3 — Manajemen Risiko',
  'admin.zone_3_levels': 'Level 8 s/d 10 (9 Soal)',
  'admin.zone_3_desc': 'Money Management, Psikologi Trading, Cut Loss vs Take Profit.',
  'admin.curriculum_footer_note': 'Kurikulum BEI terintegrasi penuh dengan simulator trading pasar reguler.',
  'admin.access_denied': 'Akses Ditolak',
  'admin.access_denied_desc': 'Halaman ini hanya dapat diakses oleh Administrator.',
  'admin.refresh_tooltip': 'Segarkan Data',
  'admin.back_tooltip': 'Kembali',
};

const Map<String, String> _adminTranslationsEn = {
  'admin.header_title': 'Admin Console & CMS',
  'admin.header_subtitle': 'Manage traders, VIP status, curriculum, & metrics',
  'admin.trader_badge': 'Traders',
  'admin.tab_users': 'User List',
  'admin.tab_curriculum': 'Curriculum Management',
  'admin.stat_total_traders': 'Total Traders',
  'admin.stat_vip_members': 'VIP Members',
  'admin.stat_free_users': 'Free Users',
  'admin.stat_admins': 'Admins',
  'admin.stats_total_traders': 'Total Traders',
  'admin.stats_vip_members': 'VIP Members',
  'admin.stats_free_users': 'Free Users',
  'admin.stats_admins': 'Admins',
  'admin.search_hint': 'Search trader name, email, or ID...',
  'admin.filter_all': 'All',
  'admin.filter_vip': 'VIP',
  'admin.filter_free': 'Free',
  'admin.filter_admin': 'Admin',
  'admin.empty_traders': 'No trader data available',
  'admin.empty_search_results': 'No matching results found',
  'admin.role_admin': 'ADMIN',
  'admin.badge_vip': 'VIP GOLD',
  'admin.badge_free': 'FREE',
  'admin.stat_cash': 'Cash',
  'admin.stat_xp': 'XP',
  'admin.stat_petir': 'Energy',
  'admin.stat_streak': 'Streak',
  'admin.stat_joined': 'Joined',
  'admin.days': 'Days',
  'admin.streak_days': 'Days',
  'admin.action_grant_vip': 'Grant VIP',
  'admin.action_revoke_vip': 'Revoke VIP',
  'admin.action_refill_petir': 'Refill Energy',
  'admin.action_add_balance': '+Rp 50M',
  'admin.vip_enabled': 'enabled',
  'admin.vip_disabled': 'disabled',
  'admin.vip_toggle_snack': 'VIP Gold {status} for {name}',
  'admin.petir_refill_snack': 'Energy lives for {name} refilled (5 Energy)',
  'admin.balance_adjust_snack': 'Cash balance for {name} set to {balance}',
  'admin.curriculum_title': 'Capital Market Curriculum Structure',
  'admin.curriculum_subtitle': '10 Verified levels • 30 Questions across 3 educational zones',
  'admin.status_verified': 'Verified',
  'admin.status_active': 'Active',
  'admin.levels_summary': 'Levels Overview',
  'admin.zone_1_title': 'Zone 1 — Core Foundations',
  'admin.zone_1_levels': 'Levels 1 to 3 (9 Questions)',
  'admin.zone_1_desc': 'Stock Basics, Indonesia Stock Exchange (IDX), Dividends & Capital Gain.',
  'admin.zone_2_title': 'Zone 2 — Technical Analysis',
  'admin.zone_2_levels': 'Levels 4 to 7 (12 Questions)',
  'admin.zone_2_desc': 'Basic Candlesticks, Support & Resistance, Trendlines, Technical Indicators.',
  'admin.zone_3_title': 'Zone 3 — Risk Management',
  'admin.zone_3_levels': 'Levels 8 to 10 (9 Questions)',
  'admin.zone_3_desc': 'Money Management, Trading Psychology, Cut Loss vs Take Profit.',
  'admin.curriculum_footer_note': 'IDX curriculum fully integrated with regular market trading simulator.',
  'admin.access_denied': 'Access Denied',
  'admin.access_denied_desc': 'This console is restricted to Administrators only.',
  'admin.refresh_tooltip': 'Refresh Data',
  'admin.back_tooltip': 'Back',
};

class AdminConsoleView extends StatefulWidget {
  const AdminConsoleView({Key? key}) : super(key: key);

  static bool _translationsRegistered = false;

  /// Ensures dynamic translations for Admin Console are registered in AppTranslations.
  static void ensureTranslationsRegistered() {
    if (!_translationsRegistered) {
      AppTranslations.registerTranslations('id', _adminTranslationsId);
      AppTranslations.registerTranslations('en', _adminTranslationsEn);
      _translationsRegistered = true;
    }
  }

  @override
  State<AdminConsoleView> createState() => _AdminConsoleViewState();
}

class _AdminConsoleViewState extends State<AdminConsoleView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedFilter = "all"; // "all" | "vip" | "free" | "admin"

  @override
  void initState() {
    super.initState();
    AdminConsoleView.ensureTranslationsRegistered();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    final users = await SupabaseService.fetchAllProfiles();
    if (mounted) {
      setState(() {
        _profiles = users;
        _isLoading = false;
      });
    }
  }

  String _formatRp(num number) {
    final str = number.toInt().abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    final sign = number < 0 ? '-Rp ' : 'Rp ';
    return '$sign$buffer';
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "-";
    try {
      final dt = DateTime.tryParse(timestamp.toString());
      if (dt == null) return "-";
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (_) {
      return "-";
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    return _profiles.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final id = (u['id'] ?? '').toString().toLowerCase();
      final role = (u['role'] ?? '').toString().toLowerCase();
      final isVip = u['is_premium'] == true;

      final query = _searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          name.contains(query) ||
          email.contains(query) ||
          id.contains(query);

      if (!matchesQuery) return false;

      final filter = _selectedFilter.toLowerCase();
      if (filter == "vip") return isVip;
      if (filter == "free") return !isVip;
      if (filter == "admin") return role == "admin";
      return true;
    }).toList();
  }

  Future<void> _toggleVip(Map<String, dynamic> user) async {
    final userId = user['id'] as String;
    final currentStatus = user['is_premium'] == true;
    final newStatus = !currentStatus;

    final success = await SupabaseService.adminUpdateProfile(userId, {
      'is_premium': newStatus,
    });

    if (success && mounted) {
      setState(() {
        user['is_premium'] = newStatus;
      });
      final appState = Provider.of<AppState>(context, listen: false);
      final lang = appState.language;
      final statusText = newStatus
          ? AppTranslations.text(lang, 'admin.vip_enabled')
          : AppTranslations.text(lang, 'admin.vip_disabled');
      final userName = user['name'] ?? user['email'] ?? 'Trader';
      final msg = AppTranslations.text(
        lang,
        'admin.vip_toggle_snack',
        params: {'name': userName.toString(), 'status': statusText},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xff059669),
          content: Text(msg),
        ),
      );
    }
  }

  Future<void> _refillPetir(Map<String, dynamic> user) async {
    final userId = user['id'] as String;
    final success = await SupabaseService.adminUpdateProfile(userId, {
      'petir': 5,
      'petir_last_used_time': null,
    });

    if (success && mounted) {
      setState(() {
        user['petir'] = 5;
      });
      final appState = Provider.of<AppState>(context, listen: false);
      final lang = appState.language;
      final userName = user['name'] ?? user['email'] ?? 'Trader';
      final msg = AppTranslations.text(
        lang,
        'admin.petir_refill_snack',
        params: {'name': userName.toString()},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xff059669),
          content: Text(msg),
        ),
      );
    }
  }

  Future<void> _adjustBalance(Map<String, dynamic> user, double delta) async {
    final userId = user['id'] as String;
    final current = (user['virtual_balance'] as num?)?.toDouble() ?? 100000000.0;
    final newBal = (current + delta).clamp(0.0, 10000000000.0);

    final success = await SupabaseService.adminUpdateProfile(userId, {
      'virtual_balance': newBal,
    });

    if (success && mounted) {
      setState(() {
        user['virtual_balance'] = newBal;
      });
      final appState = Provider.of<AppState>(context, listen: false);
      final lang = appState.language;
      final userName = user['name'] ?? user['email'] ?? 'Trader';
      final msg = AppTranslations.text(
        lang,
        'admin.balance_adjust_snack',
        params: {'name': userName.toString(), 'balance': _formatRp(newBal)},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xff059669),
          content: Text(msg),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    AdminConsoleView.ensureTranslationsRegistered();
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final language = appState.language;
    String tr(String key, {Map<String, String> params = const {}}) =>
        AppTranslations.text(language, key, params: params);

    final totalUsers = _profiles.length;
    final vipCount = _profiles.where((p) => p['is_premium'] == true).length;
    final freeCount = _profiles.where((p) => p['is_premium'] != true).length;
    final adminCount = _profiles.where((p) => (p['role'] ?? '').toString().toLowerCase() == 'admin').length;

    return Scaffold(
      key: const ValueKey('admin-scaffold'),
      backgroundColor: isDark ? const Color(0xff090d16) : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xff0f172a) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          tooltip: tr('admin.back_tooltip'),
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : const Color(0xff0f172a), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  tr('admin.header_title'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xff0f172a),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xff1e293b) : const Color(0xffecfdf5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isDark ? const Color(0xff334155) : const Color(0xffa7f3d0)),
                  ),
                  child: Text(
                    "$totalUsers ${tr('admin.trader_badge')}",
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xff10b981)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              tr('admin.header_subtitle'),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: tr('admin.refresh_tooltip'),
            icon: Icon(Icons.refresh_rounded, color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b), size: 20),
            onPressed: _loadProfiles,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xff10b981),
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: isDark ? Colors.white : const Color(0xff0f172a),
          unselectedLabelColor: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
          labelStyle: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 13),
          dividerColor: isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0),
          tabs: [
            Tab(text: tr('admin.tab_users')),
            Tab(text: tr('admin.tab_curriculum')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: USER MANAGEMENT (PRIMARY HERO VIEW)
          Column(
            children: [
              // 1. High-Density Executive Stats Strip
              Container(
                key: const ValueKey('admin-stats-strip'),
                margin: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff0f172a) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0)),
                ),
                child: Row(
                  children: [
                    _buildTopStatCell(tr('admin.stat_total_traders'), "$totalUsers", const Color(0xff38bdf8), isDark),
                    _buildDivider(isDark),
                    _buildTopStatCell(tr('admin.stat_vip_members'), "$vipCount", const Color(0xfff59e0b), isDark),
                    _buildDivider(isDark),
                    _buildTopStatCell(tr('admin.stat_free_users'), "$freeCount", const Color(0xff34d399), isDark),
                    _buildDivider(isDark),
                    _buildTopStatCell(tr('admin.stat_admins'), "$adminCount", const Color(0xffa78bfa), isDark),
                  ],
                ),
              ),

              // 2. Search & Segment Filters
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    TextField(
                      key: const ValueKey('admin-user-search'),
                      style: TextStyle(fontFamily: 'Outfit', color: isDark ? Colors.white : const Color(0xff0f172a), fontSize: 13),
                      decoration: InputDecoration(
                        hintText: tr('admin.search_hint'),
                        hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 12, color: isDark ? const Color(0xff64748b) : const Color(0xff94a3b8)),
                        prefixIcon: Icon(Icons.search_rounded, color: isDark ? const Color(0xff64748b) : const Color(0xff94a3b8), size: 18),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded, color: isDark ? const Color(0xff64748b) : const Color(0xff94a3b8), size: 16),
                                onPressed: () => setState(() => _searchQuery = ""),
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? const Color(0xff0f172a) : Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xff10b981), width: 1.2),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                    const SizedBox(height: 8),

                    // Filter Chips
                    Row(
                      children: [
                        {'key': 'all', 'label': tr('admin.filter_all')},
                        {'key': 'vip', 'label': tr('admin.filter_vip')},
                        {'key': 'free', 'label': tr('admin.filter_free')},
                        {'key': 'admin', 'label': tr('admin.filter_admin')},
                      ].map((item) {
                        final key = item['key']!;
                        final label = item['label']!;
                        final isSel = _selectedFilter.toLowerCase() == key ||
                            _selectedFilter == label ||
                            (_selectedFilter == "Semua" && key == "all");
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: isSel,
                            onSelected: (_) => setState(() => _selectedFilter = key),
                            selectedColor: const Color(0xff059669),
                            backgroundColor: isDark ? const Color(0xff0f172a) : Colors.white,
                            labelStyle: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.white : (isDark ? const Color(0xff94a3b8) : const Color(0xff64748b)),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSel ? const Color(0xff10b981) : (isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0)),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 3. Trader List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xff10b981), strokeWidth: 2))
                    : _filteredUsers.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isEmpty ? tr('admin.empty_traders') : tr('admin.empty_search_results'),
                              style: TextStyle(fontFamily: 'Inter', color: isDark ? const Color(0xff64748b) : const Color(0xff94a3b8), fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, idx) {
                              final u = _filteredUsers[idx];
                              return _buildUserCard(u, isDark, tr);
                            },
                          ),
              ),
            ],
          ),

          // TAB 2: CURRICULUM & MODULES CMS PREVIEW
          _buildCurriculumOverviewTab(isDark, tr),
        ],
      ),
    );
  }

  Widget _buildTopStatCell(String title, String val, Color color, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b)),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              val,
              style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w900, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0),
    );
  }

  Widget _buildUserCard(
    Map<String, dynamic> u,
    bool isDark,
    String Function(String, {Map<String, String> params}) tr,
  ) {
    final isVip = u['is_premium'] == true;
    final role = (u['role'] ?? '').toString().toLowerCase();
    final isAdmin = role == 'admin';
    final avatarUrl = u['avatar'] as String?;
    final balance = (u['virtual_balance'] as num?)?.toDouble() ?? 100000000.0;
    final xp = u['xp'] ?? 0;
    final streak = u['streak'] ?? 0;
    final joined = _formatDate(u['created_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff0f172a) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmin ? const Color(0xfff59e0b).withOpacity(0.35) : (isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xff1e293b) : const Color(0xfff1f5f9),
                  border: Border.all(
                    color: isAdmin ? const Color(0xfff59e0b) : (isVip ? const Color(0xffeab308) : const Color(0xff10b981)),
                    width: 1.2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: (avatarUrl != null && avatarUrl.startsWith('http'))
                    ? Image.network(avatarUrl, fit: BoxFit.cover, width: 38, height: 38)
                    : Icon(isAdmin ? Icons.shield_rounded : Icons.person_rounded, color: isDark ? Colors.white : const Color(0xff475569), size: 20),
              ),
              const SizedBox(width: 10),

              // Name & Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            u['name'] ?? 'Trader',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xff0f172a),
                            ),
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xff78350f) : const Color(0xfffef3c7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tr('admin.role_admin'),
                              style: const TextStyle(fontFamily: 'Outfit', fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xfff59e0b)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      u['email'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b)),
                    ),
                  ],
                ),
              ),

              // Status Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isVip
                      ? (isDark ? const Color(0xff78350f).withOpacity(0.5) : const Color(0xfffef3c7))
                      : (isDark ? const Color(0xff1e293b) : const Color(0xfff1f5f9)),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isVip ? const Color(0xfff59e0b) : (isDark ? const Color(0xff334155) : const Color(0xffcbd5e1)),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isVip ? tr('admin.badge_vip') : tr('admin.badge_free'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isVip ? (isDark ? const Color(0xfffbbf24) : const Color(0xffd97706)) : (isDark ? const Color(0xff94a3b8) : const Color(0xff64748b)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // User Stats Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff161f30) : const Color(0xfff8fafc),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.transparent : const Color(0xffe2e8f0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCompactStat(tr('admin.stat_cash'), _formatRp(balance), const Color(0xff34d399), isDark),
                _buildCompactStat(tr('admin.stat_xp'), "$xp", const Color(0xff60a5fa), isDark),
                _buildCompactStat(tr('admin.stat_streak'), "$streak ${tr('admin.days')}", const Color(0xfff87171), isDark),
                _buildCompactStat(tr('admin.stat_joined'), joined, const Color(0xffa78bfa), isDark),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildMiniActionBtn(
                label: isVip ? tr('admin.action_revoke_vip') : tr('admin.action_grant_vip'),
                color: isVip ? const Color(0xfff87171) : const Color(0xfff59e0b),
                onTap: () => _toggleVip(u),
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _buildMiniActionBtn(
                label: tr('admin.action_refill_petir'),
                color: const Color(0xff10b981),
                onTap: () => _refillPetir(u),
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _buildMiniActionBtn(
                label: tr('admin.action_add_balance'),
                color: const Color(0xff38bdf8),
                onTap: () => _adjustBalance(u, 50000000.0),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String label, String val, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$label: ",
          style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: isDark ? const Color(0xff64748b) : const Color(0xff64748b)),
        ),
        Text(
          val,
          style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildMiniActionBtn({required String label, required Color color, required VoidCallback onTap, required bool isDark}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.12 : 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(isDark ? 0.4 : 0.35), width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(fontFamily: 'Outfit', fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  // TAB 2: CURRICULUM CMS OVERVIEW
  Widget _buildCurriculumOverviewTab(
    bool isDark,
    String Function(String, {Map<String, String> params}) tr,
  ) {
    final zones = [
      {
        'title': tr('admin.zone_1_title'),
        'levels': tr('admin.zone_1_levels'),
        'desc': tr('admin.zone_1_desc'),
        'status': tr('admin.status_active'),
        'color': const Color(0xff10b981),
      },
      {
        'title': tr('admin.zone_2_title'),
        'levels': tr('admin.zone_2_levels'),
        'desc': tr('admin.zone_2_desc'),
        'status': tr('admin.status_active'),
        'color': const Color(0xff38bdf8),
      },
      {
        'title': tr('admin.zone_3_title'),
        'levels': tr('admin.zone_3_levels'),
        'desc': tr('admin.zone_3_desc'),
        'status': tr('admin.status_active'),
        'color': const Color(0xffec4899),
      },
    ];

    final levelBreakdown = [
      {'level': 1, 'questions': 3, 'status': tr('admin.status_verified')},
      {'level': 2, 'questions': 3, 'status': tr('admin.status_verified')},
      {'level': 3, 'questions': 3, 'status': tr('admin.status_verified')},
      {'level': 4, 'questions': 3, 'status': tr('admin.status_verified')},
      {'level': 5, 'questions': 3, 'status': tr('admin.status_verified')},
      {'level': 6, 'questions': 3, 'status': tr('admin.status_verified')},
      {'level': 7, 'questions': 3, 'status': tr('admin.status_verified')},
      {'level': 8, 'questions': 3, 'status': tr('admin.status_verified')},
      {'level': 9, 'questions': 3, 'status': tr('admin.status_verified')},
      {'level': 10, 'questions': 3, 'status': tr('admin.status_verified')},
    ];

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xff0f172a) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tr('admin.curriculum_title'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xff0f172a),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff064e3b).withOpacity(0.5) : const Color(0xffecfdf5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xff10b981), width: 0.8),
                    ),
                    child: Text(
                      tr('admin.status_verified'),
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xff10b981)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tr('admin.curriculum_subtitle'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Levels Overview Strip (Level 1-10 with Question Counts and Status)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xff0f172a) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('admin.levels_summary'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xffcbd5e1) : const Color(0xff475569),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: levelBreakdown.map((lb) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff161f30) : const Color(0xfff8fafc),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "L${lb['level']}",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xff0f172a),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "(${lb['questions']})",
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: Color(0xff10b981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        ...zones.map((z) {
          final color = z['color'] as Color;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff0f172a) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3.5,
                  height: 48,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              z['title'] as String,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xff0f172a),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: color.withOpacity(0.4), width: 0.8),
                            ),
                            child: Text(
                              z['status'] as String,
                              style: TextStyle(fontFamily: 'Outfit', fontSize: 9.5, fontWeight: FontWeight.bold, color: color),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        z['levels'] as String,
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold, color: color),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        z['desc'] as String,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xff064e3b).withOpacity(0.4) : const Color(0xffecfdf5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xff059669).withOpacity(0.6) : const Color(0xffa7f3d0)),
          ),
          child: Row(
            children: [
              Icon(Icons.verified_rounded, color: isDark ? const Color(0xff34d399) : const Color(0xff059669), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('admin.curriculum_footer_note'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: isDark ? const Color(0xffa7f3d0) : const Color(0xff065f46),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
