import 'package:flutter/material.dart';

class AvatarItem {
  final String id;
  final String titleId;
  final String titleEn;
  final String descId;
  final String descEn;
  final IconData icon;
  final Color color;

  const AvatarItem({
    required this.id,
    required this.titleId,
    required this.titleEn,
    required this.descId,
    required this.descEn,
    required this.icon,
    required this.color,
  });

  String getTitle(String lang) => lang == 'en' ? titleEn : titleId;
  String getDesc(String lang) => lang == 'en' ? descEn : descId;
}

class AvatarData {
  static const List<AvatarItem> avatars = [
    AvatarItem(
      id: 'bull',
      titleId: 'Banteng Pro',
      titleEn: 'Bull Pro',
      descId: 'Trader Tangguh Tren Bullish',
      descEn: 'Tough Bull Market Trader',
      icon: Icons.trending_up_rounded,
      color: Color(0xff10b981),
    ),
    AvatarItem(
      id: 'bear',
      titleId: 'Bear Master',
      titleEn: 'Bear Master',
      descId: 'Pakar Analisis Tren Bearish',
      descEn: 'Bear Market Trend Specialist',
      icon: Icons.south_west_rounded,
      color: Color(0xfff87171),
    ),
    AvatarItem(
      id: 'chart',
      titleId: 'Chartist Pro',
      titleEn: 'Chart Specialist',
      descId: 'Master Candlestick & Teknikal',
      descEn: 'Candlestick & Technical Master',
      icon: Icons.candlestick_chart_rounded,
      color: Color(0xff38bdf8),
    ),
    AvatarItem(
      id: 'vip',
      titleId: 'VIP Executive',
      titleEn: 'VIP Executive',
      descId: 'Member Sultan Akses Terdepan',
      descEn: 'Elite Sultan Top Tier',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xfff59e0b),
    ),
    AvatarItem(
      id: 'bandar',
      titleId: 'Detektif Bandar',
      titleEn: 'Whale Detective',
      descId: 'Pakar Bandarmologi & Smart Money',
      descEn: 'Smart Money & Flow Specialist',
      icon: Icons.visibility_rounded,
      color: Color(0xffa855f7),
    ),
    AvatarItem(
      id: 'champion',
      titleId: 'Hero Champion',
      titleEn: 'Hero Champion',
      descId: 'Juara Utama Akademi Saham',
      descEn: 'Stock Academy Grand Champion',
      icon: Icons.emoji_events_rounded,
      color: Color(0xffeab308),
    ),
    AvatarItem(
      id: 'rocket',
      titleId: 'Rocket Breakout',
      titleEn: 'Rocket Breakout',
      descId: 'Pemburu Saham Momentum & ARA',
      descEn: 'Momentum & Upper Limit Hunter',
      icon: Icons.rocket_launch_rounded,
      color: Color(0xff06b6d4),
    ),
    AvatarItem(
      id: 'fire',
      titleId: 'Scalper Kilat',
      titleEn: 'Scalper Pro',
      descId: 'Eksekusi Cepat Profit Maksimal',
      descEn: 'High Speed Rapid Execution',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xfff97316),
    ),
    AvatarItem(
      id: 'shield',
      titleId: 'Risk Guardian',
      titleEn: 'Risk Guardian',
      descId: 'Disiplin Ketat Manajemen Risiko',
      descEn: 'Strict Disciplined Risk Manager',
      icon: Icons.security_rounded,
      color: Color(0xff6366f1),
    ),
    AvatarItem(
      id: 'academy',
      titleId: 'Master Edukasi',
      titleEn: 'Academy Scholar',
      descId: 'Riset Fundamental & Analisis Nilai',
      descEn: 'Fundamental & Value Research',
      icon: Icons.school_rounded,
      color: Color(0xffec4899),
    ),
    AvatarItem(
      id: 'wallet',
      titleId: 'Super Whale',
      titleEn: 'Mega Whale',
      descId: 'Kekuatan Likuiditas & Portofolio Jumbo',
      descEn: 'Massive Liquidity & Jumbo Portfolio',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xff14b8a6),
    ),
    AvatarItem(
      id: 'star',
      titleId: 'Market Legend',
      titleEn: 'Market Legend',
      descId: 'Trader Legendaris Pasar Modal',
      descEn: 'Legendary Stock Market Trader',
      icon: Icons.stars_rounded,
      color: Color(0xffe11d48),
    ),
  ];

  static AvatarItem getById(String avatarId) {
    return avatars.firstWhere(
      (a) => a.id == avatarId,
      orElse: () => avatars.first,
    );
  }

  static IconData getIcon(String avatarId) {
    final item = avatars.cast<AvatarItem?>().firstWhere(
          (a) => a?.id == avatarId,
          orElse: () => null,
        );
    return item?.icon ?? Icons.trending_up_rounded;
  }

  static Color getColor(String avatarId) {
    if (avatarId.startsWith('http') || avatarId.startsWith('data:image')) {
      return const Color(0xff10b981);
    }
    final item = avatars.cast<AvatarItem?>().firstWhere(
          (a) => a?.id == avatarId,
          orElse: () => null,
        );
    return item?.color ?? const Color(0xff10b981);
  }

  static String getTitle(String avatarId, String lang) {
    return getById(avatarId).getTitle(lang);
  }
}
