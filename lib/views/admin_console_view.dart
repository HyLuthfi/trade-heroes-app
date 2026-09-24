import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class AdminConsoleView extends StatefulWidget {
  const AdminConsoleView({Key? key}) : super(key: key);

  @override
  State<AdminConsoleView> createState() => _AdminConsoleViewState();
}

class _AdminConsoleViewState extends State<AdminConsoleView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedFilter = "Semua"; // "Semua" | "VIP" | "Free" | "Admin"

  @override
  void initState() {
    super.initState();
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

  List<Map<String, dynamic>> get _filteredUsers {
    return _profiles.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final role = (u['role'] ?? '').toString().toLowerCase();
      final isVip = u['is_premium'] == true;

      final matchesQuery = _searchQuery.trim().isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase());

      if (!matchesQuery) return false;

      if (_selectedFilter == "VIP") return isVip;
      if (_selectedFilter == "Free") return !isVip;
      if (_selectedFilter == "Admin") return role == "admin";
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xff059669),
          content: Text("VIP Gold ${newStatus ? 'diaktifkan' : 'dinonaktifkan'} untuk ${user['name'] ?? user['email']}"),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xff059669),
          content: Text("Nyawa petir ${user['name'] ?? user['email']} diisi penuh (5 Petir)"),
        ),
      );
    }
  }

  Future<void> _adjustXp(Map<String, dynamic> user, int delta) async {
    final userId = user['id'] as String;
    final current = (user['xp'] as num?)?.toInt() ?? 0;
    final newXp = (current + delta).clamp(0, 999999);

    final success = await SupabaseService.adminUpdateProfile(userId, {
      'xp': newXp,
    });

    if (success && mounted) {
      setState(() {
        user['xp'] = newXp;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xff059669),
          content: Text("XP ${user['name'] ?? user['email']} disetel ke $newXp XP"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalUsers = _profiles.length;
    final vipCount = _profiles.where((p) => p['is_premium'] == true).length;
    int totalXp = 0;

    for (var p in _profiles) {
      totalXp += (p['xp'] as num?)?.toInt() ?? 0;
    }

    final avgXp = totalUsers > 0 ? (totalXp / totalUsers).round() : 0;

    return Scaffold(
      backgroundColor: const Color(0xff090d16),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f172a),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            const Text(
              "Admin Console",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xff1e293b),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xff334155)),
              ),
              child: Text(
                "$totalUsers Trader",
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xff10b981)),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xff94a3b8), size: 20),
            onPressed: _loadProfiles,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xff10b981),
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xff94a3b8),
          labelStyle: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "Manajemen Trader"),
            Tab(text: "Kurikulum & Modul"),
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
                margin: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xff0f172a),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xff1e293b)),
                ),
                child: Row(
                  children: [
                    _buildTopStatCell("Total Trader", "$totalUsers", const Color(0xff38bdf8)),
                    _buildDivider(),
                    _buildTopStatCell("VIP Gold", "$vipCount", const Color(0xfff59e0b)),
                    _buildDivider(),
                    _buildTopStatCell("Total XP", "$totalXp", const Color(0xff34d399)),
                    _buildDivider(),
                    _buildTopStatCell("Rata-rata XP", "$avgXp", const Color(0xffa78bfa)),
                  ],
                ),
              ),

              // 2. Search & Segment Filters
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    TextField(
                      style: const TextStyle(fontFamily: 'Outfit', color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Cari nama atau email trader...",
                        hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xff64748b)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xff64748b), size: 18),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Color(0xff64748b), size: 16),
                                onPressed: () => setState(() => _searchQuery = ""),
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xff0f172a),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xff1e293b)),
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
                      children: ["Semua", "VIP", "Free", "Admin"].map((filter) {
                        final isSel = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isSel,
                            onSelected: (_) => setState(() => _selectedFilter = filter),
                            selectedColor: const Color(0xff059669),
                            backgroundColor: const Color(0xff0f172a),
                            labelStyle: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.white : const Color(0xff94a3b8),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSel ? const Color(0xff10b981) : const Color(0xff1e293b),
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
                              _searchQuery.isEmpty ? "Belum ada data trader" : "Tidak ada hasil yang sesuai",
                              style: const TextStyle(fontFamily: 'Inter', color: Color(0xff64748b), fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, idx) {
                              final u = _filteredUsers[idx];
                              return _buildUserCard(u);
                            },
                          ),
              ),
            ],
          ),

          // TAB 2: CURRICULUM & MODULES CMS PREVIEW
          _buildCurriculumOverviewTab(),
        ],
      ),
    );
  }

  Widget _buildTopStatCell(String title, String val, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xff94a3b8)),
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

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xff1e293b),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> u) {
    final isVip = u['is_premium'] == true;
    final isAdmin = u['role'] == 'admin';
    final avatarUrl = u['avatar'] as String?;
    final petir = u['petir'] ?? 5;
    final levelCount = (u['completed_levels'] as List?)?.length ?? 0;
    final xp = u['xp'] ?? 0;
    final streak = u['streak'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff0f172a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmin ? const Color(0xfff59e0b).withOpacity(0.35) : const Color(0xff1e293b),
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
                  color: const Color(0xff1e293b),
                  border: Border.all(
                    color: isAdmin ? const Color(0xfff59e0b) : (isVip ? const Color(0xffeab308) : const Color(0xff10b981)),
                    width: 1.2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: (avatarUrl != null && avatarUrl.startsWith('http'))
                    ? Image.network(avatarUrl, fit: BoxFit.cover, width: 38, height: 38)
                    : Icon(isAdmin ? Icons.shield_rounded : Icons.person_rounded, color: Colors.white, size: 20),
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
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xff78350f),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "ADMIN",
                              style: TextStyle(fontFamily: 'Outfit', fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xfff59e0b)),
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
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xff94a3b8)),
                    ),
                  ],
                ),
              ),

              // Status Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isVip ? const Color(0xff78350f).withOpacity(0.5) : const Color(0xff1e293b),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isVip ? const Color(0xfff59e0b) : const Color(0xff334155),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isVip ? "VIP GOLD" : "FREE",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isVip ? const Color(0xfffbbf24) : const Color(0xff94a3b8),
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
              color: const Color(0xff161f30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCompactStat("Level", "$levelCount", const Color(0xff34d399)),
                _buildCompactStat("XP", "$xp", const Color(0xff60a5fa)),
                _buildCompactStat("Petir", "$petir/5", const Color(0xfff59e0b)),
                _buildCompactStat("Streak", "$streak Hari", const Color(0xfff87171)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildMiniActionBtn(
                label: isVip ? "Cabut VIP" : "Beri VIP",
                color: isVip ? const Color(0xfff87171) : const Color(0xfff59e0b),
                onTap: () => _toggleVip(u),
              ),
              const SizedBox(width: 6),
              _buildMiniActionBtn(
                label: "Isi Petir",
                color: const Color(0xff10b981),
                onTap: () => _refillPetir(u),
              ),
              const SizedBox(width: 6),
              _buildMiniActionBtn(
                label: "+50 XP",
                color: const Color(0xff38bdf8),
                onTap: () => _adjustXp(u, 50),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String label, String val, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xff64748b)),
        ),
        Text(
          val,
          style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildMiniActionBtn({required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.4), width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(fontFamily: 'Outfit', fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  // TAB 2: CURRICULUM CMS OVERVIEW
  Widget _buildCurriculumOverviewTab() {
    final zones = [
      {
        'title': "Zona 1 — Fondasi Utama",
        'levels': "Level 1 s/d 3 (9 Soal)",
        'desc': "Pengenalan Saham, Bursa Efek Indonesia (BEI), Dividen & Capital Gain.",
        'color': const Color(0xff10b981),
      },
      {
        'title': "Zona 2 — Analisis Teknikal",
        'levels': "Level 4 s/d 7 (12 Soal)",
        'desc': "Candlestick Dasar, Support & Resistance, Trendlines, Indikator Teknikal.",
        'color': const Color(0xff38bdf8),
      },
      {
        'title': "Zona 3 — Manajemen Risiko",
        'levels': "Level 8 s/d 10 (9 Soal)",
        'desc': "Money Management, Psikologi Trading, Cut Loss vs Take Profit.",
        'color': const Color(0xffec4899),
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xff0f172a),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xff1e293b)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Struktur Kurikulum Pasar Modal",
                style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 2),
              Text(
                "10 Level terverifikasi • 30 Soal terdistribusi ke 3 zona edukasi",
                style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xff94a3b8)),
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
              color: const Color(0xff0f172a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xff1e293b)),
            ),
            child: Row(
              children: [
                Container(
                  width: 3.5,
                  height: 38,
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
                          Text(
                            z['title'] as String,
                            style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            z['levels'] as String,
                            style: TextStyle(fontFamily: 'Outfit', fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        z['desc'] as String,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xff94a3b8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xff064e3b).withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xff059669).withOpacity(0.6)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_rounded, color: Color(0xff34d399), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Kurikulum BEI terintegrasi penuh dengan simulator trading pasar reguler.",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xffa7f3d0)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
