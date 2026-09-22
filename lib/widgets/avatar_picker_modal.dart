import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class AvatarPickerModal extends StatelessWidget {
  const AvatarPickerModal({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AvatarPickerModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final String currentAvatar = appState.userAvatar;

    final List<Map<String, dynamic>> avatars = [
      {
        'id': 'bull',
        'title': 'Banteng Pro',
        'desc': 'Trader Tangguh Market Bullish',
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xff10b981),
      },
      {
        'id': 'bear',
        'title': 'Bear Master',
        'desc': 'Pakar Analisis Tren Bearish',
        'icon': Icons.south_west_rounded,
        'color': const Color(0xfff87171),
      },
      {
        'id': 'vip',
        'title': 'VIP Executive',
        'desc': 'Member Sultan Akses Terdepan',
        'icon': Icons.workspace_premium_rounded,
        'color': const Color(0xfff59e0b),
      },
      {
        'id': 'chart',
        'title': 'Chart Specialist',
        'desc': 'Master Candlestick & Teknikal',
        'icon': Icons.candlestick_chart_rounded,
        'color': const Color(0xff38bdf8),
      },
      {
        'id': 'bandar',
        'title': 'Detektif Bandar',
        'desc': 'Pakar Bandarmologi & Flow',
        'icon': Icons.visibility_rounded,
        'color': const Color(0xffa855f7),
      },
      {
        'id': 'champion',
        'title': 'Hero Champion',
        'desc': 'Juara Utama Akademi Saham',
        'icon': Icons.emoji_events_rounded,
        'color': const Color(0xffeab308),
      },
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
          // Drag handle pill
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            "PILIH AVATAR TRADER 🎭",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Pilih karakter avatar 3D favorit untuk identitas profil Anda!",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xff94a3b8)),
          ),
          const SizedBox(height: 20),

          // Avatar Grid 2x3
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: avatars.length,
            itemBuilder: (context, idx) {
              final av = avatars[idx];
              final String id = av['id'] as String;
              final bool isSelected = currentAvatar == id;
              final Color color = av['color'] as Color;

              return GestureDetector(
                onTap: () {
                  appState.updateAvatar(id);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Avatar berhasil diubah menjadi ${av['title']}! 🎭"),
                      backgroundColor: const Color(0xff059669),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xff064e3b) : const Color(0xff1e293b),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xff10b981) : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: isSelected
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.2),
                          border: Border.all(color: color.withOpacity(0.5)),
                        ),
                        child: Icon(av['icon'] as IconData, color: color, size: 28),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        av['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xffcbd5e1),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
