import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../state/app_state.dart';

class LeaderboardModal extends StatefulWidget {
  const LeaderboardModal({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LeaderboardModal(),
    );
  }

  @override
  State<LeaderboardModal> createState() => _LeaderboardModalState();
}

class _LeaderboardModalState extends State<LeaderboardModal> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.loadLeaderboard();
    });
  }

  IconData _getAvatarIcon(String avatarId) {
    switch (avatarId) {
      case 'bull': return Icons.trending_up_rounded;
      case 'chart': return Icons.show_chart_rounded;
      case 'vip': return Icons.workspace_premium_rounded;
      case 'wallet': return Icons.account_balance_wallet_rounded;
      case 'rocket': return Icons.rocket_launch_rounded;
      case 'star': return Icons.stars_rounded;
      case 'shield': return Icons.security_rounded;
      case 'fire': return Icons.local_fire_department_rounded;
      case 'academy': return Icons.school_rounded;
      default: return Icons.person_rounded;
    }
  }

  Color _getAvatarColor(String avatarId) {
    switch (avatarId) {
      case 'bull': return const Color(0xff10b981);
      case 'chart': return const Color(0xff38bdf8);
      case 'vip': return const Color(0xfff59e0b);
      case 'wallet': return const Color(0xff14b8a6);
      case 'rocket': return const Color(0xffa855f7);
      case 'star': return const Color(0xfffbbf24);
      case 'shield': return const Color(0xff059669);
      case 'fire': return const Color(0xffef4444);
      case 'academy': return const Color(0xffec4899);
      default: return const Color(0xff60a5fa);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final leaderboard = appState.leaderboard;
    final isLoading = appState.isLoadingLeaderboard;
    final int userRank = appState.userLeaderboardRank;

    final top1 = leaderboard.isNotEmpty ? leaderboard[0] : null;
    final top2 = leaderboard.length > 1 ? leaderboard[1] : null;
    final top3 = leaderboard.length > 2 ? leaderboard[2] : null;
    final restList = leaderboard.length > 3 ? leaderboard.sublist(3) : <Map<String, dynamic>>[];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Color(0xff0f172a),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xfff59e0b), width: 1.8)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xfff59e0b).withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xfff59e0b).withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: Color(0xfffbbf24), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Liga Trader BEI",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Papan peringkat edukasi & akumulasi XP",
                          style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xff94a3b8)),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xff94a3b8), size: 20),
                      onPressed: () {
                        AudioService.playClick();
                        appState.loadLeaderboard(force: true);
                      },
                    ),
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
          ),
          const SizedBox(height: 12),

          // Body Content
          Expanded(
            child: isLoading && leaderboard.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xfff59e0b), strokeWidth: 2.5),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      // Top 3 Podium
                      if (top1 != null) ...[
                        _buildTopPodium(top1, top2, top3, appState),
                        const SizedBox(height: 16),
                      ],

                      // Rest of Rank List
                      if (restList.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            "Klasemen Peringkat",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff94a3b8),
                            ),
                          ),
                        ),
                        ...List.generate(restList.length, (idx) {
                          final item = restList[idx];
                          final int rankNum = idx + 4;
                          final bool isMe = item['isCurrentUser'] == true;
                          return _buildRankRow(item, rankNum, isMe);
                        }),
                      ],
                    ],
                  ),
          ),

          // Sticky Bottom User Rank Status Bar
          _buildUserRankBottomBar(appState, userRank, leaderboard),
        ],
      ),
    );
  }

  Widget _buildTopPodium(
    Map<String, dynamic> top1,
    Map<String, dynamic>? top2,
    Map<String, dynamic>? top3,
    AppState appState,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xff161f30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // #2 Runner Up
          if (top2 != null)
            _buildPodiumColumn(
              top2,
              rankNum: 2,
              height: 110,
              badgeColor: const Color(0xff94a3b8),
              medalIcon: Icons.military_tech_rounded,
              isMe: top2['isCurrentUser'] == true,
            )
          else
            const SizedBox(width: 85),

          // #1 Champion (Tallest)
          _buildPodiumColumn(
            top1,
            rankNum: 1,
            height: 135,
            badgeColor: const Color(0xfff59e0b),
            medalIcon: Icons.workspace_premium_rounded,
            isMe: top1['isCurrentUser'] == true,
          ),

          // #3 Bronze
          if (top3 != null)
            _buildPodiumColumn(
              top3,
              rankNum: 3,
              height: 95,
              badgeColor: const Color(0xffea580c),
              medalIcon: Icons.military_tech_rounded,
              isMe: top3['isCurrentUser'] == true,
            )
          else
            const SizedBox(width: 85),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn(
    Map<String, dynamic> item, {
    required int rankNum,
    required double height,
    required Color badgeColor,
    required IconData medalIcon,
    required bool isMe,
  }) {
    final String name = (item['name'] ?? 'Trader').toString();
    final int xp = (item['xp'] as num?)?.toInt() ?? 0;
    final String avatarId = (item['avatar'] ?? 'bull').toString();
    final Color avaColor = _getAvatarColor(avatarId);
    final String shortName = name.split(' ').first;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar + Crown / Medal Badge
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: rankNum == 1 ? 52 : 44,
                height: rankNum == 1 ? 52 : 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avaColor.withOpacity(0.18),
                  border: Border.all(
                    color: isMe ? const Color(0xff10b981) : badgeColor,
                    width: rankNum == 1 ? 2.2 : 1.5,
                  ),
                  boxShadow: [
                    if (rankNum == 1)
                      BoxShadow(
                        color: badgeColor.withOpacity(0.35),
                        blurRadius: 14,
                      ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(_getAvatarIcon(avatarId), color: isMe ? const Color(0xff34d399) : avaColor, size: rankNum == 1 ? 26 : 22),
              ),
              // Floating Rank Badge on top
              Positioned(
                top: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: badgeColor.withOpacity(0.4), blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(medalIcon, color: Colors.black, size: 10),
                      const SizedBox(width: 2),
                      Text(
                        "#$rankNum",
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            shortName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: rankNum == 1 ? 13 : 11.5,
              fontWeight: FontWeight.bold,
              color: isMe ? const Color(0xff34d399) : Colors.white,
            ),
          ),
          const SizedBox(height: 2),

          // XP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xff0f172a),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "$xp XP",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: rankNum == 1 ? 11 : 10,
                fontWeight: FontWeight.w900,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankRow(Map<String, dynamic> item, int rankNum, bool isMe) {
    final String name = (item['name'] ?? 'Trader').toString();
    final int xp = (item['xp'] as num?)?.toInt() ?? 0;
    final int streak = (item['streak'] as num?)?.toInt() ?? 0;
    final String avatarId = (item['avatar'] ?? 'bull').toString();
    final Color avaColor = _getAvatarColor(avatarId);

    // Get Tier name for XP
    String tierLabel = "Tier I";
    if (xp >= 1600) {
      tierLabel = "Tier V";
    } else if (xp >= 900) {
      tierLabel = "Tier IV";
    } else if (xp >= 450) {
      tierLabel = "Tier III";
    } else if (xp >= 150) {
      tierLabel = "Tier II";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xff064e3b).withOpacity(0.35) : const Color(0xff161f30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? const Color(0xff10b981).withOpacity(0.6) : Colors.white.withOpacity(0.04),
          width: isMe ? 1.4 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Rank Number
          SizedBox(
            width: 28,
            child: Text(
              "#$rankNum",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isMe ? const Color(0xff34d399) : const Color(0xff94a3b8),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avaColor.withOpacity(0.15),
              border: Border.all(color: avaColor.withOpacity(0.4)),
            ),
            alignment: Alignment.center,
            child: Icon(_getAvatarIcon(avatarId), color: avaColor, size: 17),
          ),
          const SizedBox(width: 10),

          // Name & Tier
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isMe ? const Color(0xff34d399) : Colors.white,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xff065f46),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "ANDA",
                          style: TextStyle(fontFamily: 'Inter', fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xff34d399)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Text(
                      tierLabel,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xff64748b)),
                    ),
                    if (streak > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        "• $streak Hari",
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xfff87171)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // XP Counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xff0f172a),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "$xp XP",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: isMe ? const Color(0xff34d399) : const Color(0xffcbd5e1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRankBottomBar(AppState appState, int userRank, List<Map<String, dynamic>> leaderboard) {
    int xpToOvertake = 0;
    String overtakeName = "";
    if (userRank > 1 && userRank <= leaderboard.length) {
      final prevUser = leaderboard[userRank - 2];
      final prevXp = (prevUser['xp'] as num?)?.toInt() ?? 0;
      xpToOvertake = (prevXp - appState.xp) + 1;
      overtakeName = (prevUser['name'] ?? 'Trader').toString().split(' ').first;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xff161f30),
        border: Border(top: BorderSide(color: Color(0xff1e293b), width: 1.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xff10b981).withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xff10b981).withOpacity(0.4)),
            ),
            child: Text(
              "#$userRank",
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xff34d399),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      appState.userName,
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "• ${appState.xp} XP",
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xfffbbf24)),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  userRank == 1
                      ? "Anda memimpin posisi teratas Liga!"
                      : (xpToOvertake > 0
                          ? "Butuh $xpToOvertake XP lagi untuk menyalip #$userRank-1 ($overtakeName)"
                          : "Terus selesaikan kuis untuk naik peringkat!"),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    color: userRank == 1 ? const Color(0xfffbbf24) : const Color(0xff94a3b8),
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
