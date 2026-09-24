import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_translations.dart';
import '../services/audio_service.dart';
import '../state/app_state.dart';
import 'leaderboard_modal.dart';
import 'xp_reward_modal.dart';

class RankProgressionModal extends StatelessWidget {
  const RankProgressionModal({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RankProgressionModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final curRank = appState.currentRank;
    final nextRank = appState.nextRank;
    final progress = appState.rankProgress;
    final int curTier = curRank['tier'] as int;
    final Color curColor = curRank['color'] as Color;

    String tr(String key, {Map<String, String> params = const {}}) =>
        AppTranslations.text(appState.language, key, params: params);

    String getRankTitle(int tier, String defaultTitle) {
      final key = 'rank.tier${tier}_title';
      final val = tr(key);
      return val != key ? val : defaultTitle;
    }

    String getRankDesc(int tier, String defaultDesc) {
      final key = 'rank.tier${tier}_desc';
      final val = tr(key);
      return val != key ? val : defaultDesc;
    }

    String getRankPerk(int tier, String defaultPerk) {
      final key = 'rank.tier${tier}_perk';
      final val = tr(key);
      return val != key ? val : defaultPerk;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff0f172a) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xff334155) : const Color(0xffe2e8f0),
            width: 1.5,
          ),
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

          // Header title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: curColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(curRank['icon'] as IconData, color: curColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    tr('rank.title'),
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
          const SizedBox(height: 12),

          // Sub-bar Navigasi Cepat (Hadiah XP & Liga Trader)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    AudioService.playClick();
                    Navigator.of(context).pop();
                    XpRewardModal.show(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xff064e3b).withOpacity(0.4)
                          : const Color(0xffd1fae5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: appState.unclaimedMilestonesCount > 0
                            ? (isDark ? const Color(0xff10b981) : const Color(0xff059669))
                            : (isDark ? const Color(0xff10b981).withOpacity(0.3) : const Color(0xffa7f3d0)),
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_giftcard_rounded,
                          color: isDark ? const Color(0xff34d399) : const Color(0xff059669),
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            tr('rank.nav_xp_rewards'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: isDark ? const Color(0xff34d399) : const Color(0xff065f46),
                            ),
                          ),
                        ),
                        if (appState.unclaimedMilestonesCount > 0) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xffef4444),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${appState.unclaimedMilestonesCount}",
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    AudioService.playClick();
                    Navigator.of(context).pop();
                    LeaderboardModal.show(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xff78350f).withOpacity(0.35)
                          : const Color(0xfffef3c7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xfff59e0b).withOpacity(0.35)
                            : const Color(0xfffde68a),
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          color: isDark ? const Color(0xfffbbf24) : const Color(0xffd97706),
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            tr('rank.nav_leaderboard'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: isDark ? const Color(0xfffbbf24) : const Color(0xffb45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Active Rank Hero Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  curColor.withOpacity(isDark ? 0.12 : 0.16),
                  isDark ? const Color(0xff1e293b) : const Color(0xfff8fafc),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: curColor.withOpacity(isDark ? 0.4 : 0.5),
                width: 1.2,
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
                        Text(
                          tr('rank.tier_badge', params: {'tier': curRank['roman'].toString()}),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: curColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xff064e3b) : const Color(0xffd1fae5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tr('rank.badge_active'),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isDark ? const Color(0xff34d399) : const Color(0xff059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      tr('rank.total_xp', params: {'xp': '${appState.xp}'}),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xff0f172a),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  getRankTitle(curTier, curRank['title'] as String),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xff0f172a),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  getRankDesc(curTier, curRank['desc'] as String),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                  ),
                ),
                const SizedBox(height: 14),

                // XP Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: isDark ? const Color(0xff0b0f19) : const Color(0xffe2e8f0),
                    valueColor: AlwaysStoppedAnimation<Color>(curColor),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      nextRank != null
                          ? tr('rank.target_xp', params: {'xp': '${nextRank['minXp']}'})
                          : tr('rank.highest_rank_reached'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Color(0xff64748b),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        nextRank != null
                            ? tr('rank.xp_remaining', params: {
                                'xp': '${appState.xpToNextRank}',
                                'rank': getRankTitle(nextRank['tier'] as int, nextRank['title'] as String),
                              })
                            : tr('rank.pinnacle_master'),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: curColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            tr('rank.all_tiers'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          // Scrollable list of 5 Tiers
          Expanded(
            child: ListView.separated(
              itemCount: AppState.traderRanks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final r = AppState.traderRanks[idx];
                final tierNum = r['tier'] as int;
                final bool isCurrent = tierNum == curTier;
                final bool isPassed = tierNum < curTier;
                final Color tierColor = r['color'] as Color;

                final cardBg = isCurrent
                    ? tierColor.withOpacity(isDark ? 0.08 : 0.12)
                    : (isPassed
                        ? (isDark ? const Color(0xff161f30) : const Color(0xfff8fafc))
                        : (isDark ? const Color(0xff111827) : const Color(0xfff1f5f9)));

                final cardBorder = isCurrent
                    ? tierColor.withOpacity(isDark ? 0.6 : 0.7)
                    : (isPassed
                        ? (isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0))
                        : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xffe2e8f0)));

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cardBorder,
                      width: isCurrent ? 1.4 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Tier Icon in circle
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPassed
                              ? (isDark ? const Color(0xff064e3b) : const Color(0xffd1fae5))
                              : (isCurrent
                                  ? tierColor.withOpacity(isDark ? 0.2 : 0.25)
                                  : (isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0))),
                          border: Border.all(
                            color: isPassed
                                ? (isDark ? const Color(0xff10b981) : const Color(0xff059669))
                                : (isCurrent ? tierColor : (isDark ? const Color(0xff334155) : const Color(0xffcbd5e1))),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: isPassed
                            ? Icon(Icons.check_rounded, color: isDark ? const Color(0xff34d399) : const Color(0xff059669), size: 18)
                            : Icon(r['icon'] as IconData, color: isCurrent ? tierColor : const Color(0xff64748b), size: 18),
                      ),
                      const SizedBox(width: 12),

                      // Title & Perk
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    tr('rank.tier_item_title', params: {
                                      'roman': r['roman'].toString(),
                                      'title': getRankTitle(tierNum, r['title'] as String),
                                    }),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: isCurrent
                                          ? (isDark ? Colors.white : const Color(0xff0f172a))
                                          : (isPassed
                                              ? (isDark ? const Color(0xffcbd5e1) : const Color(0xff334155))
                                              : (isDark ? const Color(0xff94a3b8) : const Color(0xff64748b))),
                                    ),
                                  ),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: tierColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tr('rank.badge_you'),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        color: tierColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              getRankPerk(tierNum, r['perk'] as String),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10.5,
                                color: Color(0xff64748b),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // XP Range pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xff0b0f19) : const Color(0xfff1f5f9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0)),
                        ),
                        child: Text(
                          tierNum == 5
                              ? tr('rank.xp_plus', params: {'min': '1.600'})
                              : tr('rank.xp_range', params: {'min': '${r['minXp']}', 'max': '${r['maxXp']}'}),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isCurrent ? tierColor : const Color(0xff64748b),
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
