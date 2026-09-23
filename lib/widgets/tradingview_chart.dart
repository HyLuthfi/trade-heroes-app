import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

/// Professional TradingView Lightweight Charts widget for Flutter Web.
class TradingViewChart extends StatefulWidget {
  final List<Map<String, dynamic>> candles;
  final String ticker;

  const TradingViewChart({
    Key? key,
    required this.candles,
    required this.ticker,
  }) : super(key: key);

  @override
  State<TradingViewChart> createState() => _TradingViewChartState();
}

class _TradingViewChartState extends State<TradingViewChart> {
  late String _viewId;
  late String _chartId;
  html.DivElement? _container;
  bool _chartReady = false;

  @override
  void initState() {
    super.initState();
    _chartId = 'tvchart_${widget.ticker}_${DateTime.now().millisecondsSinceEpoch}';
    _viewId = 'tvview_$_chartId';
    _registerView();
  }

  void _registerView() {
    _container = html.DivElement()
      ..id = _chartId
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = '#0f172a'
      ..style.borderRadius = '16px'
      ..style.overflow = 'hidden';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _container!,
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _initChart();
    });
  }

  void _initChart() {
    final initJs = '''
    (function() {
      var el = document.getElementById('$_chartId');
      if (!el || !window.LightweightCharts) return;

      var chart = LightweightCharts.createChart(el, {
        autoSize: true,
        layout: {
          background: { type: 'solid', color: '#0f172a' },
          textColor: '#94a3b8',
          fontFamily: 'Inter, sans-serif',
          fontSize: 11,
        },
        grid: {
          vertLines: { color: 'rgba(255,255,255,0.04)' },
          horzLines: { color: 'rgba(255,255,255,0.04)' },
        },
        crosshair: {
          mode: 0,
          vertLine: { color: '#f59e0b', width: 1, style: 2, labelBackgroundColor: '#f59e0b' },
          horzLine: { color: '#f59e0b', width: 1, style: 2, labelBackgroundColor: '#f59e0b' },
        },
        timeScale: {
          borderColor: '#1e293b',
          timeVisible: true,
          secondsVisible: false,
          barSpacing: 8,
        },
        rightPriceScale: {
          borderColor: '#1e293b',
          scaleMargins: { top: 0.1, bottom: 0.25 },
        },
      });

      var candleSeries = chart.addSeries(LightweightCharts.CandlestickSeries, {
        upColor: '#10b981',
        downColor: '#ef4444',
        borderUpColor: '#10b981',
        borderDownColor: '#ef4444',
        wickUpColor: '#10b981',
        wickDownColor: '#ef4444',
      });

      var volumeSeries = chart.addSeries(LightweightCharts.HistogramSeries, {
        priceFormat: { type: 'volume' },
        priceScaleId: 'volume',
      });

      chart.priceScale('volume').applyOptions({
        scaleMargins: { top: 0.8, bottom: 0 },
      });

      window['__tvc_$_chartId'] = {
        chart: chart,
        candle: candleSeries,
        volume: volumeSeries,
      };

      chart.timeScale().fitContent();
    })();
    ''';
    js.context.callMethod('eval', [initJs]);
    _chartReady = true;
    _updateChartData();
  }

  void _updateChartData() {
    if (!_chartReady || widget.candles.isEmpty) return;

    final candleData = StringBuffer('[');
    final volData = StringBuffer('[');
    final now = DateTime.now();

    for (int i = 0; i < widget.candles.length; i++) {
      final c = widget.candles[i];
      final o = (c['o'] as num?)?.toDouble() ?? 0;
      final h = (c['h'] as num?)?.toDouble() ?? 0;
      final l = (c['l'] as num?)?.toDouble() ?? 0;
      final cl = (c['c'] as num?)?.toDouble() ?? 0;
      final v = (c['vol'] as num?)?.toInt() ?? 0;

      // Build timestamp from time string (HH:mm) or use index-based
      int ts;
      final timeStr = c['time']?.toString() ?? '';
      if (timeStr.contains(':') && timeStr.length <= 5) {
        final parts = timeStr.split(':');
        final hour = int.tryParse(parts[0]) ?? 9;
        final min = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        final dt = DateTime(now.year, now.month, now.day, hour, min);
        ts = (dt.millisecondsSinceEpoch / 1000).round();
      } else {
        // For daily/weekly: use date field or sequential days
        final dateStr = c['date']?.toString() ?? '';
        if (dateStr.contains('/')) {
          final dp = dateStr.split('/');
          final day = int.tryParse(dp[0]) ?? 1;
          final month = int.tryParse(dp[1]) ?? now.month;
          final dt = DateTime(now.year, month, day);
          ts = (dt.millisecondsSinceEpoch / 1000).round();
        } else {
          // Fallback: sequential timestamps
          final base = DateTime(now.year, now.month, now.day).subtract(Duration(days: widget.candles.length - i));
          ts = (base.millisecondsSinceEpoch / 1000).round();
        }
      }

      final isUp = cl >= o;
      final volColor = isUp ? 'rgba(16,185,129,0.35)' : 'rgba(239,68,68,0.35)';

      if (i > 0) {
        candleData.write(',');
        volData.write(',');
      }
      candleData.write('{time:$ts,open:$o,high:$h,low:$l,close:$cl}');
      volData.write('{time:$ts,value:$v,color:"$volColor"}');
    }
    candleData.write(']');
    volData.write(']');

    final updateJs = '''
    (function() {
      var ref = window['__tvc_$_chartId'];
      if (!ref) return;
      try {
        var cd = $candleData;
        var vd = $volData;
        // Sort by time to avoid LightweightCharts errors
        cd.sort(function(a,b){ return a.time - b.time; });
        vd.sort(function(a,b){ return a.time - b.time; });
        // Deduplicate timestamps
        var seen = {};
        cd = cd.filter(function(x){ if(seen[x.time]) return false; seen[x.time]=1; return true; });
        seen = {};
        vd = vd.filter(function(x){ if(seen[x.time]) return false; seen[x.time]=1; return true; });
        ref.candle.setData(cd);
        ref.volume.setData(vd);
        ref.chart.timeScale().fitContent();
      } catch(e) { console.error('TV Chart update error:', e); }
    })();
    ''';
    js.context.callMethod('eval', [updateJs]);
  }

  @override
  void didUpdateWidget(covariant TradingViewChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candles != widget.candles || oldWidget.ticker != widget.ticker) {
      if (oldWidget.ticker != widget.ticker) {
        // New ticker: destroy old chart and create new
        _destroyChart();
        _chartId = 'tvchart_${widget.ticker}_${DateTime.now().millisecondsSinceEpoch}';
        _viewId = 'tvview_$_chartId';
        _chartReady = false;
        _registerView();
        setState(() {});
      } else {
        _updateChartData();
      }
    }
  }

  void _destroyChart() {
    final destroyJs = '''
    (function() {
      var ref = window['__tvc_$_chartId'];
      if (ref && ref.chart) { ref.chart.remove(); }
      delete window['__tvc_$_chartId'];
    })();
    ''';
    try { js.context.callMethod('eval', [destroyJs]); } catch (_) {}
  }

  @override
  void dispose() {
    _destroyChart();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff0f172a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xff10b981).withOpacity(0.3), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: HtmlElementView(viewType: _viewId),
    );
  }
}
