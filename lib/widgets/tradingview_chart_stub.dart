import 'package:flutter/material.dart';

/// Native Dart VM & Test Stub for TradingViewChart.
/// Renders a responsive placeholder widget in tests and native platforms
/// without any browser-specific dependencies (dart:html / dart:ui_web).
class TradingViewChart extends StatelessWidget {
  final String ticker;
  final String timeframe;
  final List<Map<String, dynamic>>? candles;
  final bool? isDark;

  const TradingViewChart({
    Key? key,
    required this.ticker,
    this.timeframe = '1D',
    this.candles,
    this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    return Container(
      key: const ValueKey('tradingview_chart_stub'),
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xff0b0f19) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkTheme ? const Color(0xff10b981).withOpacity(0.3) : const Color(0xffe2e8f0),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.show_chart_rounded, color: Color(0xff10b981), size: 36),
          const SizedBox(height: 8),
          Text(
            'TradingView Chart: $ticker ($timeframe)',
            style: TextStyle(
              color: isDarkTheme ? Colors.white70 : const Color(0xff0f172a),
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
