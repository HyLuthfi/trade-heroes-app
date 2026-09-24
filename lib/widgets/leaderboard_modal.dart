import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/avatar_data.dart';
import '../l10n/app_translations.dart';
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

  String _tr(String language, String key, {Map<String, String> params = const {}}) =>
      AppTranslations.text(language, key, params: params);

  Widget _buildAvatarImage(String avatar, double size, Color iconColor, double iconSize) {
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return ClipOval(
        child: Image.network(
          avatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            AvatarData.getIcon(avatar),
            color: iconColor,
            size: iconSize,
          ),
        ),
      );
    } else if (avatar.startsWith('data:image')) {
      try {
        final b64 = avatar.split(',').last;
        final bytes = base64Decode(b64);
        return ClipOval(
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              AvatarData.getIcon(avatar),
              color: iconColor,
              size: iconSize,
            ),
          ),
        );
      } catch (_) {
        return Icon(AvatarData.getIcon(avatar), color: iconColor, size: iconSize);
      }
    } else {
      return Icon(AvatarData.getIcon(avatar), color: iconColor, size: iconSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
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
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff0f172a) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xfff59e0b) : const Color(0xffd97706),
            width: 1.8,
          ),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xffcbd5e1),
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
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xfff59e0b).withOpacity(isDark ? 0.18 : 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xfff59e0b).withOpacity(0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Color(0xfffbbf24),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tr(appState.language, 'leaderboard.title'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xff0f172a),
                              ),
                            ),
                            Text(
                              _tr(appState.language, 'leaderboard.subtitle'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10.5,
                                color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                        size: 20,
                      ),
                      onPressed: () {
                        AudioService.playClick();
                        appState.loadLeaderboard(force: true);
                      },
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
                        _buildTopPodium(top1, top2, top3, appState, isDark),
                        const SizedBox(height: 16),
                      ],

                      // Rest of Rank List
                      if (restList.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            _tr(appState.language, 'leaderboard.rankings_header'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                            ),
                          ),
                        ),
                        ...List.generate(restList.length, (idx) {
                          final item = restList[idx];
                          final int rankNum = idx + 4;
                          final bool isMe = item['isCurrentUser'] == true;
                          return _buildRankRow(item, rankNum, isMe, appState, isDark);
                        }),
                      ],
                    ],
                  ),
          ),

          // Sticky Bottom User Rank Status Bar
          _buildUserRankBottomBar(appState, userRank, leaderboard, isDark),
        ],
      ),
    );
  }

  Widget _buildTopPodium(
    Map<String, dynamic> top1,
    Map<String, dynamic>? top2,
    Map<String, dynamic>? top3,
    AppState appState,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff161f30) : const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0),
        ),
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
              isDark: isDark,
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
            isDark: isDark,
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
              isDark: isDark,
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
    required bool isDark,
  }) {
    final String name = (item['name'] ?? 'Trader').toString();
    final int xp = (item['xp'] as num?)?.toInt() ?? 0;
    final String avatarId = (item['avatar'] ?? 'bull').toString();
    final Color avaColor = AvatarData.getColor(avatarId);
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
                        color: badgeColor.withOpacity(isDark ? 0.35 : 0.25),
                        blurRadius: 14,
                      ),
                  ],
                ),
                alignment: Alignment.center,
                child: _buildAvatarImage(
                  avatarId,
                  rankNum == 1 ? 48 : 40,
                  isMe ? const Color(0xff34d399) : avaColor,
                  rankNum == 1 ? 26 : 22,
                ),
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
                      BoxShadow(
                        color: badgeColor.withOpacity(0.4),
                        blurRadius: 6,
                      ),
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
              color: isMe
                  ? (isDark ? const Color(0xff34d399) : const Color(0xff059669))
                  : (isDark ? Colors.white : const Color(0xff0f172a)),
            ),
          ),
          const SizedBox(height: 2),

          // XP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff0f172a) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? Colors.transparent : const Color(0xffe2e8f0),
              ),
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

  Widget _buildRankRow(
    Map<String, dynamic> item,
    int rankNum,
    bool isMe,
    AppState appState,
    bool isDark,
  ) {
    final String name = (item['name'] ?? 'Trader').toString();
    final int xp = (item['xp'] as num?)?.toInt() ?? 0;
    final int streak = (item['streak'] as num?)?.toInt() ?? 0;
    final String avatarId = (item['avatar'] ?? 'bull').toString();
    final Color avaColor = AvatarData.getColor(avatarId);

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
        color: isMe
            ? (isDark ? const Color(0xff064e3b).withOpacity(0.35) : const Color(0xffd1fae5))
            : (isDark ? const Color(0xff161f30) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? (isDark ? const Color(0xff10b981).withOpacity(0.6) : const Color(0xff10b981))
              : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xffe2e8f0)),
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
                color: isMe
                    ? (isDark ? const Color(0xff34d399) : const Color(0xff065f46))
                    : (isDark ? const Color(0xff94a3b8) : const Color(0xff64748b)),
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
            child: _buildAvatarImage(avatarId, 30, avaColor, 17),
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
                          color: isMe
                              ? (isDark ? const Color(0xff34d399) : const Color(0xff065f46))
                              : (isDark ? Colors.white : const Color(0xff0f172a)),
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xff065f46) : const Color(0xff10b981),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _tr(appState.language, 'leaderboard.badge_you'),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
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
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: Color(0xff64748b),
                      ),
                    ),
                    if (streak > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        _tr(appState.language, 'leaderboard.streak_days', params: {'count': '$streak'}),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: Color(0xfff87171),
                        ),
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
              color: isDark
                  ? const Color(0xff0f172a)
                  : (isMe ? Colors.white : const Color(0xfff1f5f9)),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? Colors.transparent : const Color(0xffe2e8f0),
              ),
            ),
            child: Text(
              "$xp XP",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: isMe
                    ? (isDark ? const Color(0xff34d399) : const Color(0xff065f46))
                    : (isDark ? const Color(0xffcbd5e1) : const Color(0xff334155)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRankBottomBar(
    AppState appState,
    int userRank,
    List<Map<String, dynamic>> leaderboard,
    bool isDark,
  ) {
    int xpToOvertake = 0;
    String overtakeName = "";
    int targetRank = 1;
    if (userRank > 1 && userRank <= leaderboard.length) {
      final prevUser = leaderboard[userRank - 2];
      final prevXp = (prevUser['xp'] as num?)?.toInt() ?? 0;
      xpToOvertake = (prevXp - appState.xp) + 1;
      targetRank = userRank - 1;
      overtakeName = (prevUser['name'] ?? 'Trader').toString().split(' ').first;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff161f30) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0),
            width: 1.2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xff10b981).withOpacity(0.18)
                  : const Color(0xffd1fae5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? const Color(0xff10b981).withOpacity(0.4)
                    : const Color(0xffa7f3d0),
              ),
            ),
            child: Text(
              "#$userRank",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isDark ? const Color(0xff34d399) : const Color(0xff065f46),
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
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xff0f172a),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "• ${appState.xp} XP",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xfffbbf24) : const Color(0xffd97706),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  userRank == 1
                      ? _tr(appState.language, 'leaderboard.leading_league')
                      : (xpToOvertake > 0
                          ? _tr(appState.language, 'leaderboard.overtake_prompt', params: {
                              'xp': '$xpToOvertake',
                              'rank': '$targetRank',
                              'name': overtakeName,
                            })
                          : _tr(appState.language, 'leaderboard.keep_learning')),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    color: userRank == 1
                        ? (isDark ? const Color(0xfffbbf24) : const Color(0xffd97706))
                        : (isDark ? const Color(0xff94a3b8) : const Color(0xff64748b)),
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
