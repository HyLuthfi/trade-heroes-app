import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/audio_service.dart';
import 'ad_overlay.dart';
import 'daily_reward_modal.dart';

class PetirInfoModal extends StatelessWidget {
  const PetirInfoModal({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PetirInfoModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final bool isPremium = appState.isPremium;
    final int currentPetir = appState.petir;
    final bool isOverflow = !isPremium && currentPetir > 5;
    final bool isFull = currentPetir >= 5;
    final String regenTime = appState.getPetirRegenTime();
    final double regenFraction = appState.getPetirRegenFraction();

    final Color primaryColor = isPremium
        ? const Color(0xfff59e0b) // Amber Gold
        : (isOverflow
            ? const Color(0xff10b981) // Emerald Green for Overflow
            : (currentPetir > 0 ? const Color(0xffef4444) : const Color(0xff64748b)));

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xff0f172a),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xffef4444), width: 2.0)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // 3D Glowing Bolt Aura
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(0.15),
              border: Border.all(color: primaryColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.flash_on_rounded, color: primaryColor, size: 40),
          ),
          const SizedBox(height: 12),

          const Text(
            "STATUS NYAWA PETIR",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),

          // Count Display
          if (isPremium)
            const Text(
              "TAK TERBATAS (VIP PASS)",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xfff59e0b),
                letterSpacing: 0.5,
              ),
            )
          else if (isOverflow)
            Column(
              children: [
                Text(
                  "$currentPetir NYAWA PETIR",
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff10b981),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xff065f46),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xff10b981).withOpacity(0.4)),
                  ),
                  child: const Text(
                    "BONUS HADIAH AKTIF (KAPASITAS REGULER: 5)",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xffa7f3d0),
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              "$currentPetir / 5 NYAWA PETIR",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: currentPetir > 0 ? Colors.white : const Color(0xffef4444),
              ),
            ),

          const SizedBox(height: 18),

          // Recovery Countdown Box (if petir < 5 and not premium)
          if (!isPremium && currentPetir < 5) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xff1e293b),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xff334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.hourglass_top_rounded, color: Color(0xff38bdf8), size: 16),
                          SizedBox(width: 6),
                          Text(
                            "Pemulihan Otomatis (+1 Petir)",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (regenTime.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xff0284c7).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xff0284c7).withOpacity(0.4)),
                          ),
                          child: Text(
                            regenTime,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xff38bdf8),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: regenFraction,
                      minHeight: 6,
                      backgroundColor: Colors.black.withOpacity(0.4),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff38bdf8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Rules Guarantee Card (Candy Crush Principle)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xff1e293b).withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xff334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.verified_user_rounded, color: Color(0xff10b981), size: 16),
                    SizedBox(width: 6),
                    Text(
                      "Jaminan Belajar Bebas Khawatir",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff10b981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "• Nyawa petir TIDAK BERKURANG jika kuis lulus minimal 1 bintang.\n"
                  "• Petir hanya berkurang (-1) jika Anda gagal total (0 bintang) atau menyerah.\n"
                  "• Bonus nyawa dari Absen Harian & Milestone XP tersimpan aman dan tidak hangus.",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: Color(0xffcbd5e1),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          if (!isPremium && currentPetir < 5) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff10b981),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  AdOverlay.show(context, () {
                    appState.refillOnePetir();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("1 Nyawa petir telah berhasil dipulihkan.")),
                    );
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.smart_display_rounded, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "TONTON IKLAN (+1 NYAWA)",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (appState.canClaimDailyToday) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xfff59e0b), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  DailyRewardModal.show(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.card_giftcard_rounded, size: 18, color: Color(0xfff59e0b)),
                    SizedBox(width: 6),
                    Text(
                      "KLAIM ABSEN HARIAN",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xfff59e0b),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "TUTUP",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xff94a3b8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
