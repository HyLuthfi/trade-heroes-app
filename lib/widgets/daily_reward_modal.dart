import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class DailyRewardModal extends StatelessWidget {
  const DailyRewardModal({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DailyRewardModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final bool canClaimToday = appState.canClaimDailyToday;
    final List<int> claimedDays = appState.claimedDailyDays;

    // Current target day to claim (1 to 7)
    int currentDay = (claimedDays.length % 7) + (canClaimToday ? 1 : 0);
    if (currentDay == 0) currentDay = 7;

    final List<Map<String, dynamic>> daysData = [
      {'day': 1, 'rewardStr': '+50 XP', 'xp': 50, 'petir': 0, 'icon': Icons.star_rounded, 'color': const Color(0xfff59e0b)},
      {'day': 2, 'rewardStr': '+2 Petir ⚡', 'xp': 20, 'petir': 2, 'icon': Icons.bolt_rounded, 'color': const Color(0xff10b981)},
      {'day': 3, 'rewardStr': '+100 XP', 'xp': 100, 'petir': 0, 'icon': Icons.star_rounded, 'color': const Color(0xfff59e0b)},
      {'day': 4, 'rewardStr': '+3 Petir ⚡', 'xp': 30, 'petir': 3, 'icon': Icons.bolt_rounded, 'color': const Color(0xff10b981)},
      {'day': 5, 'rewardStr': '+150 XP', 'xp': 150, 'petir': 0, 'icon': Icons.star_rounded, 'color': const Color(0xfff59e0b)},
      {'day': 6, 'rewardStr': '+5 Petir ⚡', 'xp': 50, 'petir': 5, 'icon': Icons.bolt_rounded, 'color': const Color(0xff34d399)},
      {'day': 7, 'rewardStr': '+300 XP 👑', 'xp': 300, 'petir': 5, 'icon': Icons.workspace_premium_rounded, 'color': const Color(0xfffbbf24)},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xff0f172a),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xff10b981), width: 2.0)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle Pill
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Header 3D Gift Aura Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xff065f46),
              border: Border.all(color: const Color(0xff10b981), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff10b981).withOpacity(0.5),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 12),

          const Text(
            "HADIAH LOG-IN HARIAN",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Absen setiap hari untuk mengklaim bonus XP & energi Petir gratis!",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xff94a3b8)),
          ),
          const SizedBox(height: 20),

          // 7-Day Reward Grid Cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.85,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: daysData.length,
            itemBuilder: (context, idx) {
              final dayItem = daysData[idx];
              final int dayNum = dayItem['day'] as int;
              final bool isClaimed = claimedDays.contains(dayNum);
              final bool isCurrent = dayNum == currentDay && canClaimToday;
              final Color color = dayItem['color'] as Color;

              return Container(
                decoration: BoxDecoration(
                  color: isClaimed
                      ? const Color(0xff064e3b).withOpacity(0.4)
                      : (isCurrent ? const Color(0xff065f46) : const Color(0xff1e293b)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCurrent
                        ? const Color(0xff10b981)
                        : (isClaimed ? const Color(0xff059669) : Colors.white.withOpacity(0.08)),
                    width: isCurrent ? 2.0 : 1.0,
                  ),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: const Color(0xff10b981).withOpacity(0.4),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Hari $dayNum",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? Colors.white : const Color(0xff94a3b8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (isClaimed)
                      const Icon(Icons.check_circle_rounded, color: Color(0xff34d399), size: 24)
                    else
                      Icon(dayItem['icon'] as IconData, color: color, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      isClaimed ? "Klaim" : dayItem['rewardStr'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: isClaimed ? const Color(0xff34d399) : Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Main Action Claim Button 3D
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canClaimToday ? const Color(0xff059669) : const Color(0xff334155),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: canClaimToday ? 4 : 0,
            ),
            onPressed: canClaimToday
                ? () {
                    final todayData = daysData.firstWhere(
                      (d) => d['day'] == currentDay,
                      orElse: () => daysData.first,
                    );

                    appState.claimDailyReward(
                      currentDay,
                      xpReward: todayData['xp'] as int,
                      petirReward: todayData['petir'] as int,
                    );

                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: Color(0xfffbbf24), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Selamat! Anda mendapatkan ${todayData['rewardStr']}! 🥳",
                                style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xff059669),
                      ),
                    );
                  }
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  canClaimToday ? Icons.card_giftcard_rounded : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  canClaimToday
                      ? "KLAIM HADIAH HARI INI 🎁"
                      : "SUDAH DIKLAIM (KEMBALI BESOK)",
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
