import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

/// Professional TradingView Lightweight Charts iframe widget for Flutter Web.
class TradingViewChart extends StatefulWidget {
  final String ticker;
  final String timeframe;
  final List<Map<String, dynamic>>? candles;

  const TradingViewChart({
    Key? key,
    required this.ticker,
    this.timeframe = '1D',
    this.candles,
  }) : super(key: key);

  @override
  State<TradingViewChart> createState() => _TradingViewChartState();
}

class _TradingViewChartState extends State<TradingViewChart> {
  late String _viewId;
  html.IFrameElement? _iframe;

  @override
  void initState() {
    super.initState();
    _viewId = 'tv-iframe-${DateTime.now().microsecondsSinceEpoch}';
    _registerView();
  }

  void _registerView() {
    final cleanTicker = widget.ticker.split('_').first.toUpperCase();
    _iframe = html.IFrameElement()
      ..src = '/tv_chart.html?v=real_tv_1&ticker=$cleanTicker&tf=${widget.timeframe}'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = '#0b0f19'
      ..setAttribute('allowtransparency', 'true');

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _iframe!,
    );
  }

  @override
  void didUpdateWidget(covariant TradingViewChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cleanTicker = widget.ticker.split('_').first.toUpperCase();
    final oldCleanTicker = oldWidget.ticker.split('_').first.toUpperCase();

    if (cleanTicker != oldCleanTicker || widget.timeframe != oldWidget.timeframe) {
      _iframe?.src = '/tv_chart.html?v=real_tv_1&ticker=$cleanTicker&tf=${widget.timeframe}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff0b0f19),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xff10b981).withOpacity(0.3), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: HtmlElementView(viewType: _viewId),
    );
  }
}
