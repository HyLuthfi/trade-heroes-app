import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class VipPassModal {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _VipPassDialogContent(),
    );
  }
}

class _VipPassDialogContent extends StatefulWidget {
  const _VipPassDialogContent({Key? key}) : super(key: key);

  @override
  State<_VipPassDialogContent> createState() => _VipPassDialogContentState();
}

class _VipPassDialogContentState extends State<_VipPassDialogContent> {
  int _selectedPlanIdx = 1; // Default: Annual (Best Value)

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return AlertDialog(
      backgroundColor: const Color(0xff0f172a),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: Color(0xfff59e0b), width: 1.8),
      ),
      contentPadding: const EdgeInsets.all(22),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button & Crown Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xff78350f).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xfff59e0b).withOpacity(0.6)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.workspace_premium_rounded, color: Color(0xfff59e0b), size: 14),
                    SizedBox(width: 5),
                    Text(
                      "VIP GOLD PASS",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xfffbbf24),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Color(0xff94a3b8), size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Crown Icon Visual Aura
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff78350f).withOpacity(0.35),
                border: Border.all(color: const Color(0xfff59e0b), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xfff59e0b).withOpacity(0.55),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.workspace_premium_rounded, color: Color(0xfffbbf24), size: 44),
            ),
          ),
          const SizedBox(height: 14),

          // Title & Subtitle
          const Center(
            child: Text(
              "AKSES VIP TANPA BATAS",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              "Kuasai ilmu trading saham profesional tanpa batas nyawa dan bebas iklan selamanya.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: Color(0xffcbd5e1),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.12), height: 1),
          const SizedBox(height: 14),

          // Feature Checklist
          _buildFeatureRow(Icons.bolt_rounded, const Color(0xffef4444), "Nyawa Petir Tak Terbatas", "Bebas latihan kuis sepuasnya tanpa pernah kehabisan nyawa"),
          const SizedBox(height: 10),
          _buildFeatureRow(Icons.block_rounded, const Color(0xff10b981), "100% Bebas Iklan Sponsor", "Belajar fokus tanpa gangguan iklan pop-up sama sekali"),
          const SizedBox(height: 10),
          _buildFeatureRow(Icons.menu_book_rounded, const Color(0xff3b82f6), "Seluruh Modul Rahasia Unlocked", "Akses penuh strategi Day Trading, Swing, & Analisis Bandarmologi"),
          const SizedBox(height: 16),

          // Pricing Selector Cards
          Row(
            children: [
              Expanded(
                child: _buildPlanCard(
                  idx: 0,
                  title: "Bulanan",
                  price: "Rp 49.000",
                  period: "/ bulan",
                  tag: null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPlanCard(
                  idx: 1,
                  title: "Tahunan",
                  price: "Rp 299.000",
                  period: "/ tahun",
                  tag: "HEMAT 50% 🔥",
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Upgrade Button
          if (appState.isPremium)
            Container(
              width: double.infinity,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xff064e3b),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xff10b981)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle_rounded, color: Color(0xff34d399), size: 18),
                  SizedBox(width: 6),
                  Text(
                    "AKUN ANDA SUDAH VIP GOLD 👑",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xff34d399),
                    ),
                  ),
                ],
              ),
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffd97706),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                appState.upgradeToPremium(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Selamat! Akun Anda telah berhasil di-upgrade ke VIP GOLD PASS 👑!"),
                    backgroundColor: Color(0xff059669),
                  ),
                );
              },
              icon: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
              label: const Text(
                "GABUNG VIP GOLD PASS SEKARANG 👑",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, Color iconColor, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: Color(0xff94a3b8),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required int idx,
    required String title,
    required String price,
    required String period,
    required String? tag,
  }) {
    final isSelected = _selectedPlanIdx == idx;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanIdx = idx;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff78350f).withOpacity(0.4) : const Color(0xff1e293b),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xfff59e0b) : Colors.white.withOpacity(0.12),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xfff59e0b).withOpacity(0.3),
                blurRadius: 8,
              ),
          ],
        ),
        child: Column(
          children: [
            if (tag != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xffea580c),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xfffbbf24) : const Color(0xff94a3b8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              price,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              period,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: Color(0xff64748b),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
