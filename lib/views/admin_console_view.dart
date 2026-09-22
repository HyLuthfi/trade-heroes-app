import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../state/app_state.dart';

class AdminConsoleView extends StatefulWidget {
  const AdminConsoleView({Key? key}) : super(key: key);

  @override
  State<AdminConsoleView> createState() => _AdminConsoleViewState();
}

class _AdminConsoleViewState extends State<AdminConsoleView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoadingProfiles = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllProfiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllProfiles() async {
    setState(() => _isLoadingProfiles = true);
    final users = await SupabaseService.fetchAllProfiles();
    if (mounted) {
      setState(() {
        _profiles = users;
        _isLoadingProfiles = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredProfiles {
    if (_searchQuery.trim().isEmpty) return _profiles;
    final q = _searchQuery.toLowerCase();
    return _profiles.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final role = (u['role'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q) || role.contains(q);
    }).toList();
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

  Future<void> _toggleUserVip(Map<String, dynamic> user) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xff059669),
          content: Text("Status VIP untuk ${user['name'] ?? user['email']} diubah ke: ${newStatus ? 'VIP GOLD' : 'GRATIS'}"),
        ),
      );
    }
  }

  Future<void> _refillUserPetir(Map<String, dynamic> user) async {
    final userId = user['id'] as String;
    final success = await SupabaseService.adminUpdateProfile(userId, {
      'petir': 5,
      'petir_last_used_time': null,
    });

    if (success && mounted) {
      setState(() {
        user['petir'] = 5;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xff059669),
          content: Text("Nyawa petir ${user['name'] ?? user['email']} berhasil diisi penuh (5 Petir)!"),
        ),
      );
    }
  }

  Future<void> _topupUserBalance(Map<String, dynamic> user, double amount) async {
    final userId = user['id'] as String;
    final current = (user['virtual_balance'] as num?)?.toDouble() ?? 100000000.0;
    final newBal = current + amount;

    final success = await SupabaseService.adminUpdateProfile(userId, {
      'virtual_balance': newBal,
    });

    if (success && mounted) {
      setState(() {
        user['virtual_balance'] = newBal;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xff059669),
          content: Text("Modal virtual ${user['name'] ?? user['email']} ditambah ${_formatRp(amount)}!"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0b0f19),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f172a),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.admin_panel_settings_rounded, color: Color(0xfff59e0b), size: 18),
                const SizedBox(width: 6),
                const Text(
                  "ADMIN CONSOLE",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xff78350f),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xfff59e0b), width: 0.8),
                  ),
                  child: const Text(
                    "SUPER ADMIN",
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xfffbbf24)),
                  ),
                ),
              ],
            ),
            const Text(
              "Executive Management & User Operations",
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xff94a3b8)),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xff10b981),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xff94a3b8),
          labelStyle: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 12.5),
          tabs: const [
            Tab(icon: Icon(Icons.analytics_rounded, size: 16), text: "Metrik"),
            Tab(icon: Icon(Icons.people_alt_rounded, size: 16), text: "Pengguna"),
            Tab(icon: Icon(Icons.menu_book_rounded, size: 16), text: "Konten & Kuis"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMetricsTab(),
          _buildUsersTab(),
          _buildContentTab(),
        ],
      ),
    );
  }

  // TAB 1: METRICS & ANALYTICS
  Widget _buildMetricsTab() {
    final totalUsers = _profiles.length;
    final vipCount = _profiles.where((p) => p['is_premium'] == true).length;
    double totalCirculatingCash = 0;
    int totalXpAll = 0;

    for (var p in _profiles) {
      totalCirculatingCash += (p['virtual_balance'] as num?)?.toDouble() ?? 100000000.0;
      totalXpAll += (p['xp'] as num?)?.toInt() ?? 0;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: "Total Pengguna",
                val: "$totalUsers Trader",
                sub: "Terdaftar di Supabase",
                icon: Icons.group_rounded,
                color: const Color(0xff3b82f6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: "VIP Gold Pass",
                val: "$vipCount Akun",
                sub: "${totalUsers > 0 ? ((vipCount / totalUsers) * 100).toStringAsFixed(1) : 0}% konversi",
                icon: Icons.workspace_premium_rounded,
                color: const Color(0xfff59e0b),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: "Total Kas Virtual",
                val: _formatRp(totalCirculatingCash),
                sub: "Beredar di Simulator",
                icon: Icons.account_balance_rounded,
                color: const Color(0xff10b981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: "Total Akumulasi XP",
                val: "$totalXpAll XP",
                sub: "Aktivitas Pembelajaran",
                icon: Icons.bolt_rounded,
                color: const Color(0xffec4899),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // System Health & Supabase Cloud Status Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xff0f172a),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xff1e293b)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "STATUS INFRASTRUKTUR CLOUD",
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xff94a3b8)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xff064e3b),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xff10b981), width: 0.8),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle_rounded, color: Color(0xff34d399), size: 12),
                        SizedBox(width: 4),
                        Text("ONLINE • AP-SOUTHEAST-1", style: TextStyle(fontFamily: 'Outfit', fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xff34d399))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSystemRow("Database Engine", "PostgreSQL 15 (Supabase BaaS)"),
              _buildSystemRow("Storage Engine", "Supabase Storage Bucket: 'avatars' (Public)"),
              _buildSystemRow("Security Layer", "Row Level Security (RLS) Active"),
              _buildSystemRow("Auth Providers", "Email Password & Google OAuth 2.0"),
              _buildSystemRow("Web App Gateway", "PM2 daemon port 20170 (tradeheroes-web)"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({required String title, required String val, required String sub, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff0f172a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xff1e293b)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xff94a3b8))),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(val, style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: color.withOpacity(0.9))),
        ],
      ),
    );
  }

  Widget _buildSystemRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xff94a3b8))),
          Text(val, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  // TAB 2: USER MANAGEMENT
  Widget _buildUsersTab() {
    final users = _filteredProfiles;

    return Column(
      children: [
        // Search & Refresh Toolbar
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          color: const Color(0xff0f172a),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(fontFamily: 'Outfit', color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Cari nama, email, atau role...",
                    hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xff64748b)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xff94a3b8), size: 18),
                    filled: true,
                    fillColor: const Color(0xff1e293b),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(backgroundColor: const Color(0xff1e293b)),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                onPressed: _loadAllProfiles,
              ),
            ],
          ),
        ),

        // User List
        Expanded(
          child: _isLoadingProfiles
              ? const Center(child: CircularProgressIndicator(color: Color(0xff10b981)))
              : users.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty ? "Belum ada user terdaftar" : "Tidak ada user yang cocok",
                        style: const TextStyle(fontFamily: 'Inter', color: Color(0xff94a3b8)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: users.length,
                      itemBuilder: (context, idx) {
                        final u = users[idx];
                        final isVip = u['is_premium'] == true;
                        final isAdmin = u['role'] == 'admin';
                        final avatarUrl = u['avatar'] as String?;
                        final petir = u['petir'] ?? 5;
                        final balance = (u['virtual_balance'] as num?)?.toDouble() ?? 100000000.0;
                        final xp = u['xp'] ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xff111827),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isAdmin ? const Color(0xfff59e0b).withOpacity(0.5) : Colors.white.withOpacity(0.08),
                              width: isAdmin ? 1.2 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xff1e293b),
                                      border: Border.all(color: isAdmin ? const Color(0xfff59e0b) : const Color(0xff10b981), width: 1.5),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    alignment: Alignment.center,
                                    child: (avatarUrl != null && avatarUrl.startsWith('http'))
                                        ? Image.network(avatarUrl, fit: BoxFit.cover, width: 42, height: 42)
                                        : Icon(isAdmin ? Icons.shield_rounded : Icons.person_rounded, color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              u['name'] ?? 'Trader',
                                              style: const TextStyle(fontFamily: 'Outfit', fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white),
                                            ),
                                            const SizedBox(width: 6),
                                            if (isAdmin)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(color: const Color(0xff78350f), borderRadius: BorderRadius.circular(4)),
                                                child: const Text("ADMIN", style: TextStyle(fontFamily: 'Outfit', fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xfff59e0b))),
                                              ),
                                          ],
                                        ),
                                        Text(
                                          u['email'] ?? '',
                                          style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xff94a3b8)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // VIP Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isVip ? const Color(0xff78350f) : const Color(0xff1e293b),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isVip ? const Color(0xfff59e0b) : const Color(0xff475569)),
                                    ),
                                    child: Text(
                                      isVip ? "VIP GOLD" : "FREE",
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isVip ? const Color(0xfff59e0b) : const Color(0xff94a3b8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Stats Row
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xff1e293b).withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildUserMiniStat("Saldo Kas", _formatRp(balance)),
                                    _buildUserMiniStat("XP", "$xp XP"),
                                    _buildUserMiniStat("Petir", "$petir / 5"),
                                    _buildUserMiniStat("Streak", "${u['streak'] ?? 0} Hari"),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Admin Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isVip ? const Color(0xffef4444) : const Color(0xfff59e0b),
                                      side: BorderSide(color: isVip ? const Color(0xffef4444) : const Color(0xfff59e0b)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: const Size(0, 32),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => _toggleUserVip(u),
                                    icon: Icon(isVip ? Icons.cancel_rounded : Icons.star_rounded, size: 14),
                                    label: Text(
                                      isVip ? "Cabut VIP" : "Berikan VIP",
                                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xff10b981),
                                      side: const BorderSide(color: Color(0xff10b981)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: const Size(0, 32),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => _refillUserPetir(u),
                                    icon: const Icon(Icons.bolt_rounded, size: 14),
                                    label: const Text(
                                      "Isi Petir",
                                      style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff3b82f6),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: const Size(0, 32),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                    ),
                                    onPressed: () => _topupUserBalance(u, 50000000.0),
                                    icon: const Icon(Icons.add_card_rounded, size: 14),
                                    label: const Text(
                                      "+Rp 50M",
                                      style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildUserMiniStat(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 9.5, color: Color(0xff94a3b8))),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11.5, fontWeight: FontWeight.w900, color: Colors.white)),
      ],
    );
  }

  // TAB 3: CONTENT & CURRICULUM OVERVIEW
  Widget _buildContentTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xff0f172a),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xff1e293b)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "RINGKASAN KURIKULUM & MATERI",
                style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              SizedBox(height: 4),
              Text(
                "Total 10 Level Kuis (30 Soal) & 6 Modul Edukasi Saham BEI",
                style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xff94a3b8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildCurriculumTile("Zona 1: Fondasi Utama", "Level 1–3 • Pengenalan Saham, BEI, Dividen", Icons.looks_one_rounded, const Color(0xff10b981)),
        _buildCurriculumTile("Zona 2: Analisis Teknikal", "Level 4–7 • Candlestick, Support/Resistance, Trendlines, Indikator", Icons.looks_two_rounded, const Color(0xff3b82f6)),
        _buildCurriculumTile("Zona 3: Manajemen Risiko", "Level 8–10 • Money Management, Psikologi Pasar, Cut Loss/Take Profit", Icons.looks_3_rounded, const Color(0xffec4899)),
      ],
    );
  }

  Widget _buildCurriculumTile(String title, String sub, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xff94a3b8))),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xff10b981), size: 18),
        ],
      ),
    );
  }
}
