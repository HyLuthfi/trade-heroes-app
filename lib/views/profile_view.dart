import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../data/avatar_data.dart';
import '../l10n/app_translations.dart';
import '../services/audio_service.dart';
import '../state/app_state.dart';
import '../widgets/avatar_picker_modal.dart';
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

  String _tr(AppState appState, String key, {Map<String, String> params = const {}}) {
    return AppTranslations.text(appState.language, key, params: params);
  }

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

  void _showProfileEditPrompt(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nameController = TextEditingController(text: appState.userName);
    String currentAvatar = appState.userAvatar;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xff1e293b) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xffe2e8f0),
              width: 1.2,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xff10b981).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_rounded, color: Color(0xff10b981), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _tr(appState, 'profile.edit_name'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: isDark ? Colors.white : const Color(0xff0f172a),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr(appState, 'profile.edit_name_desc'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  maxLength: 25,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xff0f172a),
                  ),
                  decoration: InputDecoration(
                    labelText: _tr(appState, 'profile.name_label'),
                    labelStyle: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xff0f172a) : const Color(0xfff8fafc),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xff334155) : const Color(0xffcbd5e1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xff10b981), width: 1.8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _tr(appState, 'profile.avatar_picker'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xff0f172a),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 56,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AvatarData.avatars.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final ava = AvatarData.avatars[idx];
                      final isSelected = currentAvatar == ava.id;
                      return GestureDetector(
                        onTap: () {
                          AudioService.playClick();
                          setDialogState(() {
                            currentAvatar = ava.id;
                          });
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? ava.color.withOpacity(0.25)
                                : (isDark ? const Color(0xff0f172a) : const Color(0xfff1f5f9)),
                            border: Border.all(
                              color: isSelected ? ava.color : Colors.transparent,
                              width: 2.2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            ava.icon,
                            color: isSelected ? ava.color : (isDark ? Colors.white70 : const Color(0xff475569)),
                            size: 24,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    currentAvatar.startsWith('http') || currentAvatar.startsWith('data:image')
                        ? (appState.language == 'en' ? 'Custom Photo' : 'Foto Kustom')
                        : AvatarData.getTitle(currentAvatar, appState.language),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: currentAvatar.startsWith('http') || currentAvatar.startsWith('data:image')
                          ? const Color(0xff10b981)
                          : AvatarData.getColor(currentAvatar),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                _tr(appState, 'profile.cancel'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff10b981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(_tr(appState, 'profile.name_empty')),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                  return;
                }
                Navigator.of(ctx).pop();
                AudioService.playReward();
                appState.updateProfile(
                  name: newName,
                  email: appState.userEmail,
                  avatar: currentAvatar,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text(_tr(appState, 'profile.name_updated')),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
              label: Text(
                _tr(appState, 'profile.save'),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetail(BuildContext context, Map<String, dynamic> badge, bool isUnlocked) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final IconData iconData = badge['iconData'] as IconData;
    final Color badgeColor = badge['color'] as Color;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xff0f172a) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isUnlocked
                ? badgeColor
                : (isDark ? const Color(0xff334155) : const Color(0xffe2e8f0)),
            width: 1.5,
          ),
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
                  color: isUnlocked
                      ? badgeColor
                      : (isDark ? const Color(0xff475569) : const Color(0xffcbd5e1)),
                  width: isUnlocked ? 3.5 : 2,
                ),
                color: isDark ? const Color(0xff1e293b) : const Color(0xfff8fafc),
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
                child: Icon(iconData,
                    color: isUnlocked
                        ? badgeColor
                        : (isDark ? const Color(0xff64748b) : const Color(0xff94a3b8)),
                    size: 42),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge['name'],
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xff0f172a),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge['desc'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: isDark ? const Color(0xffcbd5e1) : const Color(0xff475569),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? badgeColor.withOpacity(0.2)
                    : (isDark ? const Color(0xff1e293b) : const Color(0xfff1f5f9)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isUnlocked
                      ? badgeColor
                      : (isDark ? const Color(0xff475569) : const Color(0xffcbd5e1)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUnlocked ? Icons.check_circle_rounded : Icons.lock_rounded,
                    size: 14,
                    color: isUnlocked
                        ? badgeColor
                        : (isDark ? const Color(0xff94a3b8) : const Color(0xff64748b)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isUnlocked ? "MEDALI TELAH TERBUKA" : "BELUM DIDAPATKAN",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: isUnlocked
                          ? badgeColor
                          : (isDark ? const Color(0xff94a3b8) : const Color(0xff64748b)),
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
              child: const Text("TUTUP",
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontWeight: FontWeight.w900)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            backgroundColor: isDark ? const Color(0xff1e293b) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xffe2e8f0),
              ),
            ),
            title: Text(
              _tr(appState, 'settings.choose_bgm'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xff0f172a),
              ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xff10b981)
                            : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0)),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    tileColor: isSelected
                        ? (isDark ? const Color(0xff064e3b) : const Color(0xffd1fae5))
                        : (isDark ? const Color(0xff0f172a) : const Color(0xfff8fafc)),
                    leading: Icon(
                      iconMap[track] ?? Icons.music_note_rounded,
                      color: colorMap[track] ?? Colors.white,
                      size: 26,
                    ),
                    title: Text(
                      AudioService.bgmLabels[track] ?? track,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: isDark ? Colors.white : const Color(0xff0f172a),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      AudioService.bgmDescriptions[track] ?? '',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                        fontSize: 11,
                      ),
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
                                  : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0)),
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
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            _tr(appState, 'settings.bgm_selected', params: {'track': AudioService.bgmLabels[track] ?? track}),
                          ),
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
                child: Text(_tr(appState, 'profile.close'), style: const TextStyle(color: Color(0xff10b981), fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLanguageSelectorDialog(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xff1e293b) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.12) : colors.outlineVariant.withOpacity(0.4),
            width: 1.2,
          ),
        ),
        title: Text(
          _tr(appState, 'settings.language'),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xff0f172a),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Option 1: Bahasa Indonesia
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  try {
                    AudioService.playClick();
                  } catch (_) {}
                  Navigator.of(ctx).pop();
                  appState.setLanguage('id');
                  if (mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: isDark ? const Color(0xff064e3b) : const Color(0xff10b981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppTranslations.text('id', 'settings.language_saved_id'),
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: appState.language == 'id'
                        ? (isDark ? const Color(0xff064e3b) : const Color(0xffd1fae5))
                        : (isDark ? const Color(0xff0f172a).withOpacity(0.5) : const Color(0xfff1f5f9)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: appState.language == 'id'
                          ? const Color(0xff10b981)
                          : (isDark ? Colors.white.withOpacity(0.08) : colors.outlineVariant.withOpacity(0.3)),
                      width: appState.language == 'id' ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text("🇮🇩", style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _tr(appState, 'settings.language_id'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: appState.language == 'id' ? FontWeight.w900 : FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xff0f172a),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (appState.language == 'id')
                        const Icon(Icons.check_circle_rounded, color: Color(0xff10b981), size: 22),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Option 2: English (US)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  try {
                    AudioService.playClick();
                  } catch (_) {}
                  Navigator.of(ctx).pop();
                  appState.setLanguage('en');
                  if (mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: isDark ? const Color(0xff064e3b) : const Color(0xff10b981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppTranslations.text('en', 'settings.language_saved_en'),
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: appState.language == 'en'
                        ? (isDark ? const Color(0xff064e3b) : const Color(0xffd1fae5))
                        : (isDark ? const Color(0xff0f172a).withOpacity(0.5) : const Color(0xfff1f5f9)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: appState.language == 'en'
                          ? const Color(0xff10b981)
                          : (isDark ? Colors.white.withOpacity(0.08) : colors.outlineVariant.withOpacity(0.3)),
                      width: appState.language == 'en' ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text("🇺🇸", style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _tr(appState, 'settings.language_en'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: appState.language == 'en' ? FontWeight.w900 : FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xff0f172a),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (appState.language == 'en')
                        const Icon(Icons.check_circle_rounded, color: Color(0xff10b981), size: 22),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              _tr(appState, 'profile.close'),
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Color(0xff10b981),
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationBlockedDialog(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xff1e293b) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.notifications_off_rounded, color: Color(0xfff59e0b), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _tr(appState, 'settings.notification_blocked_title'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xff0f172a),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          _tr(appState, 'settings.notification_blocked_desc'),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: isDark ? const Color(0xffcbd5e1) : const Color(0xff475569),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              _tr(appState, 'profile.close'),
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Color(0xff10b981),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReminderTimePickerDialog(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final presetHours = [
      {'hour': 8, 'labelKey': 'settings.reminder_time_8'},
      {'hour': 16, 'labelKey': 'settings.reminder_time_16'},
      {'hour': 19, 'labelKey': 'settings.reminder_time_19'},
      {'hour': 20, 'labelKey': 'settings.reminder_time_20'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xff1e293b) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xffe2e8f0),
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.access_time_filled_rounded, color: Color(0xfff59e0b), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _tr(appState, 'settings.reminder_time_title'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xff0f172a),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: presetHours.map((preset) {
            final h = preset['hour'] as int;
            final isSelected = appState.reminderHour == h;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0xff78350f).withOpacity(0.4) : const Color(0xfffef3c7))
                    : (isDark ? const Color(0xff0f172a) : const Color(0xfff8fafc)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xfff59e0b)
                      : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0)),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: ListTile(
                dense: true,
                onTap: () {
                  AudioService.playClick();
                  appState.setReminderHour(h);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        '${_tr(appState, 'settings.reminder_time')}: ${h.toString().padLeft(2, '0')}:00 WIB',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                leading: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? const Color(0xfff59e0b) : (isDark ? const Color(0xff64748b) : const Color(0xff94a3b8)),
                  size: 20,
                ),
                title: Text(
                  _tr(appState, preset['labelKey'] as String),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xff0f172a),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              _tr(appState, 'profile.close'),
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Color(0xff10b981),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFaqModal(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final appState = Provider.of<AppState>(context, listen: false);
    final isEn = appState.language == 'en';

    final faqs = isEn
        ? [
            {
              'q': "How does the Lightning Lives system work?",
              'a': "Users have 5 lightning lives. Answering a quiz question incorrectly deducts 1 life. Lives recharge automatically at 1 point every 60 seconds, or can be refilled instantly via simulated ads or VIP Pass."
            },
            {
              'q': "What are the benefits of VIP Gold Pass?",
              'a': "VIP Gold Pass grants Unlimited Lives (∞ Lightning), completely ad-free learning, and exclusive access to all premium learning and strategy modules."
            },
            {
              'q': "Does this stock market simulator use real money?",
              'a': "No. Trade Heroes is strictly an educational stock market simulation platform. All transactions, virtual cash balances, and quizzes involve no real money or financial risk."
            },
            {
              'q': "How do I maintain my Learning Streak?",
              'a': "Complete at least 1 quiz or finish reading 1 module daily before 23:59 WIB to maintain and increase your streak."
            },
            {
              'q': "How is my progress saved?",
              'a': "Your progress, XP, streak, and badges are automatically saved in the encrypted Supabase cloud, accessible across all your devices anytime."
            }
          ]
        : [
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
      backgroundColor: isDark ? const Color(0xff0f172a) : Colors.white,
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
                    color: isDark ? const Color(0xff475569) : const Color(0xffcbd5e1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.help_outline_rounded, color: Color(0xffec4899), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    _tr(appState, 'profile.help_faq'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xff0f172a),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isEn
                    ? "Frequently asked questions about Trade Heroes features & guides"
                    : "Pertanyaan umum seputar fitur & panduan Trade Heroes",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                ),
              ),
              const SizedBox(height: 16),
              ...faqs.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff1e293b) : const Color(0xfff8fafc),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : colors.outlineVariant.withOpacity(0.4),
                  ),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  title: Text(
                    f['q']!,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xff0f172a),
                    ),
                  ),
                  children: [
                    Text(
                      f['a']!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: isDark ? const Color(0xffcbd5e1) : const Color(0xff334155),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff064e3b) : const Color(0xffecfdf5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xff10b981), width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mail_outline_rounded, color: Color(0xff10b981), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isEn
                            ? "Need more help? Contact our Support Team at support@tradeheroes.app"
                            : "Butuh bantuan lain? Hubungi Tim Support kami di support@tradeheroes.app",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: isDark ? const Color(0xffa7f3d0) : const Color(0xff065f46),
                        ),
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final appState = Provider.of<AppState>(context, listen: false);
    final isEn = appState.language == 'en';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xff0f172a) : Colors.white,
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
                    color: isDark ? const Color(0xff475569) : const Color(0xffcbd5e1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.privacy_tip_outlined, color: Color(0xff94a3b8), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    isEn ? "Privacy Policy & Terms of Service" : "Kebijakan Privasi & Syarat Ketentuan",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xff0f172a),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff1e293b) : const Color(0xfff8fafc),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : colors.outlineVariant.withOpacity(0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn
                          ? "1. Financial Responsibility Disclaimer"
                          : "1. Penyangkalan Tanggung Jawab Finansial (Disclaimer)",
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xfff59e0b),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEn
                          ? "All materials, trading simulations, candlestick charts, and market data presented in Trade Heroes are solely for educational and financial literacy purposes. This application DOES NOT provide investment advice, specific stock recommendations, or solicitations to buy/sell official securities on the IDX."
                          : "Seluruh materi, simulasi trading, grafik candlestick, dan data pasar modal yang disajikan dalam aplikasi Trade Heroes bersifat semata-mata untuk tujuan edukasi dan literasi keuangan. Aplikasi ini TIDAK menyediakan saran investasi, rekomendasi saham tertentu, maupun ajakan membeli/menjual efek resmi di BEI.",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: isDark ? const Color(0xffcbd5e1) : const Color(0xff334155),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isEn
                          ? "2. User Data Collection & Security"
                          : "2. Pengumpulan & Keamanan Data Pengguna",
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff34d399),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEn
                          ? "We respect your privacy. Profile data, email addresses, and quiz progress are securely stored using Row Level Security (RLS) encryption on Supabase servers. We never sell or share your personal data with any third party for advertising purposes."
                          : "Kami menghormati privasi Anda. Data profil, alamat email, dan progres kuis disimpan secara aman menggunakan enkripsi Row Level Security (RLS) di server Supabase. Kami tidak menjual atau membagikan data pribadi Anda kepada pihak ketiga manapun untuk tujuan periklanan.",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: isDark ? const Color(0xffcbd5e1) : const Color(0xff334155),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isEn
                          ? "3. Copyright & Educational Content"
                          : "3. Hak Cipta & Konten Edukasi",
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff60a5fa),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEn
                          ? "All quiz curricula, stock market educational modules, and visual illustrations are protected by the copyright of Trade Heroes developers. Unauthorized use of content for commercial purposes is prohibited."
                          : "Seluruh kurikulum soal kuis, modul materi pasar modal, dan ilustrasi visual dilindungi oleh hak cipta pengembang platform Trade Heroes. Penggunaan konten tanpa izin untuk kepentingan komersial tidak diperkenankan.",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: isDark ? const Color(0xffcbd5e1) : const Color(0xff334155),
                        height: 1.4,
                      ),
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
                child: Text(
                  isEn ? "I UNDERSTAND" : "SAYA MENGERTI",
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
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
    return AvatarData.getIcon(avatarId);
  }

  Color _getAvatarColor(String avatarId) {
    return AvatarData.getColor(avatarId);
  }

  void _showAvatarOptionsSheet(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEn = appState.language == 'en';
    final hasCustomPhoto = appState.userAvatar.startsWith('http') || appState.userAvatar.startsWith('data:image');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff0f172a) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xffe2e8f0),
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xffcbd5e1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _tr(appState, 'profile.avatar_picker'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xff0f172a),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xff10b981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.theater_comedy_rounded, color: Color(0xff10b981), size: 22),
              ),
              title: Text(
                isEn ? "Choose Character Avatar" : "Pilih Karakter Avatar 3D",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xff0f172a),
                ),
              ),
              subtitle: Text(
                isEn ? "Select from 12 trader character avatars" : "Pilih dari 12 karakter trader Trade Heroes",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xff94a3b8)),
              onTap: () {
                Navigator.of(ctx).pop();
                AvatarPickerModal.show(context);
              },
            ),
            const SizedBox(height: 6),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xff3b82f6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_camera_rounded, color: Color(0xff3b82f6), size: 22),
              ),
              title: Text(
                isEn ? "Upload Custom Photo" : "Unggah Foto dari Galeri",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xff0f172a),
                ),
              ),
              subtitle: Text(
                isEn ? "Choose an image file from your device" : "Pilih file gambar dari penyimpanan perangkat",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xff94a3b8)),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickAndUploadAvatar(context, appState);
              },
            ),
            if (hasCustomPhoto) ...[
              const SizedBox(height: 6),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xfff59e0b).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.restore_rounded, color: Color(0xfff59e0b), size: 22),
                ),
                title: Text(
                  isEn ? "Use Default Character Avatar" : "Gunakan Karakter Bawaan",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xff0f172a),
                  ),
                ),
                subtitle: Text(
                  isEn ? "Reset photo to Bull Pro avatar" : "Kembalikan foto ke avatar Banteng Pro",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  appState.updateAvatar('bull');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(isEn ? "Reset to default character avatar" : "Avatar dikembalikan ke karakter bawaan"),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xff0f172a) : const Color(0xfff8fafc),
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
                    isDark ? const Color(0xff064e3b).withOpacity(0.9) : const Color(0xffd1fae5).withOpacity(0.85),
                    isDark ? const Color(0xff0f172a).withOpacity(0.96) : const Color(0xfff8fafc).withOpacity(0.96),
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
                      color: isDark ? const Color(0xff0f172a).withOpacity(0.92) : Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark ? const Color(0xff059669).withOpacity(0.5) : const Color(0xff10b981).withOpacity(0.3),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar Circle with Avatar Picker Sheet
                        GestureDetector(
                          onTap: _isUploadingAvatar ? null : () => _showAvatarOptionsSheet(context, appState),
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
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0),
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
                        // Name with Edit Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                appState.userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xff0f172a),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                AudioService.playClick();
                                _showProfileEditPrompt(context, appState);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xff1e293b) : const Color(0xfff1f5f9),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? const Color(0xff334155) : const Color(0xffe2e8f0),
                                  ),
                                ),
                                child: Icon(
                                  Icons.edit_rounded,
                                  size: 15,
                                  color: isDark ? const Color(0xff10b981) : const Color(0xff059669),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        // Email
                        Text(
                          appState.userEmail,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Avatar Tag Pill
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            AudioService.playClick();
                            _showAvatarOptionsSheet(context, appState);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xff1e293b) : const Color(0xfff1f5f9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getAvatarColor(appState.userAvatar).withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getAvatarIcon(appState.userAvatar),
                                  size: 13,
                                  color: _getAvatarColor(appState.userAvatar),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  appState.userAvatar.startsWith('http') || appState.userAvatar.startsWith('data:image')
                                      ? (appState.language == 'en' ? 'Custom Photo' : 'Foto Kustom')
                                      : AvatarData.getTitle(appState.userAvatar, appState.language),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xff0f172a),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit_rounded,
                                  size: 11,
                                  color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                                ),
                              ],
                            ),
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
                              color: isDark ? const Color(0xff161f30) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: (appState.currentRank['color'] as Color).withOpacity(isDark ? 0.35 : 0.45),
                                width: 1.0,
                              ),
                              boxShadow: isDark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
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
                                        Text(
                                          appState.language == 'en' ? "Career Progression" : "Jenjang Karier Trader",
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xff0f172a),
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
                                     backgroundColor: isDark ? const Color(0xff0b0f19) : const Color(0xffe2e8f0),
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
                                       style: TextStyle(
                                         fontFamily: 'Inter',
                                         fontSize: 10.5,
                                         color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                                       ),
                                     ),
                                     Text(
                                       appState.nextRank != null
                                           ? (appState.language == 'en'
                                               ? "${appState.xpToNextRank} XP left (${(appState.rankProgress * 100).toInt()}%)"
                                               : "Kurang ${appState.xpToNextRank} XP lagi (${(appState.rankProgress * 100).toInt()}%)")
                                           : (appState.language == 'en' ? "Max Rank Reached ✓" : "Gelar Tertinggi ✓"),
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
                              gradient: LinearGradient(
                                colors: isDark
                                    ? const [Color(0xff1e293b), Color(0xff0f172a)]
                                    : const [Colors.white, Color(0xfff8fafc)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: appState.unclaimedMilestonesCount > 0
                                    ? const Color(0xfff59e0b)
                                    : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0)),
                                width: appState.unclaimedMilestonesCount > 0 ? 1.5 : 1.0,
                              ),
                              boxShadow: [
                                if (appState.unclaimedMilestonesCount > 0)
                                  BoxShadow(
                                    color: const Color(0xfff59e0b).withOpacity(0.2),
                                    blurRadius: 10,
                                  )
                                else if (!isDark)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xfff59e0b).withOpacity(isDark ? 0.18 : 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.card_giftcard_rounded, color: Color(0xffd97706), size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            appState.language == 'en' ? "XP Milestone Rewards" : "Jalur Hadiah XP",
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w900,
                                              color: isDark ? Colors.white : const Color(0xff0f172a),
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
                                                appState.language == 'en'
                                                    ? "${appState.unclaimedMilestonesCount} Rewards Ready!"
                                                    : "${appState.unclaimedMilestonesCount} Hadiah Siap!",
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
                                                  color: Color(0xffd97706),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        appState.language == 'en'
                                            ? "Unlock hearts, streak shields & avatars as XP grows."
                                            : "Buka nyawa, pelindung streak & avatar saat XP naik.",
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 10.5,
                                          color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: isDark ? const Color(0xfffbbf24) : const Color(0xffd97706),
                                  size: 13,
                                ),
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
                                  ? (isDark
                                      ? const LinearGradient(colors: [Color(0xff1e293b), Color(0xff334155)])
                                      : const LinearGradient(colors: [Color(0xfff1f5f9), Color(0xffe2e8f0)]))
                                  : const LinearGradient(colors: [Color(0xff78350f), Color(0xffea580c)]),
                              border: Border.all(
                                color: appState.isPremium
                                    ? (isDark ? Colors.white.withOpacity(0.2) : const Color(0xffcbd5e1))
                                    : const Color(0xfff59e0b),
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
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
                                        appState.isPremium
                                            ? _tr(appState, 'profile.premium_member')
                                            : _tr(appState, 'profile.free_account'),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: appState.isPremium && !isDark ? const Color(0xff0f172a) : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        appState.isPremium
                                            ? _tr(appState, 'profile.premium_benefit')
                                            : _tr(appState, 'profile.premium_upgrade'),
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 10.5,
                                          color: appState.isPremium && !isDark ? const Color(0xff475569) : const Color(0xffcbd5e1),
                                        ),
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
                                    child: Text(
                                      _tr(appState, 'profile.upgrade'),
                                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
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
                        children: [
                          const Icon(Icons.bar_chart_rounded, color: Color(0xff10b981), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _tr(appState, 'profile.statistics'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xff0f172a),
                            ),
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
                        context,
                        _tr(appState, 'profile.total_xp'),
                        "${appState.xp} XP",
                        iconData: appState.currentRank['icon'] as IconData,
                        color: appState.currentRank['color'] as Color,
                        subtitle: "Tier ${appState.currentRank['roman']} • ${appState.currentRank['title']}",
                        onTap: () {
                          AudioService.playClick();
                          RankProgressionModal.show(context);
                        },
                      ),
                      _buildStatCard(
                        context,
                        _tr(appState, 'profile.xp_today'),
                        "${appState.dailyXp} / 50",
                        iconData: appState.isDailyGoalReached ? Icons.check_circle_rounded : Icons.track_changes_rounded,
                        color: appState.isDailyGoalReached ? const Color(0xff10b981) : const Color(0xff3b82f6),
                        subtitle: appState.canClaimDailyGoalBonus
                            ? (appState.language == 'en' ? "Claim Daily Bonus!" : "Klaim Bonus Hadiah!")
                            : (appState.isDailyGoalClaimedToday ? (appState.language == 'en' ? "Goal Reached ✓" : "Target Tercapai ✓") : (appState.language == 'en' ? "Target 50 XP/day" : "Target 50 XP/hari")),
                        onTap: () {
                          AudioService.playClick();
                          if (appState.canClaimDailyGoalBonus) {
                            appState.claimDailyGoalBonus(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(appState.language == 'en' ? "Congrats! Daily Goal Reached: +15 Bonus XP & +1 Heart!" : "Selamat! Target Harian Tercapai: +15 Bonus XP & +1 Nyawa Petir!"),
                                backgroundColor: const Color(0xff059669),
                              ),
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (dCtx) => AlertDialog(
                                backgroundColor: isDark ? const Color(0xff0f172a) : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: isDark ? const Color(0xff334155) : const Color(0xffe2e8f0)),
                                ),
                                title: Row(
                                  children: [
                                    const Icon(Icons.track_changes_rounded, color: Color(0xff38bdf8), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      appState.language == 'en' ? "Daily Learning Goal" : "Target Belajar Harian",
                                      style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xff0f172a), fontSize: 17),
                                    ),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      appState.language == 'en' ? "Today's Progress: ${appState.dailyXp} of 50 XP" : "Progres Hari Ini: ${appState.dailyXp} dari 50 XP",
                                      style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xff0f172a)),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: (appState.dailyXp / 50).clamp(0.0, 1.0),
                                        minHeight: 8,
                                        backgroundColor: isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0),
                                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff10b981)),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      appState.canClaimDailyGoalBonus
                                          ? (appState.language == 'en' ? "Target reached! Claim your daily bonus reward now." : "Target harian tercapai! Klaim bonus hadiah sekarang.")
                                          : (appState.isDailyGoalClaimedToday
                                              ? (appState.language == 'en' ? "You have claimed today's bonus. Come back tomorrow!" : "Anda telah mengklaim bonus hari ini. Terus belajar untuk menambah XP!")
                                              : (appState.language == 'en' ? "Earn 50 XP today from quizzes & lessons to claim 15 XP bonus & 1 heart." : "Kumpulkan 50 XP hari ini dari kuis atau materi untuk mendapatkan bonus 15 XP & 1 Nyawa Petir.")),
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b), height: 1.4),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dCtx).pop(),
                                    child: Text(appState.language == 'en' ? "Close" : "Tutup", style: const TextStyle(color: Color(0xff94a3b8))),
                                  ),
                                  if (appState.canClaimDailyGoalBonus)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff10b981)),
                                      onPressed: () {
                                        Navigator.of(dCtx).pop();
                                        appState.claimDailyGoalBonus(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(appState.language == 'en' ? "Daily Goal Bonus Claimed! +15 XP & +1 Heart!" : "Selamat! Bonus Harian Berhasil Diklaim: +15 Bonus XP & +1 Nyawa Petir!"),
                                            backgroundColor: const Color(0xff059669),
                                          ),
                                        );
                                      },
                                      child: Text(appState.language == 'en' ? "Claim Now" : "Klaim Sekarang", style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                      _buildStatCard(
                        context,
                        _tr(appState, 'profile.streak'),
                        "${appState.streak} ${_tr(appState, 'profile.days_unit')}",
                        iconData: Icons.local_fire_department_rounded,
                        color: const Color(0xffef4444),
                        subtitle: appState.streak > 0 ? (appState.language == 'en' ? "Keep the fire burning!" : "Pertahankan Api!") : (appState.language == 'en' ? "Start Today!" : "Mulai Hari Ini"),
                      ),
                      _buildStatCard(
                        context,
                        _tr(appState, 'profile.levels_completed'),
                        "${appState.completedLevels.length} / 10",
                        iconData: Icons.emoji_events_rounded,
                        color: const Color(0xff10b981),
                        subtitle: "${((appState.completedLevels.length / 10) * 100).toInt()}% ${appState.language == 'en' ? 'Completed' : 'Selesai'}",
                      ),
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
                          Text(
                            _tr(appState, 'profile.badges'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xff0f172a),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xffcbd5e1)),
                            ),
                            child: Text(
                              "${appState.unlockedBadges.length}/${_badges.length}",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
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
                            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xfff1f5f9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xffcbd5e1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _showAllBadges
                                    ? (appState.language == 'en' ? "Collapse" : "Ringkas")
                                    : (appState.language == 'en' ? "View All" : "Lihat Semua"),
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
                                color: isDark ? const Color(0xff0f172a).withOpacity(0.9) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isUnlocked
                                      ? badgeColor.withOpacity(isDark ? 0.8 : 0.6)
                                      : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xffe2e8f0)),
                                  width: isUnlocked ? 1.2 : 0.8,
                                ),
                                boxShadow: isUnlocked
                                    ? [
                                        BoxShadow(
                                          color: badgeColor.withOpacity(isDark ? 0.2 : 0.15),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : (!isDark
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.03),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null),
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
                                        color: isUnlocked
                                            ? badgeColor
                                            : (isDark ? const Color(0xff334155) : const Color(0xffcbd5e1)),
                                        width: isUnlocked ? 2.0 : 1.0,
                                      ),
                                      color: isUnlocked
                                          ? badgeColor.withOpacity(isDark ? 0.15 : 0.1)
                                          : (isDark ? const Color(0xff1e293b) : const Color(0xfff1f5f9)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      iconData,
                                      color: isUnlocked
                                          ? badgeColor
                                          : (isDark ? const Color(0xff475569) : const Color(0xff94a3b8)),
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
                                      color: isUnlocked
                                          ? (isDark ? Colors.white : const Color(0xff0f172a))
                                          : (isDark ? const Color(0xff64748b) : const Color(0xff94a3b8)),
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
                          gradient: LinearGradient(
                            colors: isDark
                                ? const [Color(0xff78350f), Color(0xff1e293b)]
                                : const [Color(0xfffef3c7), Color(0xffffffff)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xfff59e0b), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xfff59e0b).withOpacity(isDark ? 0.2 : 0.15),
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
                                children: [
                                  Text(
                                    _tr(appState, 'profile.admin_console'),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : const Color(0xff0f172a),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _tr(appState, 'profile.admin_console_subtitle'),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11.5,
                                      color: isDark ? const Color(0xffcbd5e1) : const Color(0xff64748b),
                                    ),
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
                    children: [
                      const Icon(Icons.settings_rounded, color: Color(0xff3b82f6), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        _tr(appState, 'profile.settings'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xff0f172a),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Settings Card Group
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff0f172a).withOpacity(0.92) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xffe2e8f0)),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Column(
                      children: [
                        _buildSettingSwitchTile(
                          context: context,
                          icon: Icons.dark_mode_rounded,
                          iconColor: const Color(0xff8b5cf6),
                          title: _tr(appState, 'settings.dark_mode_title'),
                          subtitle: appState.darkMode
                              ? _tr(appState, 'settings.dark_mode_on')
                              : _tr(appState, 'settings.dark_mode_off'),
                          value: appState.darkMode,
                          onChanged: (val) {
                            appState.toggleDarkMode(val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(val ? _tr(appState, 'settings.dark_mode_enabled') : _tr(appState, 'settings.light_mode_enabled')),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        Divider(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0), height: 1),
                        _buildSettingSwitchTile(
                          context: context,
                          icon: Icons.notifications_active_rounded,
                          iconColor: const Color(0xfff59e0b),
                          title: _tr(appState, 'settings.daily_reminder_title'),
                          subtitle: appState.dailyReminder
                              ? '${_tr(appState, 'settings.reminder_time')}: ${appState.reminderHour.toString().padLeft(2, '0')}:00 WIB'
                              : _tr(appState, 'settings.daily_reminder_off'),
                          value: appState.dailyReminder,
                          onChanged: (val) async {
                            if (val) {
                              final granted = await appState.requestNotificationPermission();
                              if (mounted) {
                                if (granted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      content: Text(_tr(appState, 'settings.daily_reminder_enabled')),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  _showNotificationBlockedDialog(context, appState);
                                }
                              }
                            } else {
                              appState.toggleDailyReminder(false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    content: Text(_tr(appState, 'settings.daily_reminder_disabled')),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        if (appState.dailyReminder) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(56, 0, 16, 12),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    side: BorderSide(
                                      color: isDark
                                          ? const Color(0xfff59e0b).withOpacity(0.5)
                                          : const Color(0xffd97706),
                                      width: 1.0,
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _showReminderTimePickerDialog(context, appState),
                                  icon: const Icon(Icons.access_time_rounded, size: 14, color: Color(0xfff59e0b)),
                                  label: Text(
                                    '${appState.reminderHour.toString().padLeft(2, '0')}:00 WIB',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xfff59e0b) : const Color(0xffd97706),
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    side: BorderSide(
                                      color: isDark
                                          ? const Color(0xfff59e0b).withOpacity(0.5)
                                          : const Color(0xffd97706),
                                      width: 1.0,
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    try {
                                      AudioService.playClick();
                                    } catch (_) {}
                                    appState.testNotification();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(_tr(appState, 'settings.test_notification_sent')),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.send_rounded, size: 14, color: Color(0xfff59e0b)),
                                  label: Text(
                                    _tr(appState, 'settings.test_notification'),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xfff59e0b) : const Color(0xffd97706),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Divider(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0), height: 1),
                        _buildSettingSwitchTile(
                          context: context,
                          icon: Icons.volume_up_rounded,
                          iconColor: const Color(0xff10b981),
                          title: _tr(appState, 'settings.sound_haptic_title'),
                          subtitle: appState.soundHaptic
                              ? _tr(appState, 'settings.sound_haptic_on')
                              : _tr(appState, 'settings.sound_haptic_off'),
                          value: appState.soundHaptic,
                          onChanged: (val) {
                            appState.toggleSoundHaptic(val);
                            if (val) HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(val ? _tr(appState, 'settings.sound_haptic_enabled') : _tr(appState, 'settings.sound_haptic_disabled')),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        Divider(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0), height: 1),
                        _buildSettingSwitchTile(
                          context: context,
                          icon: Icons.music_note_rounded,
                          iconColor: const Color(0xff06b6d4),
                          title: _tr(appState, 'settings.bgm_title'),
                          subtitle: appState.bgmEnabled
                              ? _tr(appState, 'settings.bgm_on')
                              : _tr(appState, 'settings.bgm_off'),
                          value: appState.bgmEnabled,
                          onChanged: (val) {
                            appState.toggleBgm(val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(val ? _tr(appState, 'settings.bgm_enabled') : _tr(appState, 'settings.bgm_disabled')),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        Divider(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0), height: 1),
                        _buildSettingItemTile(
                          context: context,
                          icon: Icons.library_music_rounded,
                          iconColor: const Color(0xff8b5cf6),
                          title: _tr(appState, 'settings.choose_bgm'),
                          trailingText: AudioService.bgmLabels[appState.bgmTrack] ?? _tr(appState, 'settings.default_bgm'),
                          onTap: () => _showBgmPickerDialog(context, appState),
                        ),
                        Divider(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0), height: 1),
                        _buildSettingItemTile(
                          context: context,
                          icon: Icons.language_rounded,
                          iconColor: const Color(0xff3b82f6),
                          title: _tr(appState, 'settings.language'),
                          trailingText: appState.language == 'id'
                              ? _tr(appState, 'settings.language_id')
                              : _tr(appState, 'settings.language_en'),
                          onTap: () => _showLanguageSelectorDialog(context, appState),
                        ),
                        Divider(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0), height: 1),
                        _buildSettingItemTile(
                          context: context,
                          icon: Icons.help_outline_rounded,
                          iconColor: const Color(0xffec4899),
                          title: _tr(appState, 'profile.help_faq'),
                          trailingText: _tr(appState, 'profile.help'),
                          onTap: () => _showFaqModal(context),
                        ),
                        Divider(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0), height: 1),
                        _buildSettingItemTile(
                          context: context,
                          icon: Icons.privacy_tip_outlined,
                          iconColor: const Color(0xff94a3b8),
                          title: _tr(appState, 'profile.privacy_terms'),
                          trailingText: _tr(appState, 'profile.legal'),
                          onTap: () => _showPrivacyPolicyModal(context),
                        ),
                        Divider(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0), height: 1),
                        _buildSettingItemTile(
                          context: context,
                          icon: Icons.restart_alt_rounded,
                          iconColor: const Color(0xfff43f5e),
                          title: _tr(appState, 'settings.reset_progress'),
                          trailingText: 'Reset',
                          onTap: () => _showResetProgressDialog(context, appState),
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
                    label: Text(
                      _tr(appState, 'profile.logout'),
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
                  Center(
                    child: Text(
                      "Trade Heroes v2.4.0 PRO • Build 2026.08",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: isDark ? const Color(0xff64748b) : const Color(0xff94a3b8),
                      ),
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
    BuildContext context,
    String label,
    String value, {
    required IconData iconData,
    required Color color,
    VoidCallback? onTap,
    String? subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Positioned.fill(
            top: 3.5,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff022c22) : const Color(0xffcbd5e1),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 3.5),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff0f172a).withOpacity(0.92) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(isDark ? 0.4 : 0.3), width: 1.2),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: isDark ? const Color(0xffcbd5e1) : const Color(0xff64748b),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSwitchTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(isDark ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xff0f172a),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: (newVal) {
          AudioService.playClick();
          onChanged(newVal);
        },
        activeColor: const Color(0xff10b981),
        activeTrackColor: isDark ? const Color(0xff065f46) : const Color(0xffa7f3d0),
        inactiveThumbColor: isDark ? const Color(0xff94a3b8) : const Color(0xffcbd5e1),
        inactiveTrackColor: isDark ? const Color(0xff334155) : const Color(0xffe2e8f0),
      ),
    );
  }

  Widget _buildSettingItemTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String trailingText,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: () {
        try {
          AudioService.playClick();
        } catch (_) {}
        onTap();
      },
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(isDark ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xff0f172a),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trailingText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: isDark ? const Color(0xff64748b) : const Color(0xff94a3b8), size: 18),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xff1e293b) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xffe2e8f0),
          ),
        ),
        title: Text(
          _tr(appState, 'profile.logout_confirm'),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xff0f172a),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              _tr(appState, 'profile.logout_cancel'),
              style: TextStyle(
                fontFamily: 'Inter',
                color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
              ),
            ),
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
            child: Text(
              _tr(appState, 'profile.logout_action'),
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetProgressDialog(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xff1e293b) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xffe2e8f0),
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xffef4444), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _tr(appState, 'settings.reset_progress_confirm_title'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xff0f172a),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          _tr(appState, 'settings.reset_progress_confirm_desc'),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: isDark ? const Color(0xffcbd5e1) : const Color(0xff475569),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              _tr(appState, 'profile.cancel'),
              style: TextStyle(
                fontFamily: 'Outfit',
                color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffef4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              appState.resetProgress();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(_tr(appState, 'settings.reset_progress_success')),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              _tr(appState, 'settings.reset_progress_action'),
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
