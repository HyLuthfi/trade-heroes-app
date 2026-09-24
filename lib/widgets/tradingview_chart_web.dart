import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

/// Professional TradingView Official Chart iframe widget for Flutter Web.
class TradingViewChart extends StatefulWidget {
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
  State<TradingViewChart> createState() => _TradingViewChartState();
}

class _TradingViewChartState extends State<TradingViewChart> {
  late String _viewId;
  html.IFrameElement? _iframe;
  bool? _lastIsDark;

  @override
  void initState() {
    super.initState();
    final cleanTicker = widget.ticker.split('_').first.toUpperCase();
    _viewId = 'tv-iframe-$cleanTicker-${DateTime.now().microsecondsSinceEpoch}';
  }

  void _registerView(bool isDarkTheme) {
    if (_iframe != null) return;
    final cleanTicker = widget.ticker.split('_').first.toUpperCase();
    final themeParam = isDarkTheme ? 'dark' : 'light';
    final bgHex = isDarkTheme ? '#0b0f19' : '#ffffff';

    _iframe = html.IFrameElement()
      ..src = '/tv_chart.html?v=tv_strict_1d_v4&ticker=$cleanTicker&theme=$themeParam'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = bgHex
      ..setAttribute('allowtransparency', 'true');

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _iframe!,
    );
  }

  void _updateChart(bool isDarkTheme) {
    final cleanTicker = widget.ticker.split('_').first.toUpperCase();
    final themeParam = isDarkTheme ? 'dark' : 'light';
    final bgHex = isDarkTheme ? '#0b0f19' : '#ffffff';

    if (_iframe != null) {
      _iframe!.style.backgroundColor = bgHex;
      _iframe!.src = '/tv_chart.html?v=tv_strict_1d_v4&ticker=$cleanTicker&theme=$themeParam';
    }
  }

  @override
  void didUpdateWidget(covariant TradingViewChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cleanTicker = widget.ticker.split('_').first.toUpperCase();
    final oldCleanTicker = oldWidget.ticker.split('_').first.toUpperCase();
    final currentIsDark = widget.isDark ?? _lastIsDark ?? true;

    if (cleanTicker != oldCleanTicker || widget.isDark != oldWidget.isDark) {
      _updateChart(currentIsDark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = widget.isDark ?? (Theme.of(context).brightness == Brightness.dark);

    if (_iframe == null) {
      _registerView(isDarkTheme);
      _lastIsDark = isDarkTheme;
    } else if (_lastIsDark != isDarkTheme) {
      _lastIsDark = isDarkTheme;
      _updateChart(isDarkTheme);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xff0b0f19) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkTheme ? const Color(0xff10b981).withOpacity(0.3) : const Color(0xffe2e8f0),
          width: 1.2,
        ),
        boxShadow: isDarkTheme
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: HtmlElementView(viewType: _viewId),
    );
  }
}
