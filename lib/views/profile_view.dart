import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../state/app_state.dart';
import '../widgets/vip_pass_modal.dart';
import '../widgets/rank_progression_modal.dart';
import '../widgets/xp_reward_modal.dart';
import '../widgets/leaderboard_modal.dart';
import 'admin_console_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _isUploadingAvatar = false;
  bool _showAllBadges = false;

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
    },
    {
      'id': "trader_tier_2",
      'name': "Trader Ritel",
      'desc': "Mencapai 150 XP dan naik pangkat ke Tier II.",
      'iconData': Icons.trending_up_rounded,
      'color': Color(0xfff59e0b),
    },
    {
      'id': "trader_tier_3",
      'name': "Analis Muda",
      'desc': "Mencapai 450 XP dan naik pangkat ke Tier III.",
      'iconData': Icons.query_stats_rounded,
      'color': Color(0xff38bdf8),
    },
    {
      'id': "trader_tier_4",
      'name': "Specialist",
      'desc': "Mencapai 900 XP dan naik pangkat ke Tier IV.",
      'iconData': Icons.psychology_rounded,
      'color': Color(0xff10b981),
    },
    {
      'id': "trader_tier_5",
      'name': "Maestro",
      'desc': "Mencapai 1.600 XP dan meraih gelar tertinggi Tier V!",
      'iconData': Icons.workspace_premium_rounded,
      'color': Color(0xffa855f7),
    },
  ];

  final List<Map<String, dynamic>> _avatars = const [
    { 'id': "bull", 'iconData': Icons.trending_up_rounded, 'name': "Bull", 'cost': 0 },
    { 'id': "chart", 'iconData': Icons.show_chart_rounded, 'name': "Analyst", 'cost': 0 },
    { 'id': "wallet", 'iconData': Icons.account_balance_wallet_rounded, 'name': "Whale", 'cost': 0 },
    { 'id': "vip", 'iconData': Icons.workspace_premium_rounded, 'name': "VIP Gold", 'cost': 0, 'vipOnly': true },
    { 'id': "rocket", 'iconData': Icons.rocket_launch_rounded, 'name': "Breakout", 'cost': 200 },
    { 'id': "shield", 'iconData': Icons.security_rounded, 'name': "Guardian", 'cost': 300 },
    { 'id': "fire", 'iconData': Icons.local_fire_department_rounded, 'name': "Scalper", 'cost': 400 },
    { 'id': "star", 'iconData': Icons.stars_rounded, 'name': "Legend", 'cost': 600 },
    { 'id': "academy", 'iconData': Icons.school_rounded, 'name': "Master", 'cost': 1000 },
  ];

  void _showAvatarSelector(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff0f172a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xff10b981), width: 1.5)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Pilih Avatar Trader", style: TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 18)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xff1e293b),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xfff59e0b).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xfffbbf24), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "${appState.xp} XP",
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xfffbbf24)),
                  ),
                ],
              ),
            ),
          ],
        ),
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
              final avaId = ava['id'] as String;
              final isSelected = appState.userAvatar == avaId;
              final isUnlocked = appState.isAvatarUnlocked(avaId);
              final cost = ava['cost'] as int? ?? 0;
              final isVipOnly = ava['vipOnly'] == true;

              return GestureDetector(
                onTap: () {
                  if (isUnlocked) {
                    Navigator.of(ctx).pop();
                    _showProfileEditPrompt(context, appState, avaId);
                  } else if (isVipOnly) {
                    Navigator.of(ctx).pop();
                    _showPremiumUpgradeModal(context, appState);
                  } else {
                    // Purchase avatar prompt
                    _showAvatarPurchaseDialog(ctx, appState, ava);
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xff059669).withOpacity(0.4)
                            : (isUnlocked ? const Color(0xff1e293b) : const Color(0xff0b0f19)),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xfff59e0b)
                              : (isUnlocked ? Colors.white.withOpacity(0.12) : const Color(0xff334155)),
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
                        color: isSelected
                            ? const Color(0xfff59e0b)
                            : (isUnlocked ? const Color(0xff60a5fa) : const Color(0xff64748b)),
                        size: 32,
                      ),
                    ),
                    if (!isUnlocked)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isVipOnly ? const Color(0xff78350f) : const Color(0xff1e293b),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isVipOnly ? const Color(0xfff59e0b) : const Color(0xff64748b),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            isVipOnly ? "VIP" : "$cost",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isVipOnly ? const Color(0xfffbbf24) : Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAvatarPurchaseDialog(BuildContext parentCtx, AppState appState, Map<String, dynamic> ava) {
    final cost = ava['cost'] as int;
    final name = ava['name'] as String;
    final canClaim = appState.canClaimMilestone(cost);

    showDialog(
      context: parentCtx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: const Color(0xff0f172a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xff334155))),
        title: Text("Buka Avatar $name", style: const TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff1e293b),
                border: Border.all(color: const Color(0xfff59e0b), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Icon(ava['iconData'] as IconData, color: const Color(0xfff59e0b), size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              canClaim
                  ? "Selamat! Total akumulasi belajar Anda telah mencapai $cost XP. Klaim avatar eksklusif ini sekarang secara gratis di Jalur Hadiah!"
                  : "Avatar ini merupakan hadiah Jalur Hadiah di target $cost XP. (XP Anda saat ini: ${appState.xp} XP). Terus belajar untuk membuka hadiah ini!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xffcbd5e1), height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text("Tutup", style: TextStyle(color: Color(0xff94a3b8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xfff59e0b)),
            onPressed: () {
              Navigator.of(dCtx).pop();
              Navigator.of(parentCtx).pop();
              XpRewardModal.show(context);
            },
            child: const Text(
              "Buka Jalur Hadiah 🎁",
              style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
        ],
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

  void _showBgmPickerDialog(BuildContext context, AppState appState) {
    final iconMap = {
      'default': Icons.piano_rounded,
      'ambient_piano': Icons.blur_on_rounded,
      'gentle_piano': Icons.spa_rounded,
      'chill_piano': Icons.wb_twilight_rounded,
      'lofi_study': Icons.headphones_rounded,
      'jazz_cafe': Icons.local_cafe_rounded,
      'deep_space': Icons.auto_awesome_rounded,
      'rain_meditation': Icons.water_rounded,
    };
    final colorMap = {
      'default': const Color(0xff10b981),
      'ambient_piano': const Color(0xff60a5fa),
      'gentle_piano': const Color(0xffa78bfa),
      'chill_piano': const Color(0xfffbbf24),
      'lofi_study': const Color(0xffec4899),
      'jazz_cafe': const Color(0xfff97316),
      'deep_space': const Color(0xff818cf8),
      'rain_meditation': const Color(0xff22d3ee),
    };

    String? previewingTrack;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xff1e293b),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text(
              "Pilih Musik Latar",
              style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: AudioService.availableBgms.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, idx) {
                  final track = AudioService.availableBgms[idx];
                  final isSelected = appState.bgmTrack == track;
                  final isPreviewing = previewingTrack == track;
                  return ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: isSelected ? const Color(0xff064e3b) : const Color(0xff0f172a),
                    leading: Icon(
                      iconMap[track] ?? Icons.music_note_rounded,
                      color: colorMap[track] ?? Colors.white,
                      size: 26,
                    ),
                    title: Text(
                      AudioService.bgmLabels[track] ?? track,
                      style: const TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      AudioService.bgmDescriptions[track] ?? '',
                      style: TextStyle(fontFamily: 'Outfit', color: Colors.white.withOpacity(0.5), fontSize: 11),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (isPreviewing) {
                              // Stop preview
                              AudioService.stopPreview();
                              setDialogState(() { previewingTrack = null; });
                            } else {
                              // Stop any current preview, start new one
                              AudioService.stopPreview();
                              setDialogState(() { previewingTrack = track; });
                              AudioService.previewBgm(track);
                              // Auto-reset icon after 8s (preview duration)
                              Future.delayed(const Duration(seconds: 9), () {
                                if (previewingTrack == track) {
                                  setDialogState(() { previewingTrack = null; });
                                }
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isPreviewing
                                  ? (colorMap[track] ?? Colors.white).withOpacity(0.2)
                                  : Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isPreviewing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                              color: colorMap[track],
                              size: 18,
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle_rounded, color: Color(0xff10b981), size: 22),
                        ],
                      ],
                    ),
                    onTap: () {
                      appState.setBgmTrack(track);
                      setDialogState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Musik latar: ${AudioService.bgmLabels[track]}"),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Stop any preview when closing
                  if (previewingTrack != null) {
                    AudioService.stopPreview();
                  }
                  Navigator.of(ctx).pop();
                },
                child: const Text("TUTUP", style: TextStyle(color: Color(0xff10b981), fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLanguageSelectorDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Pilih Bahasa Aplikasi",
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: appState.language == 'id' ? const Color(0xff064e3b) : null,
              title: const Text("Bahasa Indonesia", style: TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: appState.language == 'id' ? const Icon(Icons.check_circle_rounded, color: Color(0xff10b981)) : null,
              onTap: () {
                appState.setLanguage('id');
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Bahasa disetel ke Bahasa Indonesia")),
                );
              },
            ),
            const SizedBox(height: 6),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: appState.language == 'en' ? const Color(0xff064e3b) : null,
              title: const Text("English (US)", style: TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: appState.language == 'en' ? const Icon(Icons.check_circle_rounded, color: Color(0xff10b981)) : null,
              onTap: () {
                appState.setLanguage('en');
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Language set to English (US)")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFaqModal(BuildContext context) {
    final faqs = [
      {
        'q': "Bagaimana cara kerja Sistem Nyawa Petir?",
        'a': "Pengguna memiliki 5 nyawa petir. Menjawab salah kuis akan mengurangi 1 petir. Petir pulih otomatis 1 poin setiap 60 detik atau dapat diisi ulang instan lewat tontonan iklan simulasi / VIP Pass."
      },
      {
        'q': "Apa saja keuntungan VIP Gold Pass?",
        'a': "VIP Gold Pass memberikan Nyawa Tak Terbatas (∞ Petir), bebas dari penayangan iklan pop-up, serta akses eksklusif ke seluruh modul analisis materi."
      },
      {
        'q': "Apakah simulator pasar saham ini menggunakan uang sungguhan?",
        'a': "Tidak. Trade Heroes adalah platform simulasi dan edukasi pasar modal murni. Seluruh transaksi, saldo kas virtual, dan kuis tidak melibatkan uang atau risiko finansial nyata."
      },
      {
        'q': "Bagaimana cara mempertahankan Streak Belajar?",
        'a': "Selesaikan minimal 1 kuis atau selesaikan membaca 1 modul materi setiap hari sebelum pukul 23:59 WIB untuk mempertahankan dan menaikkan streak berturut-turut Anda."
      },
      {
        'q': "Bagaimana data saya tersimpan?",
        'a': "Data progress, XP, streak, dan medali Anda otomatis tersimpan di cloud terenkripsi Supabase sehingga dapat diakses antar-perangkat kapan saja."
      }
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff0f172a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xff475569),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Icon(Icons.help_outline_rounded, color: Color(0xffec4899), size: 22),
                  SizedBox(width: 8),
                  Text(
                    "Pusat Bantuan & FAQ",
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Pertanyaan umum seputar fitur & panduan Trade Heroes",
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xff94a3b8)),
              ),
              const SizedBox(height: 16),
              ...faqs.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xff1e293b),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  title: Text(
                    f['q']!,
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  children: [
                    Text(
                      f['a']!,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xffcbd5e1), height: 1.45),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xff064e3b),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xff10b981), width: 1.2),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.mail_outline_rounded, color: Color(0xff34d399), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Butuh bantuan lain? Hubungi Tim Support kami di support@tradeheroes.app",
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xffa7f3d0)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff0f172a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xff475569),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Icon(Icons.privacy_tip_outlined, color: Color(0xff94a3b8), size: 22),
                  SizedBox(width: 8),
                  Text(
                    "Kebijakan Privasi & Syarat Ketentuan",
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xff1e293b),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "1. Penyangkalan Tanggung Jawab Finansial (Disclaimer)",
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xfff59e0b)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Seluruh materi, simulasi trading, grafik candlestick, dan data pasar modal yang disajikan dalam aplikasi Trade Heroes bersifat semata-mata untuk tujuan edukasi dan literasi keuangan. Aplikasi ini TIDAK menyediakan saran investasi, rekomendasi saham tertentu, maupun ajakan membeli/menjual efek resmi di BEI.",
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xffcbd5e1), height: 1.4),
                    ),
                    SizedBox(height: 14),
                    Text(
                      "2. Pengumpulan & Keamanan Data Pengguna",
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff34d399)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Kami menghormati privasi Anda. Data profil, alamat email, dan progres kuis disimpan secara aman menggunakan enkripsi Row Level Security (RLS) di server Supabase. Kami tidak menjual atau membagikan data pribadi Anda kepada pihak ketiga manapun untuk tujuan periklanan.",
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xffcbd5e1), height: 1.4),
                    ),
                    SizedBox(height: 14),
                    Text(
                      "3. Hak Cipta & Konten Edukasi",
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff60a5fa)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Seluruh kurikulum soal kuis, modul materi pasar modal, dan ilustrasi visual dilindungi oleh hak cipta pengembang platform Trade Heroes. Penggunaan konten tanpa izin untuk kepentingan komersial tidak diperkenankan.",
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xffcbd5e1), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff059669),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 44),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("SAYA MENGERTI", style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context, AppState appState) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingAvatar = true);

      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last.toLowerCase();
      final safeExt = ['png', 'jpg', 'jpeg', 'webp'].contains(ext) ? ext : 'png';

      final success = await appState.uploadAndSetCustomAvatar(bytes, safeExt);

      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xff059669),
              content: Text("Foto profil berhasil diperbarui!"),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xffdc2626),
              content: Text("Gagal mengunggah foto profil, silakan coba lagi."),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xffdc2626),
            content: Text("Terjadi kesalahan: $e"),
          ),
        );
      }
    }
  }

  Widget _buildAvatarImage(String avatar, Color fallbackColor) {
    if (avatar.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          avatar,
          width: 86,
          height: 86,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.person_rounded, color: fallbackColor, size: 42);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Color(0xff10b981), strokeWidth: 2),
              ),
            );
          },
        ),
      );
    } else if (avatar.startsWith('data:image')) {
      try {
        final b64 = avatar.split(',').last;
        final bytes = base64Decode(b64);
        return ClipOval(
          child: Image.memory(
            bytes,
            width: 86,
            height: 86,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        return Icon(Icons.person_rounded, color: fallbackColor, size: 42);
      }
    } else {
      return Icon(
        _getAvatarIcon(avatar),
        color: fallbackColor,
        size: 42,
      );
    }
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
    if (avatarId.startsWith('http') || avatarId.startsWith('data:image')) {
      return const Color(0xff10b981);
    }
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
                        // Avatar Circle with Custom Photo Picker
                        GestureDetector(
                          onTap: _isUploadingAvatar ? null : () => _pickAndUploadAvatar(context, appState),
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
                                  child: _isUploadingAvatar
                                      ? const SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: CircularProgressIndicator(color: Color(0xff10b981), strokeWidth: 2.5),
                                        )
                                      : _buildAvatarImage(appState.userAvatar, _getAvatarColor(appState.userAvatar)),
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
                                  child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
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
                        const SizedBox(height: 10),

                        // Trader Rank Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (appState.currentRank['color'] as Color).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (appState.currentRank['color'] as Color).withOpacity(0.5),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                appState.currentRank['icon'] as IconData,
                                color: appState.currentRank['color'] as Color,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "TIER ${appState.currentRank['roman']} • ${(appState.currentRank['title'] as String).toUpperCase()}",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: appState.currentRank['color'] as Color,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Trader Rank & XP Progression Card
                        GestureDetector(
                          onTap: () {
                            AudioService.playClick();
                            RankProgressionModal.show(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xff161f30),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: (appState.currentRank['color'] as Color).withOpacity(0.35),
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.military_tech_rounded,
                                          color: appState.currentRank['color'] as Color,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          "Jenjang Karier Trader",
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "${appState.xp} XP",
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w900,
                                            color: appState.currentRank['color'] as Color,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Color(0xff94a3b8),
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: LinearProgressIndicator(
                                    value: appState.rankProgress.clamp(0.0, 1.0),
                                    minHeight: 6,
                                    backgroundColor: const Color(0xff0b0f19),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      appState.currentRank['color'] as Color,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      appState.currentRank['title'] as String,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10.5,
                                        color: Color(0xff94a3b8),
                                      ),
                                    ),
                                    Text(
                                      appState.nextRank != null
                                          ? "Kurang ${appState.xpToNextRank} XP lagi (${(appState.rankProgress * 100).toInt()}%)"
                                          : "Gelar Tertinggi ✓",
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: appState.currentRank['color'] as Color,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Jalur Hadiah XP Banner (Milestone Rewards Track)
                        GestureDetector(
                          onTap: () {
                            AudioService.playClick();
                            XpRewardModal.show(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xff1e293b), Color(0xff0f172a)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: appState.unclaimedMilestonesCount > 0
                                    ? const Color(0xfff59e0b)
                                    : Colors.white.withOpacity(0.08),
                                width: appState.unclaimedMilestonesCount > 0 ? 1.5 : 1.0,
                              ),
                              boxShadow: appState.unclaimedMilestonesCount > 0
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xfff59e0b).withOpacity(0.2),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xfff59e0b).withOpacity(0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.card_giftcard_rounded, color: Color(0xfffbbf24), size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            "Jalur Hadiah XP",
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          if (appState.unclaimedMilestonesCount > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xff10b981),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                "${appState.unclaimedMilestonesCount} Hadiah Siap!",
                                                style: const TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            )
                                          else
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: const Color(0xfff59e0b).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                "${appState.xp} XP",
                                                style: const TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xfffbbf24),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        "Buka nyawa, pelindung streak & avatar saat XP naik.",
                                        style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xff94a3b8)),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xfffbbf24), size: 13),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      GestureDetector(
                        onTap: () {
                          AudioService.playClick();
                          LeaderboardModal.show(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xfff59e0b).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xfff59e0b).withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events_rounded, color: Color(0xfffbbf24), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                "Liga #${appState.userLeaderboardRank}",
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xfffbbf24),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                      _buildStatCard(
                        "Total XP",
                        "${appState.xp} XP",
                        iconData: appState.currentRank['icon'] as IconData,
                        color: appState.currentRank['color'] as Color,
                        subtitle: "Tier ${appState.currentRank['roman']} • ${appState.currentRank['title']}",
                        onTap: () {
                          AudioService.playClick();
                          RankProgressionModal.show(context);
                        },
                      ),
                      _buildStatCard("XP Hari Ini", "${appState.dailyXp} / 50", iconData: Icons.track_changes_rounded, color: const Color(0xff3b82f6)),
                      _buildStatCard("Streak Belajar", "${appState.streak} Hari", iconData: Icons.local_fire_department_rounded, color: const Color(0xffef4444)),
                      _buildStatCard("Level Selesai", "${appState.completedLevels.length} / 10", iconData: Icons.emoji_events_rounded, color: const Color(0xff10b981)),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.military_tech_rounded, color: Color(0xfff59e0b), size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            "Medali Pencapaian",
                            style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xff1e293b),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Text(
                              "${appState.unlockedBadges.length}/${_badges.length}",
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff94a3b8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          AudioService.playClick();
                          setState(() {
                            _showAllBadges = !_showAllBadges;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _showAllBadges ? "Ringkas" : "Lihat Semua",
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff38bdf8),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                _showAllBadges ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                color: const Color(0xff38bdf8),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3. Hall of Fame Badges Grid (Compact 4 columns, limited preview)
                  Builder(
                    builder: (context) {
                      // Urutkan: yang sudah terbuka di depan
                      final sortedBadges = List<Map<String, dynamic>>.from(_badges);
                      sortedBadges.sort((a, b) {
                        final aUnlocked = appState.unlockedBadges.contains(a['id']);
                        final bUnlocked = appState.unlockedBadges.contains(b['id']);
                        if (aUnlocked && !bUnlocked) return -1;
                        if (!aUnlocked && bUnlocked) return 1;
                        return 0;
                      });

                      final displayedBadges = _showAllBadges ? sortedBadges : sortedBadges.take(4).toList();

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: displayedBadges.length,
                        itemBuilder: (context, idx) {
                          final badge = displayedBadges[idx];
                          final isUnlocked = appState.unlockedBadges.contains(badge['id']);
                          final IconData iconData = badge['iconData'] as IconData;
                          final Color badgeColor = badge['color'] as Color;

                          return GestureDetector(
                            onTap: () => _showBadgeDetail(context, badge, isUnlocked),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xff0f172a).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isUnlocked ? badgeColor.withOpacity(0.8) : Colors.white.withOpacity(0.06),
                                  width: isUnlocked ? 1.2 : 0.8,
                                ),
                                boxShadow: isUnlocked
                                    ? [
                                        BoxShadow(
                                          color: badgeColor.withOpacity(0.2),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isUnlocked ? badgeColor : const Color(0xff334155),
                                        width: isUnlocked ? 2.0 : 1.0,
                                      ),
                                      color: const Color(0xff1e293b),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      iconData,
                                      color: isUnlocked ? badgeColor : const Color(0xff475569),
                                      size: 19,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    badge['name'],
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 10,
                                      fontWeight: isUnlocked ? FontWeight.w800 : FontWeight.w600,
                                      color: isUnlocked ? Colors.white : const Color(0xff64748b),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Admin Console Command Card (Only visible to Admin)
                  if (appState.isAdmin) ...[
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminConsoleView()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xff78350f), Color(0xff1e293b)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xfff59e0b), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xfff59e0b).withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xfff59e0b).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xfffbbf24), size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "Admin Console & CMS",
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "Kelola trader, status VIP, kurikulum, & metrik",
                                    style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xffcbd5e1)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xfffbbf24), size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

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
                          subtitle: appState.darkMode ? "Tampilan slate dark glassmorphic pro aktif" : "Mode terang diaktifkan",
                          value: appState.darkMode,
                          onChanged: (val) {
                            appState.toggleDarkMode(val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(val ? "Mode Gelap diaktifkan" : "Mode Terang diaktifkan"),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        Divider(color: Colors.white.withOpacity(0.08), height: 1),
                        _buildSettingSwitchTile(
                          icon: Icons.notifications_active_rounded,
                          iconColor: const Color(0xfff59e0b),
                          title: "Notifikasi Belajar Harian",
                          subtitle: appState.dailyReminder ? "Pengingat streak jam 19:00 WIB aktif" : "Pengingat dinonaktifkan",
                          value: appState.dailyReminder,
                          onChanged: (val) {
                            appState.toggleDailyReminder(val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(val ? "Pengingat belajar aktif (19:00 WIB)" : "Pengingat belajar dinonaktifkan"),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        Divider(color: Colors.white.withOpacity(0.08), height: 1),
                        _buildSettingSwitchTile(
                          icon: Icons.volume_up_rounded,
                          iconColor: const Color(0xff10b981),
                          title: "Efek Suara & Haptik",
                          subtitle: appState.soundHaptic ? "Suara kuis & getaran sentuhan aktif" : "Efek suara & getaran nonaktif",
                          value: appState.soundHaptic,
                          onChanged: (val) {
                            appState.toggleSoundHaptic(val);
                            if (val) HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(val ? "Efek suara & haptik diaktifkan" : "Efek suara & haptik dinonaktifkan"),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        Divider(color: Colors.white.withOpacity(0.08), height: 1),
                        _buildSettingSwitchTile(
                          icon: Icons.music_note_rounded,
                          iconColor: const Color(0xff06b6d4),
                          title: "Musik Latar (Lo-Fi BGM)",
                          subtitle: appState.bgmEnabled ? "Musik ambient santai aktif" : "Musik latar dinonaktifkan",
                          value: appState.bgmEnabled,
                          onChanged: (val) {
                            appState.toggleBgm(val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(val ? "Musik latar Lo-Fi diaktifkan" : "Musik latar dimatikan"),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        Divider(color: Colors.white.withOpacity(0.08), height: 1),
                        _buildSettingItemTile(
                          icon: Icons.library_music_rounded,
                          iconColor: const Color(0xff8b5cf6),
                          title: "Pilih Musik Latar",
                          trailingText: AudioService.bgmLabels[appState.bgmTrack] ?? "Default",
                          onTap: () => _showBgmPickerDialog(context, appState),
                        ),
                        Divider(color: Colors.white.withOpacity(0.08), height: 1),
                        _buildSettingItemTile(
                          icon: Icons.language_rounded,
                          iconColor: const Color(0xff3b82f6),
                          title: "Bahasa Aplikasi",
                          trailingText: appState.language == 'id' ? "Bahasa Indonesia" : "English (US)",
                          onTap: () => _showLanguageSelectorDialog(context, appState),
                        ),
                        Divider(color: Colors.white.withOpacity(0.08), height: 1),
                        _buildSettingItemTile(
                          icon: Icons.help_outline_rounded,
                          iconColor: const Color(0xffec4899),
                          title: "Pusat Bantuan & FAQ",
                          trailingText: "Bantuan",
                          onTap: () => _showFaqModal(context),
                        ),
                        Divider(color: Colors.white.withOpacity(0.08), height: 1),
                        _buildSettingItemTile(
                          icon: Icons.privacy_tip_outlined,
                          iconColor: const Color(0xff94a3b8),
                          title: "Kebijakan Privasi & Syarat",
                          trailingText: "Legal",
                          onTap: () => _showPrivacyPolicyModal(context),
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

  Widget _buildStatCard(
    String label,
    String value, {
    required IconData iconData,
    required Color color,
    VoidCallback? onTap,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
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
                  subtitle ?? label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xffcbd5e1)),
                ),
              ],
            ),
          ),
        ],
      ),
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
        onChanged: (newVal) {
          AudioService.playClick();
          onChanged(newVal);
        },
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
      onTap: () {
        AudioService.playClick();
        onTap();
      },
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
