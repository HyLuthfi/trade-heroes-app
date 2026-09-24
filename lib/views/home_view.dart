import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../state/app_state.dart';
import '../widgets/rank_progression_modal.dart';
import '../widgets/leaderboard_modal.dart';
import 'kuis_view.dart';
import 'materi_view.dart';
import 'profile_view.dart';
import 'market_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentTabIndex = 0;

  final List<Widget> _tabs = const [
    KuisView(),
    MarketView(),
    MateriView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Dynamic title based on active tab
    String appTitle = "Trade Heroes";
    if (_currentTabIndex == 1) appTitle = "Live Market";
    if (_currentTabIndex == 2) appTitle = "Materi Belajar";
    if (_currentTabIndex == 3) appTitle = "Profil Anda";

    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            // Custom logo with fallback vector icon
            Image.asset(
              'assets/images/logo.png',
              width: 42,
              height: 42,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.show_chart,
                  color: Color(0xff3ec374),
                  size: 42,
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              appTitle,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          // Header Stats
          Row(
            children: [
              // Petir/Lives Stat
              Tooltip(
                message: appState.isPremium ? "Nyawa tak terbatas" : "Nyawa petir Anda",
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xff1e293b),
                    border: Border.all(
                      color: appState.isPremium ? const Color(0xfff59e0b) : const Color(0xff334155),
                      width: appState.isPremium ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flash_on,
                        color: appState.isPremium ? const Color(0xfff59e0b) : const Color(0xffef4444),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        appState.isPremium ? "∞" : "${appState.petir}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: appState.isPremium ? const Color(0xfff59e0b) : const Color(0xffef4444),
                        ),
                      ),
                      if (!appState.isPremium && appState.petir < 5) ...[
                        const SizedBox(width: 4),
                        Text(
                          "(${appState.getPetirRegenTime()})",
                          style: const TextStyle(fontSize: 10, color: Color(0xff94a3b8)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // XP & Rank Stat Pill (tappable to view roadmap)
              GestureDetector(
                onTap: () {
                  AudioService.playClick();
                  RankProgressionModal.show(context);
                },
                child: Tooltip(
                  message: "${appState.currentRank['title']} (Tier ${appState.currentRank['roman']}) • Ketuk rincian gelar",
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xff1e293b),
                      border: Border.all(
                        color: (appState.currentRank['color'] as Color).withOpacity(0.5),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          appState.currentRank['icon'] as IconData,
                          color: appState.currentRank['color'] as Color,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "${appState.xp} XP",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: appState.currentRank['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          )
        ],
      ),
      body: _tabs[_currentTabIndex],
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16, top: 4),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xff182232), // Dark slate capsule background
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xff334155), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildNavItem(0, Icons.map_outlined, Icons.map, "Kuis"),
                _buildNavItem(1, Icons.candlestick_chart_outlined, Icons.candlestick_chart_rounded, "Market"),
                _buildNavItem(2, Icons.menu_book_outlined, Icons.menu_book, "Materi"),
                _buildNavItem(3, Icons.person_outline, Icons.person, "Saya"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentTabIndex == index;
    const activeColor = Color(0xff58cc02); // Unified Duolingo green
    const unselectedColor = Color(0xff94a3b8);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentTabIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Icon and Text Column (centered)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected ? activeColor : unselectedColor,
                    size: 24,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                      color: isSelected ? activeColor : unselectedColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4), // offset spacing for bottom line indicator
                ],
              ),
              // Bottom active indicator line (flush with capsule bottom edge)
              if (isSelected)
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(2),
                        topRight: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
