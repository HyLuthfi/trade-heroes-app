import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/vip_pass_modal.dart';
import '../widgets/avatar_picker_modal.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> _badges = const [
    {
      'id': "saham_pemula",
      'name': "Saham Pemula",
      'desc': "Menyelesaikan kuis pertama Anda.",
      'iconData': Icons.grass_rounded,
      'color': Color(0xff10b981),
    },
    {
      'id': "anti_boncos",
      'name': "Anti Boncos",
      'desc': "Menjawab kuis 100% benar tanpa salah nyawa.",
      'iconData': Icons.shield_rounded,
      'color': Color(0xff3b82f6),
    },
    {
      'id': "investor_setia",
      'name': "Investor Setia",
      'desc': "Memiliki streak belajar minimal 3 hari.",
      'iconData': Icons.local_fire_department_rounded,
      'color': Color(0xffef4444),
    },
    {
      'id': "kolektor_ilmu",
      'name': "Kolektor Ilmu",
      'desc': "Menyimpan minimal 3 soal ke daftar favorit.",
      'iconData': Icons.menu_book_rounded,
      'color': Color(0xfff59e0b),
    },
    {
      'id': "premium_member",
      'name': "Premium Member",
      'desc': "Upgrade akun Anda ke Premium Plan.",
      'iconData': Icons.workspace_premium_rounded,
      'color': Color(0xff8b5cf6),
    },
    {
      'id': "pakar_saham",
      'name': "Pakar Saham",
      'desc': "Menyelesaikan seluruh 10 level Trade Heroes.",
      'iconData': Icons.school_rounded,
      'color': Color(0xffec4899),
    }
  ];

  final List<Map<String, dynamic>> _avatars = const [
    { 'id': "bull", 'iconData': Icons.trending_up_rounded, 'name': "Bull" },
    { 'id': "chart", 'iconData': Icons.show_chart_rounded, 'name': "Analyst" },
    { 'id': "vip", 'iconData': Icons.workspace_premium_rounded, 'name': "VIP Gold" },
    { 'id': "wallet", 'iconData': Icons.account_balance_wallet_rounded, 'name': "Whale" },
    { 'id': "rocket", 'iconData': Icons.rocket_launch_rounded, 'name': "Breakout" },
    { 'id': "star", 'iconData': Icons.stars_rounded, 'name': "Legend" },
    { 'id': "shield", 'iconData': Icons.security_rounded, 'name': "Guardian" },
    { 'id': "fire", 'iconData': Icons.local_fire_department_rounded, 'name': "Scalper" },
    { 'id': "academy", 'iconData': Icons.school_rounded, 'name': "Master" },
  ];

  void _showAvatarSelector(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff0f172a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xff10b981), width: 1.5)),
        title: const Text("Pilih Avatar Trader", style: TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _avatars.length,
            itemBuilder: (context, idx) {
              final ava = _avatars[idx];
              final isSelected = appState.userAvatar == ava['id'];
              return GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showProfileEditPrompt(context, appState, ava['id']);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xff059669).withOpacity(0.4) : const Color(0xff1e293b),
                    border: Border.all(
                      color: isSelected ? const Color(0xfff59e0b) : Colors.white.withOpacity(0.12),
                      width: isSelected ? 2.5 : 1,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xfff59e0b).withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    ava['iconData'] as IconData,
                    color: isSelected ? const Color(0xfff59e0b) : const Color(0xff60a5fa),
                    size: 32,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showProfileEditPrompt(BuildContext context, AppState appState, String selectedAvatar) {
    final nameController = TextEditingController(text: appState.userName);
    final emailController = TextEditingController(text: appState.userEmail);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff0f172a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xff10b981), width: 1.5)),
        title: const Text("Edit Informasi Profil", style: TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: "Nama Pengguna",
                labelStyle: TextStyle(color: Color(0xff94a3b8)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xff334155))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xff10b981))),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white, fontFamily: 'Outfit'),
              decoration: const InputDecoration(
                labelText: "Alamat Email",
                labelStyle: TextStyle(color: Color(0xff94a3b8)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xff334155))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xff10b981))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("BATAL", style: TextStyle(color: Color(0xff94a3b8), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff10b981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              appState.updateProfile(
                name: nameController.text.trim().isNotEmpty ? nameController.text.trim() : appState.userName,
                email: emailController.text.trim().isNotEmpty ? emailController.text.trim() : appState.userEmail,
                avatar: selectedAvatar,
              );
            },
            icon: const Icon(Icons.save_rounded, size: 16, color: Colors.white),
            label: const Text("SIMPAN", style: TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showBadgeDetail(BuildContext context, Map<String, dynamic> badge, bool isUnlocked) {
    final IconData iconData = badge['iconData'] as IconData;
    final Color badgeColor = badge['color'] as Color;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff0f172a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: isUnlocked ? badgeColor : const Color(0xff334155), width: 1.5),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnlocked ? badgeColor : const Color(0xff475569),
                  width: isUnlocked ? 3.5 : 2,
                ),
                color: const Color(0xff1e293b),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: badgeColor.withOpacity(0.5),
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Opacity(
                opacity: isUnlocked ? 1.0 : 0.35,
                child: Icon(iconData, color: isUnlocked ? badgeColor : const Color(0xff64748b), size: 42),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge['name'],
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              badge['desc'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xffcbd5e1), height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isUnlocked ? badgeColor.withOpacity(0.2) : const Color(0xff1e293b),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isUnlocked ? badgeColor : const Color(0xff475569),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isUnlocked ? Icons.check_circle_rounded : Icons.lock_rounded, size: 14, color: isUnlocked ? badgeColor : const Color(0xff94a3b8)),
                  const SizedBox(width: 6),
                  Text(
                    isUnlocked ? "MEDALI TELAH TERBUKA" : "BELUM DIDAPATKAN",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: isUnlocked ? badgeColor : const Color(0xff94a3b8),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff10b981),
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("TUTUP", style: TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumUpgradeModal(BuildContext context, AppState appState) {
    VipPassModal.show(context);
  }

  IconData _getAvatarIcon(String avatarId) {
    switch (avatarId) {
      case 'bear':
        return Icons.south_west_rounded;
      case 'vip':
        return Icons.workspace_premium_rounded;
      case 'chart':
        return Icons.candlestick_chart_rounded;
      case 'bandar':
        return Icons.visibility_rounded;
      case 'champion':
        return Icons.emoji_events_rounded;
      case 'bull':
      default:
        return Icons.trending_up_rounded;
    }
  }

  Color _getAvatarColor(String avatarId) {
    switch (avatarId) {
      case 'bear':
        return const Color(0xfff87171);
      case 'vip':
        return const Color(0xfff59e0b);
      case 'chart':
        return const Color(0xff38bdf8);
      case 'bandar':
        return const Color(0xffa855f7);
      case 'champion':
        return const Color(0xffeab308);
      case 'bull':
      default:
        return const Color(0xff10b981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      body: Stack(
        children: [
          // Background Image matching main app theme
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xff064e3b).withOpacity(0.9),
                    const Color(0xff0f172a).withOpacity(0.96),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Trader Profile Card 3D
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xff0f172a).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xff059669).withOpacity(0.5), width: 1.4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar Circle with Custom Material Vector Icon
                        GestureDetector(
                          onTap: () => AvatarPickerModal.show(context),
                          child: Stack(
                            children: [
                              Container(
                                width: 94,
                                height: 94,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: appState.isPremium
                                        ? [const Color(0xfff59e0b), const Color(0xfffbbf24)]
                                        : [_getAvatarColor(appState.userAvatar), _getAvatarColor(appState.userAvatar).withOpacity(0.7)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getAvatarColor(appState.userAvatar).withOpacity(0.4),
                                      blurRadius: 14,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xff1e293b),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    _getAvatarIcon(appState.userAvatar),
                                    color: _getAvatarColor(appState.userAvatar),
                                    size: 44,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xff10b981),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Name
                        Text(
                          appState.userName,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Email
                        Text(
                          appState.userEmail,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            color: Color(0xff94a3b8),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Prominent 3D Ganti Avatar Button
                        GestureDetector(
                          onTap: () => AvatarPickerModal.show(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xff059669),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xff10b981), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xff10b981).withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.theater_comedy_rounded, color: Colors.white, size: 15),
                                SizedBox(width: 6),
                                Text(
                                  "GANTI AVATAR 3D 🎭",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Premium Plan Banner Card Widget
                        GestureDetector(
                          onTap: appState.isPremium ? null : () => _showPremiumUpgradeModal(context, appState),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: appState.isPremium
                                  ? const LinearGradient(colors: [Color(0xff1e293b), Color(0xff334155)])
                                  : const LinearGradient(colors: [Color(0xff78350f), Color(0xffea580c)]),
                              border: Border.all(
                                color: appState.isPremium ? Colors.white.withOpacity(0.2) : const Color(0xfff59e0b),
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.workspace_premium_rounded, color: Color(0xfff59e0b), size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appState.isPremium ? "MEMBER PREMIUM" : "AKUN GRATIS",
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        appState.isPremium
                                            ? "Nyawa petir tak terbatas & bebas iklan."
                                            : "Upgrade ke Premium untuk nyawa tak terbatas!",
                                        style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xffcbd5e1)),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!appState.isPremium)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xfff59e0b),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      "UPGRADE",
                                      style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),
                  Row(
                    children: const [
                      Icon(Icons.bar_chart_rounded, color: Color(0xff10b981), size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Statistik Belajar",
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. Stats Grid 3D
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: [
                      _buildStatCard("Total XP", "${appState.xp} XP", iconData: Icons.monetization_on_rounded, color: const Color(0xfff59e0b)),
                      _buildStatCard("XP Hari Ini", "${appState.dailyXp} / 50", iconData: Icons.track_changes_rounded, color: const Color(0xff3b82f6)),
                      _buildStatCard("Streak Belajar", "${appState.streak} Hari", iconData: Icons.local_fire_department_rounded, color: const Color(0xffef4444)),
                      _buildStatCard("Level Selesai", "${appState.completedLevels.length} / 10", iconData: Icons.emoji_events_rounded, color: const Color(0xff10b981)),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: const [
                      Icon(Icons.military_tech_rounded, color: Color(0xfff59e0b), size: 22),
                      SizedBox(width: 8),
                      Text(
                        "Medali Pencapaian",
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3. Hall of Fame Badges Grid 3D
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.88,
                    ),
                    itemCount: _badges.length,
                    itemBuilder: (context, idx) {
                      final badge = _badges[idx];
                      final isUnlocked = appState.unlockedBadges.contains(badge['id']);
                      final IconData iconData = badge['iconData'] as IconData;
                      final Color badgeColor = badge['color'] as Color;

                      return GestureDetector(
                        onTap: () => _showBadgeDetail(context, badge, isUnlocked),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xff0f172a).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isUnlocked ? badgeColor : Colors.white.withOpacity(0.1),
                              width: isUnlocked ? 1.5 : 1.0,
                            ),
                            boxShadow: isUnlocked
                                ? [
                                    BoxShadow(
                                      color: badgeColor.withOpacity(0.25),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isUnlocked ? badgeColor : const Color(0xff475569),
                                    width: isUnlocked ? 2.5 : 1.5,
                                  ),
                                  color: const Color(0xff1e293b),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  iconData,
                                  color: isUnlocked ? badgeColor : const Color(0xff64748b),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                badge['name'],
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.5,
                                  fontWeight: isUnlocked ? FontWeight.w900 : FontWeight.bold,
                                  color: isUnlocked ? Colors.white : const Color(0xff94a3b8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),
                  // 4. Settings & Preferences Section Header
                  Row(
                    children: const [
                      Icon(Icons.settings_rounded, color: Color(0xff3b82f6), size: 22),
                      SizedBox(width: 8),
                      Text(
                        "Pengaturan & Preferensi",
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Settings Card Group
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xff0f172a).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        _buildSettingSwitchTile(
                          icon: Icons.dark_mode_rounded,
                          iconColor: const Color(0xff8b5cf6),
                          title: "Mode Gelap (Theme)",
                          subtitle: "Tampilan dark glassmorphic pro active",
                          value: true,
                          onChanged: (_) {},
                        ),
                        Divider(color: Colors.white.withOpacity(0.08), height: 1),
                        _buildSettingSwitchTile(
                          icon: Icons.notifications_active_rounded,
                          iconColor: const Color(0xfff59e0b),
                          title: "Notifikasi Belajar Harian",
                          subtitle: "Pengingat streak jam 19:00 WIB",
                          value: true,
                          onChanged: (_) {},
                        ),
                        Divider(color: Colors.white.withOpacity(0.08), height: 1),
                        _buildSettingSwitchTile(
                          icon: Icons.volume_up_rounded,
                          iconColor: const Color(0xff10b981),
                          title: "Efek Suara & Haptik",
                          subtitle: "Suara jawaban kuis & getaran",
                          value: true,
                          onChanged: (_) {},
                        ),
                        Divider(color: Colors.white.withOpacity(0.08), height: 1),
                        _buildSettingItemTile(
                          icon: Icons.language_rounded,
                          iconColor: const Color(0xff3b82f6),
                          title: "Bahasa Aplikasi",
                          trailingText: "Bahasa Indonesia 🇮🇩",
                          onTap: () {},
                        ),
                        Divider(color: Colors.white.withOpacity(0.08), height: 1),
                        _buildSettingItemTile(
                          icon: Icons.help_outline_rounded,
                          iconColor: const Color(0xffec4899),
                          title: "Pusat Bantuan & FAQ",
                          trailingText: "Bantuan",
                          onTap: () {},
                        ),
                        Divider(color: Colors.white.withOpacity(0.08), height: 1),
                        _buildSettingItemTile(
                          icon: Icons.privacy_tip_outlined,
                          iconColor: const Color(0xff94a3b8),
                          title: "Kebijakan Privasi & Syarat",
                          trailingText: "Legal",
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. Danger Zone - 3D Pressable LOGOUT BUTTON
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffdc2626),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    onPressed: () => _showLogoutConfirmationDialog(context, appState),
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                    label: const Text(
                      "KELUAR AKUN",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      "Trade Heroes v2.4.0 PRO • Build 2026.08",
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xff64748b)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, {required IconData iconData, required Color color}) {
    return Stack(
      children: [
        Positioned.fill(
          top: 3.5,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xff022c22),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 3.5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xff0f172a).withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(iconData, color: color, size: 20),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(color: color.withOpacity(0.6), blurRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xffcbd5e1)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xff94a3b8))),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xff10b981),
        activeTrackColor: const Color(0xff065f46),
      ),
    );
  }

  Widget _buildSettingItemTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(trailingText, style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xff94a3b8))),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: Color(0xff64748b), size: 18),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff1e293b),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: const Text(
          "Keluar dari Akun?",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Batal", style: TextStyle(fontFamily: 'Inter', color: Color(0xff94a3b8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffdc2626),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              appState.logout();
            },
            child: const Text("Keluar", style: TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
