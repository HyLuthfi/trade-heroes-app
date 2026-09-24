import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/materi_data.dart';
import '../l10n/app_translations.dart';
import '../services/audio_service.dart';
import '../state/app_state.dart';
import '../widgets/vip_pass_modal.dart';
import 'package:path_provider/path_provider.dart';

class MateriView extends StatefulWidget {
  const MateriView({Key? key}) : super(key: key);

  @override
  State<MateriView> createState() => _MateriViewState();
}

class _MateriViewState extends State<MateriView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  String _tr(AppState appState, String key, {Map<String, String> params = const {}}) {
    return AppTranslations.text(appState.language, key, params: params);
  }

  List<Map<String, dynamic>> _getModules(AppState appState) =>
      MateriData.getModules(appState.language);

  List<Map<String, dynamic>> _getTradingTips(AppState appState) =>
      MateriData.getTradingTips(appState.language);

  List<Map<String, dynamic>> _getGlossary(AppState appState) =>
      MateriData.getGlossary(appState.language);

  int? _expandedGlossaryIdx;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _downloadPdf(AppState appState, Map<String, dynamic> tip) async {
    final title = tip['title'] as String;
    final content = tip['content'] as String;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? const Color(0xff0f172a) : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark ? const Color(0xff10b981) : const Color(0xff10b981).withOpacity(0.5),
                width: 1.2,
              )),
          title: Text(
            _tr(appState, 'materi.pdf_sim_title'),
            style: TextStyle(
              fontFamily: 'Outfit',
              color: isDark ? Colors.white : const Color(0xff0f172a),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            _tr(appState, 'materi.pdf_sim_desc', params: {
              'file': '${title.toLowerCase().replaceAll(' ', '_')}.pdf',
              'content': content,
            }),
            style: TextStyle(
              color: isDark ? const Color(0xffcbd5e1) : const Color(0xff334155),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                _tr(appState, 'materi.pdf_sim_ok'),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Color(0xff10b981),
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      );
    } else {
      try {
        final directory = await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
        final file = File(
            '${directory.path}/${title.toLowerCase().replaceAll(' ', '_')}.pdf');
        await file.writeAsString(content);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _tr(appState, 'materi.pdf_saved', params: {'path': file.path}),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _tr(appState, 'materi.pdf_failed', params: {'error': '$e'}),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Image matching main app theme
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 1.0 : 0.05,
              child: Image.asset(
                'assets/images/background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xff064e3b).withOpacity(0.92),
                          const Color(0xff0f172a).withOpacity(0.96),
                        ]
                      : [
                          const Color(0xffecfdf5).withOpacity(0.92),
                          theme.scaffoldBackgroundColor.withOpacity(0.96),
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Clearance for HomeView floating AppBar
                const SizedBox(height: kToolbarHeight),
                // 3D Header Tab Bar
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xff1e293b).withOpacity(0.9)
                        : colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.12)
                          : colors.outlineVariant.withOpacity(0.5),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: const Color(0xff10b981),
                    indicatorWeight: 3.5,
                    labelColor: const Color(0xff10b981),
                    unselectedLabelColor: isDark
                        ? const Color(0xff94a3b8)
                        : const Color(0xff64748b),
                    labelStyle: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w900),
                    unselectedLabelStyle: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(
                          icon: const Icon(Icons.menu_book_rounded, size: 16),
                          text: _tr(appState, 'materi.tab_modules')),
                      Tab(
                          icon: const Icon(Icons.star_rounded, size: 16),
                          text: _tr(appState, 'materi.tab_favorites')),
                      Tab(
                          icon: const Icon(Icons.lightbulb_rounded, size: 16),
                          text: _tr(appState, 'materi.tab_tips')),
                      Tab(
                          icon: const Icon(Icons.spellcheck_rounded, size: 16),
                          text: _tr(appState, 'materi.tab_glossary')),
                    ],
                  ),
                ),

                // Tab Views Body
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildModulesTab(appState),
                      _buildFavoritesTab(appState),
                      _buildTipsTab(appState),
                      _buildGlossaryTab(appState),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. MODUL BELAJAR TAB (3D Cards)
  Widget _buildModulesTab(AppState appState) {
    final modules = _getModules(appState);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
      itemCount: modules.length,
      itemBuilder: (context, idx) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        final mod = modules[idx];
        final isRead = appState.readModules.contains(mod['id']);
        final isLocked = mod['isPremium'] && !appState.isPremium;

        String badgeText = mod['category'];
        Color badgeColor =
            isDark ? const Color(0xff1e293b) : const Color(0xffeff6ff);
        Color badgeTextColor =
            isDark ? const Color(0xff60a5fa) : const Color(0xff2563eb);
        Color badgeBorder = isDark
            ? const Color(0xff3b82f6).withOpacity(0.5)
            : const Color(0xff93c5fd);

        if (isRead) {
          badgeText = _tr(appState, 'materi.read_completed');
          badgeColor =
              isDark ? const Color(0xff064e3b) : const Color(0xffdcfce7);
          badgeTextColor =
              isDark ? const Color(0xff34d399) : const Color(0xff059669);
          badgeBorder = const Color(0xff10b981);
        } else if (isLocked) {
          badgeText = _tr(appState, 'materi.premium_badge');
          badgeColor =
              isDark ? const Color(0xff78350f) : const Color(0xfffef3c7);
          badgeTextColor =
              isDark ? const Color(0xfff59e0b) : const Color(0xffd97706);
          badgeBorder = const Color(0xfff59e0b);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: Stack(
            children: [
              // 3D Bottom Extrusion Shadow
              Positioned.fill(
                top: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xff022c22)
                        : const Color(0xffd1fae5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              // Main Card Face
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xff0f172a).withOpacity(0.92)
                      : colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isRead
                        ? const Color(0xff10b981).withOpacity(0.6)
                        : isLocked
                            ? const Color(0xfff59e0b).withOpacity(0.6)
                            : isDark
                                ? Colors.white.withOpacity(0.12)
                                : colors.outlineVariant.withOpacity(0.5),
                    width: 1.2,
                  ),
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      if (isLocked) {
                        try {
                          AudioService.playClick();
                        } catch (_) {}
                        _showPremiumLockedDialog();
                        return;
                      }
                      try {
                        AudioService.playConfirm();
                      } catch (_) {}
                      _openModuleContent(appState, mod);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category Badge Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: badgeBorder, width: 1.0),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: badgeTextColor,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        // XP Reward Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xff78350f).withOpacity(0.3)
                                : const Color(0xfffef3c7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    const Color(0xfff59e0b).withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              const Text("🪙 ", style: TextStyle(fontSize: 11)),
                              Text(
                                "+${mod['xp']} XP",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? const Color(0xfff59e0b)
                                      : const Color(0xffd97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Title
                    Text(
                      mod['title'],
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Description
                    Text(
                      mod['desc'],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: isDark
                            ? const Color(0xffcbd5e1)
                            : const Color(0xff475569),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Divider(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : colors.outlineVariant.withOpacity(0.5),
                      height: 1,
                    ),
                    const SizedBox(height: 10),
                    // 3D Read Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isLocked
                              ? const LinearGradient(colors: [
                                  Color(0xffea580c),
                                  Color(0xffc2410c)
                                ])
                              : const LinearGradient(colors: [
                                  Color(0xff059669),
                                  Color(0xff10b981)
                                ]),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: isLocked
                                  ? const Color(0xffea580c).withOpacity(0.4)
                                  : const Color(0xff10b981).withOpacity(0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLocked
                                  ? _tr(appState, 'materi.locked')
                                  : _tr(appState, 'materi.read_now'),
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
            ],
          ),
        );
      },
    );
  }

  // 3D Module Reading Content Modal
  void _openModuleContent(AppState appState, Map<String, dynamic> mod) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: (screenW - 32).clamp(280.0, 540.0),
          height: screenH * 0.82,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xff0f172a) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xff10b981) : const Color(0xff10b981).withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0xff10b981).withOpacity(0.3)
                    : Colors.black.withOpacity(0.12),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      mod['title'],
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xff0f172a),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Icon(Icons.close_rounded,
                        color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xffe2e8f0)),
              const SizedBox(height: 10),
              // Key Takeaways Summary Box
              if (mod['takeaways'] != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xff064e3b).withOpacity(0.5)
                        : const Color(0xffecfdf5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xff10b981).withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded,
                              color: Color(0xfffbbf24), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            "${_tr(appState, 'materi.summary_title')} (${mod['readTimeStr'] ?? ''})",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: isDark ? const Color(0xff6ee7b7) : const Color(0xff047857),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...(mod['takeaways'] as List<String>).map(
                        (point) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("• ",
                                  style: TextStyle(
                                      color: Color(0xff34d399),
                                      fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  point,
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11.5,
                                      color: isDark ? Colors.white : const Color(0xff0f172a)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    (mod['content'] as String)
                        .replaceAll("<h1>", "")
                        .replaceAll("</h1>", "\n\n")
                        .replaceAll("<h2>", "\n📌 ")
                        .replaceAll("</h2>", "\n")
                        .replaceAll("<p>", "")
                        .replaceAll("</p>", "\n\n")
                        .replaceAll("<b>", "")
                        .replaceAll("</b>", "")
                        .replaceAll("<br>", "\n"),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      color: isDark ? const Color(0xffcbd5e1) : const Color(0xff334155),
                      height: 1.55,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff10b981),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  try {
                    AudioService.playReward();
                  } catch (_) {}
                  Navigator.of(ctx).pop();
                  appState.completeModule(mod['id'], mod['xp'], context);
                },
                child: Text(
                  "${_tr(appState, 'materi.finish_reading', params: {'xp': '${mod['xp'] ?? 5}'})} 🚀",
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. FAVORIT TAB (3D Cards)
  Widget _buildFavoritesTab(AppState appState) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        if (appState.favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_border_rounded,
                  size: 64,
                  color: isDark
                      ? const Color(0xff475569)
                      : const Color(0xff94a3b8),
                ),
                const SizedBox(height: 16),
                Text(
                  _tr(appState, 'materi.no_favorites_title'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: isDark
                        ? const Color(0xffcbd5e1)
                        : const Color(0xff64748b),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _tr(appState, 'materi.no_favorites_desc'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: isDark
                          ? const Color(0xff94a3b8)
                          : const Color(0xff64748b),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
          itemCount: appState.favorites.length,
          itemBuilder: (context, idx) {
            final fav = appState.favorites[idx];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xff0f172a).withOpacity(0.9)
                    : colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xfff59e0b).withOpacity(0.5),
                    width: 1.2),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      fav['questionText'],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        color: colors.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      AudioService.playClick();
                      appState.toggleFavorite(
                          fav['levelId'], fav['qIndex'], fav['questionText']);
                    },
                    child: const Icon(Icons.star_rounded,
                        color: Color(0xfff59e0b), size: 24),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 3. TIPS TRADING TAB (3D Cards)
  Widget _buildTipsTab(AppState appState) {
    final tips = _getTradingTips(appState);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
      itemCount: tips.length,
      itemBuilder: (context, idx) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        final tip = tips[idx];
        final isLocked = tip['isPremium'] && !appState.isPremium;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xff0f172a).withOpacity(0.92)
                : colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.12)
                  : colors.outlineVariant.withOpacity(0.5),
              width: 1.2,
            ),
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
            children: [
              // Cover Banner
              Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  gradient: LinearGradient(
                    colors: tip['isPdf']
                        ? [const Color(0xffdc2626), const Color(0xffef4444)]
                        : [const Color(0xff059669), const Color(0xff10b981)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  tip['isPdf']
                      ? (appState.language == 'en' ? "📄 PDF DOCUMENT" : "📄 DOKUMEN PDF")
                      : (appState.language == 'en' ? "💡 TRADING TIPS" : "💡 TIPS TRADING"),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip['title'],
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tip['desc'],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: isDark
                            ? const Color(0xffcbd5e1)
                            : const Color(0xff475569),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xff1e293b)
                                : const Color(0xffeff6ff),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tip['tag'],
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10,
                              color: isDark
                                  ? const Color(0xff60a5fa)
                                  : const Color(0xff2563eb),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLocked
                                ? const Color(0xffea580c)
                                : const Color(0xff10b981),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            if (isLocked) {
                              AudioService.playClick();
                              _showPremiumLockedDialog();
                              return;
                            }
                            AudioService.playConfirm();
                            if (tip['isPdf']) {
                              _downloadPdf(appState, tip);
                            } else {
                              _openTipsContent(tip);
                            }
                          },
                          icon: Icon(
                            isLocked
                                ? Icons.lock_rounded
                                : (tip['isPdf']
                                    ? Icons.download_rounded
                                    : Icons.read_more_rounded),
                            size: 14,
                            color: Colors.white,
                          ),
                          label: Text(
                            isLocked
                                ? _tr(appState, 'materi.tip_unlock')
                                : (tip['isPdf']
                                    ? _tr(appState, 'materi.tip_download_pdf')
                                    : _tr(appState, 'materi.tip_read_tips')),
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openTipsContent(Map<String, dynamic> tip) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xff0f172a) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? const Color(0xff10b981) : const Color(0xff10b981).withOpacity(0.5),
              width: 1.2,
            )),
        title: Text(
          tip['title'],
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xff0f172a),
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            tip['content'],
            style: TextStyle(
              color: isDark ? const Color(0xffcbd5e1) : const Color(0xff334155),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              _tr(Provider.of<AppState>(context, listen: false), 'profile.close'),
              style: const TextStyle(
                fontFamily: 'Outfit',
                color: Color(0xff10b981),
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  // 4. KAMUS ISTILAH TAB (3D Search & Interactive Cards)
  Widget _buildGlossaryTab(AppState appState) {
    final glossary = _getGlossary(appState);
    final filteredGlossary = glossary.where((item) {
      final termMatch =
          item['term'].toLowerCase().contains(_searchQuery.toLowerCase());
      final defMatch =
          item['def'].toLowerCase().contains(_searchQuery.toLowerCase());
      return termMatch || defMatch;
    }).toList();

    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return Column(
          children: [
            // 3D Glass Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: colors.onSurface,
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: _tr(appState, 'materi.search_glossary_hint'),
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.4)
                        : const Color(0xff94a3b8),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xff10b981)),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xff1e293b).withOpacity(0.9)
                      : colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.12)
                          : colors.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.12)
                          : colors.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: Color(0xff10b981), width: 1.8),
                  ),
                ),
                onChanged: (text) {
                  setState(() {
                    _searchQuery = text;
                  });
                },
              ),
            ),

            // Glossary List
            Expanded(
              child: filteredGlossary.isEmpty
                  ? Center(
                      child: Text(
                        _tr(appState, 'materi.glossary_not_found'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: isDark
                              ? const Color(0xffcbd5e1)
                              : const Color(0xff64748b),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                      itemCount: filteredGlossary.length,
                      itemBuilder: (context, idx) {
                        final item = filteredGlossary[idx];
                        final isExpanded = _expandedGlossaryIdx == idx;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xff0f172a).withOpacity(0.92)
                                : colors.surface,
                            border: Border.all(
                              color: isExpanded
                                  ? const Color(0xff10b981)
                                  : (isDark
                                      ? Colors.white.withOpacity(0.12)
                                      : colors.outlineVariant.withOpacity(0.5)),
                              width: 1.2,
                            ),
                            borderRadius: BorderRadius.circular(16),
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
                          child: Theme(
                            data: Theme.of(context)
                                .copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: isExpanded,
                              onExpansionChanged: (expanded) {
                                setState(() {
                                  _expandedGlossaryIdx = expanded ? idx : null;
                                });
                              },
                              title: Text(
                                item['term'],
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: colors.onSurface,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.volume_up_rounded,
                                        color: Color(0xff10b981), size: 20),
                                    onPressed: () {
                                      AudioService.playClick();
                                      ScaffoldMessenger.of(context).clearSnackBars();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _tr(appState, 'materi.pronounce_snack',
                                                params: {'term': item['term']}),
                                          ),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                  Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: isDark
                                        ? const Color(0xff94a3b8)
                                        : const Color(0xff64748b),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['def'],
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          color: isDark
                                              ? const Color(0xffcbd5e1)
                                              : const Color(0xff334155),
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xff1e293b)
                                              : const Color(0xfff1f5f9),
                                          border: const Border(
                                            left: BorderSide(
                                                color: Color(0xff10b981),
                                                width: 3),
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _tr(appState, 'materi.glossary_example_format',
                                              params: {'example': item['example']}),
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: isDark
                                                ? const Color(0xffcbd5e1)
                                                : const Color(0xff475569),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showPremiumLockedDialog() {
    VipPassModal.show(context);
  }
}
