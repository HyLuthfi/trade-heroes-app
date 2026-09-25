import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_translations.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = appState.language;
    String tr(String key, {Map<String, String> params = const {}}) =>
        AppTranslations.text(lang, key, params: params);

    final bool isPremium = appState.isPremium;
    final int currentPetir = appState.petir;
    final bool isOverflow = !isPremium && currentPetir > 5;
    final String regenTime = appState.getPetirRegenTime();
    final double regenFraction = appState.getPetirRegenFraction();

    final Color primaryColor = isPremium
        ? const Color(0xfff59e0b) // Amber Gold
        : (isOverflow
            ? const Color(0xff10b981) // Emerald Green for Overflow
            : (currentPetir > 0 ? const Color(0xffef4444) : const Color(0xff64748b)));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff0f172a) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(top: BorderSide(color: Color(0xffef4444), width: 2.0)),
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
              color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xffcbd5e1),
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
                  color: primaryColor.withOpacity(isDark ? 0.4 : 0.25),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.flash_on_rounded, color: primaryColor, size: 40),
          ),
          const SizedBox(height: 12),

          Text(
            tr('petir.modal_title'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xff0f172a),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),

          // Count Display
          if (isPremium)
            Text(
              tr('petir.vip_unlimited'),
              style: const TextStyle(
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
                  tr('petir.overflow_count', params: {'count': '$currentPetir'}),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff10b981),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xff065f46) : const Color(0xffd1fae5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xff10b981).withOpacity(isDark ? 0.4 : 0.6),
                    ),
                  ),
                  child: Text(
                    tr('petir.overflow_badge'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xffa7f3d0) : const Color(0xff065f46),
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              tr('petir.regular_count', params: {'current': '$currentPetir'}),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: currentPetir > 0
                    ? (isDark ? Colors.white : const Color(0xff0f172a))
                    : const Color(0xffef4444),
              ),
            ),

          const SizedBox(height: 18),

          // Recovery Countdown Box (if petir < 5 and not premium)
          if (!isPremium && currentPetir < 5) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff1e293b) : const Color(0xfff8fafc),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xff334155) : const Color(0xffe2e8f0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.hourglass_top_rounded, color: Color(0xff0284c7), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            tr('petir.auto_recovery_title'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xff0f172a),
                            ),
                          ),
                        ],
                      ),
                      if (regenTime.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xff0284c7).withOpacity(isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xff0284c7).withOpacity(0.4)),
                          ),
                          child: Text(
                            regenTime,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xff0284c7),
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
                      backgroundColor: isDark ? Colors.black.withOpacity(0.4) : const Color(0xffe2e8f0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff0284c7)),
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
              color: isDark
                  ? const Color(0xff1e293b).withOpacity(0.7)
                  : const Color(0xffecfdf5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xff334155) : const Color(0xffa7f3d0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xff10b981), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      tr('petir.guarantee_title'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xff10b981) : const Color(0xff059669),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "${tr('petir.guarantee_rule_1')}\n${tr('petir.guarantee_rule_2')}\n${tr('petir.guarantee_rule_3')}",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: isDark ? const Color(0xffcbd5e1) : const Color(0xff334155),
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
                  AudioService.playClick();
                  Navigator.of(context).pop();
                  AdOverlay.show(context, () {
                    appState.refillOnePetir();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('petir.snack_refilled'))),
                    );
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.smart_display_rounded, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      tr('petir.btn_watch_ad'),
                      style: const TextStyle(
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
                  AudioService.playClick();
                  Navigator.of(context).pop();
                  DailyRewardModal.show(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.card_giftcard_rounded, size: 18, color: Color(0xfff59e0b)),
                    const SizedBox(width: 6),
                    Text(
                      tr('petir.btn_claim_daily'),
                      style: const TextStyle(
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
            onPressed: () {
              AudioService.playClick();
              Navigator.of(context).pop();
            },
            child: Text(
              tr('petir.btn_close'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
