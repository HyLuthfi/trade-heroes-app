import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_translations.dart';
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
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final language = appState.language;
    String tr(String key, {Map<String, String> params = const {}}) =>
        AppTranslations.text(language, key, params: params);

    final bool canClaimToday = appState.canClaimDailyToday;
    final List<int> claimedDays = appState.claimedDailyDays;

    // Current target day to claim (1 to 7)
    int currentDay = (claimedDays.length % 7) + (canClaimToday ? 1 : 0);
    if (currentDay == 0) currentDay = 7;

    final List<Map<String, dynamic>> daysData = [
      {'day': 1, 'xp': 50, 'petir': 0, 'icon': Icons.star_rounded, 'color': const Color(0xfff59e0b)},
      {'day': 2, 'xp': 20, 'petir': 2, 'icon': Icons.bolt_rounded, 'color': const Color(0xff10b981)},
      {'day': 3, 'xp': 100, 'petir': 0, 'icon': Icons.star_rounded, 'color': const Color(0xfff59e0b)},
      {'day': 4, 'xp': 30, 'petir': 3, 'icon': Icons.bolt_rounded, 'color': const Color(0xff10b981)},
      {'day': 5, 'xp': 150, 'petir': 0, 'icon': Icons.star_rounded, 'color': const Color(0xfff59e0b)},
      {'day': 6, 'xp': 50, 'petir': 5, 'icon': Icons.bolt_rounded, 'color': const Color(0xff34d399)},
      {'day': 7, 'xp': 300, 'petir': 5, 'icon': Icons.workspace_premium_rounded, 'color': const Color(0xfffbbf24)},
    ];

    String formatRewardString(Map<String, dynamic> item) {
      final petir = item['petir'] as int;
      final xp = item['xp'] as int;
      if (item['day'] == 7) {
        return "+$xp XP 👑";
      } else if (petir > 0) {
        return tr('daily_reward.reward_petir', params: {'count': '$petir'});
      } else {
        return tr('daily_reward.reward_xp', params: {'count': '$xp'});
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff0f172a) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: isDark ? const Color(0xff10b981) : const Color(0xff059669), width: 2.0)),
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
              color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Header 3D Gift Aura Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xff065f46) : const Color(0xffd1fae5),
              border: Border.all(color: const Color(0xff10b981), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff10b981).withOpacity(isDark ? 0.5 : 0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              color: isDark ? Colors.white : const Color(0xff059669),
              size: 36,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            tr('daily_reward.title'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xff0f172a),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr('daily_reward.subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
            ),
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
              final String rewardLabel = formatRewardString(dayItem);

              return Container(
                decoration: BoxDecoration(
                  color: isClaimed
                      ? (isDark ? const Color(0xff064e3b).withOpacity(0.4) : const Color(0xffecfdf5))
                      : (isCurrent
                          ? (isDark ? const Color(0xff065f46) : const Color(0xffd1fae5))
                          : (isDark ? const Color(0xff1e293b) : const Color(0xfff8fafc))),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCurrent
                        ? const Color(0xff10b981)
                        : (isClaimed
                            ? const Color(0xff059669)
                            : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0))),
                    width: isCurrent ? 2.0 : 1.0,
                  ),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: const Color(0xff10b981).withOpacity(isDark ? 0.4 : 0.25),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tr('daily_reward.day', params: {'day': '$dayNum'}),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCurrent
                            ? (isDark ? Colors.white : const Color(0xff065f46))
                            : (isDark ? const Color(0xff94a3b8) : const Color(0xff64748b)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (isClaimed)
                      const Icon(Icons.check_circle_rounded, color: Color(0xff34d399), size: 24)
                    else
                      Icon(dayItem['icon'] as IconData, color: color, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      isClaimed ? tr('daily_reward.claimed') : rewardLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: isClaimed
                            ? const Color(0xff059669)
                            : (isDark ? Colors.white : const Color(0xff0f172a)),
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
              backgroundColor: canClaimToday
                  ? const Color(0xff059669)
                  : (isDark ? const Color(0xff334155) : const Color(0xffcbd5e1)),
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
                    final rewardLabel = formatRewardString(todayData);

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
                                tr('daily_reward.claim_success', params: {'reward': rewardLabel}),
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
                      ? tr('daily_reward.claim_today')
                      : tr('daily_reward.already_claimed'),
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
