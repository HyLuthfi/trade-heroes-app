import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

import 'leaderboard_modal.dart';

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
    final curRank = appState.currentRank;
    final nextRank = appState.nextRank;
    final progress = appState.rankProgress;
    final int curTier = curRank['tier'] as int;
    final Color curColor = curRank['color'] as Color;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Color(0xff0f172a),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xff334155), width: 1.5)),
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
                color: Colors.white.withOpacity(0.2),
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
                  const Text(
                    "Jenjang Karier Trader",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      LeaderboardModal.show(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xfff59e0b).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xfff59e0b).withOpacity(0.4)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.emoji_events_rounded, color: Color(0xfffbbf24), size: 14),
                          SizedBox(width: 4),
                          Text(
                            "Liga Trader",
                            style: TextStyle(
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
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Active Rank Hero Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  curColor.withOpacity(0.12),
                  const Color(0xff1e293b),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: curColor.withOpacity(0.4), width: 1.2),
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
                          "TIER ${curRank['roman']}",
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
                            color: const Color(0xff064e3b),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "AKTIF",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Color(0xff34d399),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "${appState.xp} Total XP",
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  curRank['title'] as String,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  curRank['desc'] as String,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: Color(0xff94a3b8),
                  ),
                ),
                const SizedBox(height: 14),

                // XP Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: const Color(0xff0b0f19),
                    valueColor: AlwaysStoppedAnimation<Color>(curColor),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      nextRank != null
                          ? "Target: ${nextRank['minXp']} XP"
                          : "Gelar Tertinggi Tercapai",
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Color(0xff64748b),
                      ),
                    ),
                    Text(
                      nextRank != null
                          ? "${appState.xpToNextRank} XP lagi menuju ${nextRank['title']}"
                          : "Puncak Master Trader",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: curColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            "Semua Tingkatan Trader",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: Color(0xff94a3b8),
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

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? tierColor.withOpacity(0.08)
                        : (isPassed ? const Color(0xff161f30) : const Color(0xff111827)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCurrent
                          ? tierColor.withOpacity(0.6)
                          : (isPassed ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.04)),
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
                              ? const Color(0xff064e3b)
                              : (isCurrent ? tierColor.withOpacity(0.2) : const Color(0xff1e293b)),
                          border: Border.all(
                            color: isPassed
                                ? const Color(0xff10b981)
                                : (isCurrent ? tierColor : const Color(0xff334155)),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: isPassed
                            ? const Icon(Icons.check_rounded, color: Color(0xff34d399), size: 18)
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
                                Text(
                                  "Tier ${r['roman']} • ${r['title']}",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent ? Colors.white : (isPassed ? const Color(0xffcbd5e1) : const Color(0xff94a3b8)),
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
                                      "ANDA",
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
                              r['perk'] as String,
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
                          color: const Color(0xff0b0f19),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xff1e293b)),
                        ),
                        child: Text(
                          tierNum == 5 ? "1.600+ XP" : "${r['minXp']}-${r['maxXp']} XP",
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
