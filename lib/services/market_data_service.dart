import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Live market data service using Yahoo Finance via local proxy
class MarketDataService {
  // Proxy URL avoids CORS — server.py proxies to Yahoo Finance
  static String get _baseUrl {
    if (kIsWeb) {
      return '/api/yahoo';
    }
    return 'https://query1.finance.yahoo.com/v8/finance';
  }

  /// Fetch chart data (OHLCV candles) for a given ticker
  static Future<Map<String, dynamic>?> fetchChart({
    required String ticker,
    String interval = '5m',
    String range = '1d',
  }) async {
    final symbol = ticker.contains('.') ? ticker : '$ticker.JK';
    final url = '$_baseUrl/chart/$symbol?interval=$interval&range=$range';
    try {
      final resp = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final result = data['chart']?['result']?[0];
        if (result == null) return null;
        return _parseChartResult(result);
      }
    } catch (e) {
      debugPrint('MarketData fetchChart error: $e');
    }
    return null;
  }

  /// Parse Yahoo Finance chart result into clean format
  static Map<String, dynamic> _parseChartResult(Map<String, dynamic> result) {
    final meta = result['meta'] ?? {};
    final timestamps = List<int>.from(result['timestamp'] ?? []);
    final quote = (result['indicators']?['quote'] ?? [{}])[0];

    final List<Map<String, dynamic>> candles = [];
    final opens = List.from(quote['open'] ?? []);
    final highs = List.from(quote['high'] ?? []);
    final lows = List.from(quote['low'] ?? []);
    final closes = List.from(quote['close'] ?? []);
    final volumes = List.from(quote['volume'] ?? []);

    for (int i = 0; i < timestamps.length; i++) {
      if (closes[i] == null) continue;
      final dt = DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000);
      candles.add({
        'time': '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
        'date': '${dt.day}/${dt.month}',
        'o': (opens[i] as num?)?.toDouble() ?? 0,
        'h': (highs[i] as num?)?.toDouble() ?? 0,
        'l': (lows[i] as num?)?.toDouble() ?? 0,
        'c': (closes[i] as num?)?.toDouble() ?? 0,
        'vol': (volumes[i] as num?)?.toInt() ?? 0,
      });
    }

    return {
      'symbol': meta['symbol'] ?? '',
      'price': (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0,
      'prevClose': (meta['chartPreviousClose'] as num?)?.toDouble() ?? (meta['previousClose'] as num?)?.toDouble() ?? 0,
      'currency': meta['currency'] ?? 'IDR',
      'exchangeTimezoneName': meta['exchangeTimezoneName'] ?? '',
      'candles': candles,
    };
  }

  /// Fetch quotes for multiple tickers at once
  static Future<List<Map<String, dynamic>>> fetchMultiQuotes(List<String> tickers) async {
    final List<Map<String, dynamic>> results = [];
    // Fetch in parallel
    final futures = tickers.map((t) => fetchChart(ticker: t, interval: '1d', range: '5d'));
    final responses = await Future.wait(futures);
    for (int i = 0; i < tickers.length; i++) {
      final data = responses[i];
      if (data != null) {
        results.add({
          'ticker': tickers[i],
          'name': _stockNames[tickers[i]] ?? tickers[i],
          'sector': _stockSectors[tickers[i]] ?? '',
          'price': data['price'],
          'prevClose': data['prevClose'],
          'candles': data['candles'],
        });
      }
    }
    return results;
  }

  /// Map of ticker → full company name
  static const Map<String, String> _stockNames = {
    'BBCA': 'Bank Central Asia Tbk',
    'BBRI': 'Bank Rakyat Indonesia Tbk',
    'BMRI': 'Bank Mandiri Tbk',
    'TLKM': 'Telkom Indonesia Tbk',
    'ASII': 'Astra International Tbk',
    'GOTO': 'GoTo Gojek Tokopedia Tbk',
    'AMMN': 'Amman Mineral Internasional Tbk',
    'ICBP': 'Indofood CBP Sukses Makmur Tbk',
    'UNVR': 'Unilever Indonesia Tbk',
    'BRIS': 'Bank Syariah Indonesia Tbk',
    'ADRO': 'Adaro Energy Indonesia Tbk',
    'ANTM': 'Aneka Tambang Tbk',
    'INDF': 'Indofood Sukses Makmur Tbk',
    'KLBF': 'Kalbe Farma Tbk',
    'EMTK': 'Elang Mahkota Teknologi Tbk',
  };

  static const Map<String, String> _stockSectors = {
    'BBCA': 'Perbankan', 'BBRI': 'Perbankan', 'BMRI': 'Perbankan',
    'TLKM': 'Telko', 'ASII': 'Otomotif', 'GOTO': 'Teknologi',
    'AMMN': 'Tambang', 'ICBP': 'Konsumer', 'UNVR': 'Konsumer',
    'BRIS': 'Perbankan', 'ADRO': 'Tambang', 'ANTM': 'Tambang',
    'INDF': 'Konsumer', 'KLBF': 'Kesehatan', 'EMTK': 'Teknologi',
  };

  /// Default watchlist tickers
  static const List<String> defaultTickers = [
    'BBCA', 'BBRI', 'BMRI', 'TLKM', 'ASII',
    'GOTO', 'AMMN', 'ICBP', 'UNVR', 'BRIS',
    'ADRO', 'ANTM', 'INDF', 'KLBF', 'EMTK',
  ];

  /// Interval/range mapping for timeframe selector (rich, dense candles)
  static Map<String, Map<String, String>> get timeframeMap => {
    '1D': {'interval': '2m', 'range': '1d'},
    '1W': {'interval': '15m', 'range': '5d'},
    '1M': {'interval': '30m', 'range': '1mo'},
    '3M': {'interval': '1d', 'range': '6mo'},
    '1Y': {'interval': '1d', 'range': '1y'},
  };
}
