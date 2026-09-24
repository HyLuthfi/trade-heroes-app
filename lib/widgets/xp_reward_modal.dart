import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_translations.dart';
import '../services/audio_service.dart';
import '../state/app_state.dart';

class XpRewardModal extends StatelessWidget {
  const XpRewardModal({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const XpRewardModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final milestones = AppState.xpMilestoneRewards;

    String tr(String key, {Map<String, String> params = const {}}) =>
        AppTranslations.text(appState.language, key, params: params);

    String getMilestoneTitle(int targetXp, String defaultTitle) {
      final key = 'xp_reward.m${targetXp}_title';
      final val = tr(key);
      return val != key ? val : defaultTitle;
    }

    String getMilestoneDesc(int targetXp, String defaultDesc) {
      final key = 'xp_reward.m${targetXp}_desc';
      final val = tr(key);
      return val != key ? val : defaultDesc;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff0f172a) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(
          top: BorderSide(color: Color(0xfff59e0b), width: 1.8),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xffcbd5e1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xfff59e0b).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.military_tech_rounded, color: Color(0xfffbbf24), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        tr('xp_reward.title'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xff0f172a),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current XP Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff1e293b) : const Color(0xfffef3c7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xfff59e0b).withOpacity(0.4)
                            : const Color(0xfffde68a),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xfff59e0b), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          tr('xp_reward.current_xp', params: {'xp': '${appState.xp}'}),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: isDark ? const Color(0xfffbbf24) : const Color(0xffb45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Close Button
                  GestureDetector(
                    onTap: () {
                      AudioService.playClick();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white : const Color(0xff64748b),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tr('xp_reward.subtitle'),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Milestones List
          Expanded(
            child: ListView.separated(
              itemCount: milestones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final m = milestones[idx];
                final targetXp = m['targetXp'] as int;
                final isClaimed = appState.isMilestoneClaimed(targetXp);
                final canClaim = appState.canClaimMilestone(targetXp);
                final Color mColor = m['color'] as Color;
                final IconData mIcon = m['icon'] as IconData;

                final cardBg = canClaim
                    ? (isDark ? const Color(0xff1e293b) : const Color(0xfffffbeb))
                    : (isClaimed
                        ? (isDark ? const Color(0xff09111e) : const Color(0xfff8fafc))
                        : (isDark ? const Color(0xff131d2e) : const Color(0xfff1f5f9)));

                final cardBorder = canClaim
                    ? const Color(0xfff59e0b)
                    : (isClaimed
                        ? (isDark ? Colors.white.withOpacity(0.04) : const Color(0xffe2e8f0))
                        : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0)));

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cardBorder,
                      width: canClaim ? 1.5 : 1.0,
                    ),
                    boxShadow: canClaim
                        ? [
                            BoxShadow(
                              color: const Color(0xfff59e0b).withOpacity(isDark ? 0.18 : 0.12),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Target XP Badge Box
                      Container(
                        width: 52,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: canClaim
                              ? const Color(0xfff59e0b).withOpacity(isDark ? 0.2 : 0.15)
                              : (isDark ? const Color(0xff0f172a) : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: canClaim
                                ? const Color(0xfff59e0b).withOpacity(0.5)
                                : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0)),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isClaimed
                                  ? Icons.check_circle_rounded
                                  : (canClaim ? Icons.lock_open_rounded : Icons.lock_outline_rounded),
                              color: isClaimed
                                  ? const Color(0xff10b981)
                                  : (canClaim
                                      ? (isDark ? const Color(0xfffbbf24) : const Color(0xffd97706))
                                      : const Color(0xff64748b)),
                              size: 16,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "$targetXp",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: canClaim
                                    ? (isDark ? const Color(0xfffbbf24) : const Color(0xffb45309))
                                    : (isClaimed
                                        ? const Color(0xff94a3b8)
                                        : (isDark ? Colors.white : const Color(0xff0f172a))),
                              ),
                            ),
                            Text(
                              tr('xp_reward.xp_unit'),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9,
                                color: Color(0xff64748b),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Reward Icon & Desc
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: mColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: mColor.withOpacity(0.4)),
                        ),
                        child: Icon(mIcon, color: mColor, size: 22),
                      ),
                      const SizedBox(width: 12),

                      // Text Title & Desc
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getMilestoneTitle(targetXp, m['title'] as String),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: isClaimed
                                    ? const Color(0xff94a3b8)
                                    : (isDark ? Colors.white : const Color(0xff0f172a)),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              getMilestoneDesc(targetXp, m['desc'] as String),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Action Button
                      if (isClaimed)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xffe2e8f0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tr('xp_reward.claimed'),
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff64748b),
                            ),
                          ),
                        )
                      else if (canClaim)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff10b981),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 3,
                          ),
                          onPressed: () {
                            appState.claimXpMilestone(targetXp);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  tr('xp_reward.snack_claimed', params: {
                                    'reward': getMilestoneTitle(targetXp, m['title'] as String),
                                  }),
                                ),
                                backgroundColor: const Color(0xff059669),
                              ),
                            );
                          },
                          child: Text(
                            tr('xp_reward.claim_action'),
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xffe2e8f0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tr('xp_reward.xp_needed', params: {'xp': '${targetXp - appState.xp}'}),
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff64748b),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
