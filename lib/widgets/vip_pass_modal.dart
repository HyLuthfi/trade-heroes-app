import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_translations.dart';
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
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final language = appState.language;
    String tr(String key, {Map<String, String> params = const {}}) =>
        AppTranslations.text(language, key, params: params);

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xff0f172a) : Colors.white,
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
                  color: isDark ? const Color(0xff78350f).withOpacity(0.5) : const Color(0xfffef3c7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xfff59e0b).withOpacity(0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: Color(0xfff59e0b), size: 14),
                    const SizedBox(width: 5),
                    Text(
                      tr('vip.badge'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: isDark ? const Color(0xfffbbf24) : const Color(0xffb45309),
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
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                    size: 18,
                  ),
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
                color: isDark ? const Color(0xff78350f).withOpacity(0.35) : const Color(0xfffef3c7),
                border: Border.all(color: const Color(0xfff59e0b), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xfff59e0b).withOpacity(isDark ? 0.55 : 0.25),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.workspace_premium_rounded, color: Color(0xfff59e0b), size: 44),
            ),
          ),
          const SizedBox(height: 14),

          // Title & Subtitle
          Center(
            child: Text(
              tr('vip.title'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xff0f172a),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              tr('vip.subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: isDark ? const Color(0xffcbd5e1) : const Color(0xff475569),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xffe2e8f0), height: 1),
          const SizedBox(height: 14),

          // Feature Checklist
          _buildFeatureRow(
            Icons.bolt_rounded,
            const Color(0xffef4444),
            tr('vip.feat_lives_title'),
            tr('vip.feat_lives_desc'),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            Icons.block_rounded,
            const Color(0xff10b981),
            tr('vip.feat_ads_title'),
            tr('vip.feat_ads_desc'),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            Icons.menu_book_rounded,
            const Color(0xff3b82f6),
            tr('vip.feat_modules_title'),
            tr('vip.feat_modules_desc'),
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Pricing Selector Cards
          Row(
            children: [
              Expanded(
                child: _buildPlanCard(
                  idx: 0,
                  title: tr('vip.plan_monthly'),
                  price: tr('vip.plan_monthly_price'),
                  period: tr('vip.plan_monthly_period'),
                  tag: null,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPlanCard(
                  idx: 1,
                  title: tr('vip.plan_yearly'),
                  price: tr('vip.plan_yearly_price'),
                  period: tr('vip.plan_yearly_period'),
                  tag: tr('vip.plan_yearly_tag'),
                  isDark: isDark,
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
                color: isDark ? const Color(0xff064e3b) : const Color(0xffecfdf5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xff10b981)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xff059669), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    tr('vip.already_active'),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xff059669),
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
                  SnackBar(
                    content: Text(tr('vip.upgrade_success')),
                    backgroundColor: const Color(0xff059669),
                  ),
                );
              },
              icon: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
              label: Text(
                tr('vip.cta_upgrade'),
                style: const TextStyle(
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

  Widget _buildFeatureRow(
    IconData icon,
    Color iconColor,
    String title,
    String desc, {
    required bool isDark,
  }) {
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
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xff0f172a),
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
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
    required bool isDark,
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
          color: isSelected
              ? (isDark ? const Color(0xff78350f).withOpacity(0.4) : const Color(0xfffef3c7))
              : (isDark ? const Color(0xff1e293b) : const Color(0xfff8fafc)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xfff59e0b)
                : (isDark ? Colors.white.withOpacity(0.12) : const Color(0xffe2e8f0)),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xfff59e0b).withOpacity(isDark ? 0.3 : 0.2),
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
                color: isSelected
                    ? (isDark ? const Color(0xfffbbf24) : const Color(0xffb45309))
                    : (isDark ? const Color(0xff94a3b8) : const Color(0xff64748b)),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              price,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xff0f172a),
              ),
            ),
            Text(
              period,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: isDark ? const Color(0xff64748b) : const Color(0xff94a3b8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
