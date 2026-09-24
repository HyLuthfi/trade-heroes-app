import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../services/market_data_service.dart';
import '../l10n/app_translations.dart';
import '../services/live_voice_service.dart';
import '../state/app_state.dart';
import '../widgets/tradingview_chart.dart';
import '../widgets/live_voice_modal.dart';
import '../utils/browser_helper.dart';

class MarketView extends StatefulWidget {
  const MarketView({Key? key}) : super(key: key);

  @override
  State<MarketView> createState() => _MarketViewState();
}

class _MarketViewState extends State<MarketView> with SingleTickerProviderStateMixin {
  int _selectedStockIdx = 0;

  String _t(AppState appState, String key, String fallbackId, String fallbackEn, {Map<String, String> params = const {}}) {
    final lang = appState.language.toLowerCase().startsWith('en') ? 'en' : 'id';
    final translated = AppTranslations.text(lang, key, params: params);
    if (translated == key) {
      var text = lang == 'en' ? fallbackEn : fallbackId;
      for (final entry in params.entries) {
        text = text.replaceAll('{${entry.key}}', entry.value);
      }
      return text;
    }
    return translated;
  }

  String _tr(String key, String fallbackId, String fallbackEn, {Map<String, String> params = const {}}) {
    final appState = Provider.of<AppState>(context, listen: false);
    return _t(appState, key, fallbackId, fallbackEn, params: params);
  }

  String _getSectorLabel(String sector) {
    switch (sector) {
      case 'Semua':
        return _tr('market.sector_all', 'Semua', 'All');
      case 'Perbankan':
        return _tr('market.sector_banking', 'Perbankan', 'Banking');
      case 'Telko':
        return _tr('market.sector_telecom', 'Telko', 'Telecom');
      case 'Teknologi':
        return _tr('market.sector_technology', 'Teknologi', 'Technology');
      case 'Otomotif':
        return _tr('market.sector_automotive', 'Otomotif', 'Automotive');
      case 'Tambang':
        return _tr('market.sector_mining', 'Tambang', 'Mining');
      case 'Konsumer':
        return _tr('market.sector_consumer', 'Konsumer', 'Consumer');
      default:
        return sector;
    }
  }
  String _selectedTimeframe = "1D";
  String _selectedSector = "Semua";
  int _selectedTabIdx = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Real Market Stocks Database with Generated 30+ Dense Historical Candles
  final List<Map<String, dynamic>> _allStocks = [];

  // AI Stock Analyst Chatbot State
  final List<Map<String, dynamic>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _isAiResponding = false;
  String? _lastChatTicker;
  String? _currentlySpeakingText;

  // Live Market News State
  List<Map<String, dynamic>> _liveNews = [];
  bool _isLoadingNews = false;
  String _selectedNewsCategory = "Semua";
  String? _loadedNewsTicker;

  // Dynamic Search State
  bool _isSearchingNewStock = false;

  Timer? _realDataRefreshTimer;
  bool _isLoadingRealData = false;
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _initStockDatabase();
    _fetchRealMarketData();

    // Refresh data real-time setiap 30 detik
    _realDataRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchRealMarketData(silent: true);
    });

  }

  Future<void> _fetchRealMarketData({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() => _isLoadingRealData = true);
    }

    try {
      final activeStock = _filteredStocks.isNotEmpty && _selectedStockIdx < _filteredStocks.length
          ? _filteredStocks[_selectedStockIdx]
          : (_allStocks.isNotEmpty ? _allStocks[0] : null);

      if (activeStock != null) {
        final tfConfig = MarketDataService.timeframeMap[_selectedTimeframe] ?? {'interval': '5m', 'range': '1d'};
        final chartData = await MarketDataService.fetchChart(
          ticker: activeStock['ticker'],
          interval: tfConfig['interval']!,
          range: tfConfig['range']!,
        );

        if (chartData != null && mounted) {
          setState(() {
            final candles = List<Map<String, dynamic>>.from(chartData['candles']);
            if (candles.isNotEmpty) {
              // Update timeframe map
              final Map<String, dynamic> tfMap = Map<String, dynamic>.from(activeStock['timeframesMap'] ?? {});
              tfMap[_selectedTimeframe] = candles;
              activeStock['timeframesMap'] = tfMap;
              activeStock['candles'] = candles;

              // Update price from latest candle / meta
              final realPrice = chartData['price'] > 0 ? (chartData['price'] as num).toDouble() : (candles.last['c'] as num).toDouble();
              activeStock['price'] = realPrice;

              final prevClose = chartData['prevClose'] > 0 ? (chartData['prevClose'] as num).toDouble() : (candles.first['o'] as num).toDouble();
              final change = realPrice - prevClose;
              final changePct = prevClose > 0 ? (change / prevClose) * 100 : 0.0;

              activeStock['change'] = change;
              activeStock['changePct'] = double.parse(changePct.toStringAsFixed(2));

              final double highVal = candles.map((c) => (c['h'] as num).toDouble()).reduce(max);
              final double lowVal = candles.map((c) => (c['l'] as num).toDouble()).reduce(min);
              final double openVal = (candles.first['o'] as num).toDouble();
              activeStock['open'] = openVal;
              activeStock['high'] = highVal;
              activeStock['low'] = lowVal;
            }
          });
        }
      }

      // Update background watchlist prices for top stocks
      final topTickers = _allStocks.take(8).map((s) => s['ticker'].toString()).toList();
      for (final ticker in topTickers) {
        if (!mounted) break;
        if (activeStock != null && ticker == activeStock['ticker']) continue; // already fetched
        final data = await MarketDataService.fetchChart(ticker: ticker, interval: '1d', range: '2d');
        if (data != null && mounted) {
          final target = _allStocks.firstWhere((s) => s['ticker'] == ticker, orElse: () => {});
          if (target.isNotEmpty) {
            setState(() {
              final realP = data['price'] > 0 ? (data['price'] as num).toDouble() : (target['price'] as num).toDouble();
              target['price'] = realP;
              final prevC = data['prevClose'] > 0 ? (data['prevClose'] as num).toDouble() : realP;
              final chg = realP - prevC;
              target['change'] = chg;
              target['changePct'] = prevC > 0 ? double.parse(((chg / prevC) * 100).toStringAsFixed(2)) : 0.0;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching real market data: $e");
    } finally {
      if (mounted && !silent) {
        setState(() => _isLoadingRealData = false);
      }
    }
  }

  void _initStockDatabase() {
    final rawData = [
      {'ticker': 'BBCA', 'name': 'Bank Central Asia Tbk', 'sector': 'Perbankan', 'basePrice': 10250.0, 'volStr': '854.2K', 'valStr': 'Rp 872.5 M', 'mcap': 'Rp 1.263,4 T', 'per': 24.8, 'pbv': 4.85, 'foreign': '+Rp 142,8 M'},
      {'ticker': 'BBRI', 'name': 'Bank Rakyat Indonesia Tbk', 'sector': 'Perbankan', 'basePrice': 5450.0, 'volStr': '1.24M', 'valStr': 'Rp 676.2 M', 'mcap': 'Rp 825,9 T', 'per': 14.2, 'pbv': 2.65, 'foreign': '+Rp 88,4 M'},
      {'ticker': 'TLKM', 'name': 'Telkom Indonesia Tbk', 'sector': 'Telko', 'basePrice': 3820.0, 'volStr': '451.8K', 'valStr': 'Rp 172.6 M', 'mcap': 'Rp 378,4 T', 'per': 15.6, 'pbv': 2.80, 'foreign': '-Rp 24,5 M'},
      {'ticker': 'ASII', 'name': 'Astra International Tbk', 'sector': 'Otomotif', 'basePrice': 5175.0, 'volStr': '328.4K', 'valStr': 'Rp 169.8 M', 'mcap': 'Rp 209,5 T', 'per': 6.8, 'pbv': 1.05, 'foreign': '+Rp 18,2 M'},
      {'ticker': 'GOTO', 'name': 'GoTo Gojek Tokopedia Tbk', 'sector': 'Teknologi', 'basePrice': 68.0, 'volStr': '12.4M', 'valStr': 'Rp 843.2 M', 'mcap': 'Rp 81,6 T', 'per': -12.4, 'pbv': 0.72, 'foreign': '+Rp 31,6 M'},
      {'ticker': 'AMMN', 'name': 'Amman Mineral Internasional Tbk', 'sector': 'Tambang', 'basePrice': 11450.0, 'volStr': '650.4K', 'valStr': 'Rp 742.1 M', 'mcap': 'Rp 830,2 T', 'per': 38.5, 'pbv': 8.12, 'foreign': '+Rp 210,5 M'},
      {'ticker': 'ICBP', 'name': 'Indofood CBP Sukses Makmur Tbk', 'sector': 'Konsumer', 'basePrice': 11200.0, 'volStr': '210.5K', 'valStr': 'Rp 235.8 M', 'mcap': 'Rp 130,6 T', 'per': 16.4, 'pbv': 3.12, 'foreign': '+Rp 45,2 M'},
      {'ticker': 'UNVR', 'name': 'Unilever Indonesia Tbk', 'sector': 'Konsumer', 'basePrice': 2450.0, 'volStr': '540.1K', 'valStr': 'Rp 132.4 M', 'mcap': 'Rp 93,5 T', 'per': 22.1, 'pbv': 14.8, 'foreign': '-Rp 12,8 M'},
      {'ticker': 'BMRI', 'name': 'Bank Mandiri Tbk', 'sector': 'Perbankan', 'basePrice': 5925.0, 'volStr': '1.02M', 'valStr': 'Rp 604.1 M', 'mcap': 'Rp 552,8 T', 'per': 10.2, 'pbv': 2.18, 'foreign': '+Rp 65,3 M'},
      {'ticker': 'MDKA', 'name': 'Merdeka Copper Gold Tbk', 'sector': 'Tambang', 'basePrice': 2380.0, 'volStr': '420.3K', 'valStr': 'Rp 100.1 M', 'mcap': 'Rp 56,4 T', 'per': 28.5, 'pbv': 3.45, 'foreign': '+Rp 22,1 M'},
      {'ticker': 'ANTM', 'name': 'Aneka Tambang Tbk', 'sector': 'Tambang', 'basePrice': 1485.0, 'volStr': '1.8M', 'valStr': 'Rp 267.3 M', 'mcap': 'Rp 35,6 T', 'per': 8.9, 'pbv': 1.62, 'foreign': '-Rp 8,4 M'},
      {'ticker': 'ADRO', 'name': 'Adaro Energy Indonesia Tbk', 'sector': 'Tambang', 'basePrice': 2550.0, 'volStr': '890.6K', 'valStr': 'Rp 227.0 M', 'mcap': 'Rp 79,8 T', 'per': 5.2, 'pbv': 1.15, 'foreign': '+Rp 38,7 M'},
      {'ticker': 'BREN', 'name': 'Barito Renewables Energy Tbk', 'sector': 'Energi', 'basePrice': 6850.0, 'volStr': '320.1K', 'valStr': 'Rp 219.3 M', 'mcap': 'Rp 458,2 T', 'per': 95.0, 'pbv': 18.5, 'foreign': '+Rp 52,4 M'},
      {'ticker': 'INDF', 'name': 'Indofood Sukses Makmur Tbk', 'sector': 'Konsumer', 'basePrice': 6575.0, 'volStr': '180.2K', 'valStr': 'Rp 118.5 M', 'mcap': 'Rp 57,8 T', 'per': 7.5, 'pbv': 1.08, 'foreign': '+Rp 10,2 M'},
      {'ticker': 'CPIN', 'name': 'Charoen Pokphand Indonesia Tbk', 'sector': 'Konsumer', 'basePrice': 4850.0, 'volStr': '245.8K', 'valStr': 'Rp 119.3 M', 'mcap': 'Rp 79,4 T', 'per': 18.2, 'pbv': 4.35, 'foreign': '-Rp 5,6 M'},
      {'ticker': 'ACES', 'name': 'Ace Hardware Indonesia Tbk', 'sector': 'Ritel', 'basePrice': 720.0, 'volStr': '1.5M', 'valStr': 'Rp 108.0 M', 'mcap': 'Rp 12,3 T', 'per': 19.8, 'pbv': 3.05, 'foreign': '-Rp 2,1 M'},
      {'ticker': 'PANI', 'name': 'Pantai Indah Kapuk Dua Tbk', 'sector': 'Properti', 'basePrice': 17800.0, 'volStr': '120.5K', 'valStr': 'Rp 214.5 M', 'mcap': 'Rp 327,5 T', 'per': 120.0, 'pbv': 25.8, 'foreign': '+Rp 95,3 M'},
      {'ticker': 'EMTK', 'name': 'Elang Mahkota Teknologi Tbk', 'sector': 'Teknologi', 'basePrice': 430.0, 'volStr': '3.2M', 'valStr': 'Rp 137.6 M', 'mcap': 'Rp 25,3 T', 'per': -5.2, 'pbv': 0.55, 'foreign': '+Rp 4,8 M'},
    ];

    for (var item in rawData) {
      final double baseP = item['basePrice'] as double;

      // Generate candles per timeframe
      List<Map<String, dynamic>> generateCandleSet(String tf) {
        final List<Map<String, dynamic>> res = [];
        double currP = baseP * (tf == '1Y' ? 0.78 : (tf == '3M' ? 0.88 : 0.94));
        int hour = 9;
        int minute = 30;
        int day = 1;

        final monthNames = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"];

        for (int i = 0; i < 32; i++) {
          final factor = tf == '1Y' ? 0.035 : (tf == '3M' ? 0.025 : 0.015);
          final change = (_rnd.nextDouble() - 0.46) * (baseP * factor);
          final openP = currP;
          final closeP = openP + change;
          final highP = max(openP, closeP) + (_rnd.nextDouble() * baseP * (factor * 0.5));
          final lowP = min(openP, closeP) - (_rnd.nextDouble() * baseP * (factor * 0.5));
          final vol = _rnd.nextInt(90000) + 20000;

          String timeStr = "";
          if (tf == '1D') {
            timeStr = "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
            minute += 10;
            if (minute >= 60) {
              minute = 0;
              hour++;
            }
          } else if (tf == '1W') {
            timeStr = "H-$i";
          } else if (tf == '1M') {
            timeStr = "${day}Agt";
            day += 2;
          } else if (tf == '3M') {
            timeStr = "${day}Jul";
            day += 3;
          } else {
            timeStr = monthNames[i % 12];
          }

          res.add({
            'o': double.parse(openP.toStringAsFixed(1)),
            'c': double.parse(closeP.toStringAsFixed(1)),
            'h': double.parse(highP.toStringAsFixed(1)),
            'l': double.parse(lowP.toStringAsFixed(1)),
            'vol': vol,
            'time': timeStr,
          });

          currP = closeP;
        }
        return res;
      }

      final Map<String, List<Map<String, dynamic>>> timeframesMap = {
        '1D': generateCandleSet('1D'),
        '1W': generateCandleSet('1W'),
        '1M': generateCandleSet('1M'),
        '3M': generateCandleSet('3M'),
        '1Y': generateCandleSet('1Y'),
      };

      final candles = timeframesMap['1D']!;
      final firstC = candles.first['o'] as double;
      final lastC = candles.last['c'] as double;
      final diff = lastC - firstC;
      final diffPct = (diff / firstC) * 100;

      _allStocks.add({
        'ticker': item['ticker'],
        'name': item['name'],
        'sector': item['sector'],
        'price': lastC,
        'change': diff,
        'changePct': double.parse(diffPct.toStringAsFixed(2)),
        'open': firstC,
        'high': candles.map((c) => c['h'] as double).reduce(max),
        'low': candles.map((c) => c['l'] as double).reduce(min),
        'prevClose': firstC,
        'volume': item['volStr'],
        'timeframesMap': timeframesMap,
        'value': item['valStr'],
        'marketCap': item['mcap'],
        'per': item['per'],
        'pbv': item['pbv'],
        'foreignNet': item['foreign'],
        'candles': candles,
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    _realDataRefreshTimer?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredStocks {
    return _allStocks.where((st) {
      final matchesQuery = st['ticker'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          st['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSector = _selectedSector == "Semua" || st['sector'] == _selectedSector;
      return matchesQuery && matchesSector;
    }).toList();
  }

  bool get _isSearchQueryAValidTicker {
    final q = _searchQuery.trim().toUpperCase();
    return q.length >= 4 && q.length <= 5 && RegExp(r'^[A-Z]{4,5}$').hasMatch(q);
  }

  bool get _isSearchedTickerAlreadyInList {
    final q = _searchQuery.trim().toUpperCase();
    return _allStocks.any((s) => s['ticker'].toString().toUpperCase() == q);
  }

  Future<void> _addDynamicStock(String ticker) async {
    final cleanTicker = ticker.trim().toUpperCase();
    if (_allStocks.any((s) => s['ticker'] == cleanTicker)) {
      // Already exists, just select it
      final idx = _allStocks.indexWhere((s) => s['ticker'] == cleanTicker);
      if (idx >= 0) {
        setState(() {
          _selectedStockIdx = idx;
          _searchController.clear();
          _searchQuery = "";
          _selectedSector = "Semua";
        });
      }
      return;
    }

    setState(() => _isSearchingNewStock = true);

    try {
      final data = await MarketDataService.fetchChart(
        ticker: cleanTicker,
        interval: '1d',
        range: '5d',
      );

      if (data != null && mounted) {
        final realPrice = data['price'] > 0 ? (data['price'] as num).toDouble() : 0.0;
        if (realPrice <= 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Ticker $cleanTicker tidak ditemukan di BEI."),
                backgroundColor: const Color(0xffef4444),
              ),
            );
          }
          return;
        }

        final prevClose = data['prevClose'] > 0 ? (data['prevClose'] as num).toDouble() : realPrice;
        final change = realPrice - prevClose;
        final changePct = prevClose > 0 ? (change / prevClose) * 100 : 0.0;
        final candles = List<Map<String, dynamic>>.from(data['candles'] ?? []);

        final newStock = {
          'ticker': cleanTicker,
          'name': '$cleanTicker • IDX',
          'sector': 'Lainnya',
          'price': realPrice,
          'change': change,
          'changePct': double.parse(changePct.toStringAsFixed(2)),
          'open': realPrice,
          'high': realPrice,
          'low': realPrice,
          'prevClose': prevClose,
          'volume': '-',
          'timeframesMap': {'1D': candles},
          'value': '-',
          'marketCap': '-',
          'turnover': '-',
          'mcap': '-',
          'per': 0.0,
          'pbv': 0.0,
          'foreignNet': '-',
          'candles': candles,
          'isDynamic': true,
        };

        setState(() {
          _allStocks.insert(0, newStock);
          _selectedStockIdx = 0;
          _searchController.clear();
          _searchQuery = "";
          _selectedSector = "Semua";
        });

        AudioService.playConfirm();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$cleanTicker berhasil ditambahkan ke watchlist!"),
              backgroundColor: const Color(0xff059669),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal mengambil data $cleanTicker dari BEI."),
              backgroundColor: const Color(0xffef4444),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error adding dynamic stock $cleanTicker: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menambahkan $cleanTicker: $e"),
            backgroundColor: const Color(0xffef4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearchingNewStock = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final filtered = _filteredStocks;
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      if (_allStocks.isEmpty) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xff0b0f19) : theme.scaffoldBackgroundColor,
          body: const Center(
            child: CircularProgressIndicator(color: Color(0xff10b981)),
          ),
        );
      }

      final activeStock = filtered.isNotEmpty
          ? filtered[_selectedStockIdx.clamp(0, filtered.length - 1)]
          : _allStocks.first;
      final bool isBullish = ((activeStock['changePct'] as num?)?.toDouble() ?? 0.0) >= 0;
      final Color mainColor = isBullish ? const Color(0xff10b981) : const Color(0xffef4444);

      return Scaffold(
        backgroundColor: isDark ? const Color(0xff0b0f19) : theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // 1. Interactive Real Search Bar & Sector Filter Chips
              _buildSearchBarAndFilters(),

              // 2. Stock Watchlist Selector Carousel
              _buildStockWatchlistBar(filtered),

              // 3. Pro Terminal Main Content Tabs
              _buildTerminalTabSelector(),

              // 4. Tab Body Content
              Expanded(
                child: IndexedStack(
                  index: _selectedTabIdx.clamp(0, 2),
                  children: [
                    _buildTradingViewUltraChartTab(activeStock, mainColor),
                    _buildAiChatbotTab(activeStock),
                    _buildNewsTab(activeStock),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint("Error in MarketView.build: $e\n$stack");
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return Scaffold(
        backgroundColor: isDark ? const Color(0xff0b0f19) : theme.scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh_rounded, color: Color(0xff10b981), size: 48),
                const SizedBox(height: 12),
                const Text(
                  "Memuat Data Pasar...",
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "$e",
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xff94a3b8)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff10b981)),
                  onPressed: () {
                    setState(() {
                      _initStockDatabase();
                      _fetchRealMarketData();
                    });
                  },
                  child: const Text("Muat Ulang"),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // 2. Search Bar & Filter Chips
  Widget _buildSearchBarAndFilters() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final sectors = ["Semua", "Perbankan", "Telko", "Teknologi", "Otomotif", "Tambang", "Konsumer", "Energi", "Properti", "Ritel", "Lainnya"];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: BoxDecoration(
        color: isDark ? theme.scaffoldBackgroundColor : colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(isDark ? 0.12 : 0.15))),
      ),
      child: Column(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface : const Color(0xfff1f5f9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(isDark ? 0.15 : 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xff10b981), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _selectedStockIdx = 0;
                      });
                    },
                    onSubmitted: (val) {
                      final q = val.trim().toUpperCase();
                      if (q.length >= 4 && RegExp(r'^[A-Z]{4,5}$').hasMatch(q)) {
                        _addDynamicStock(q);
                      }
                    },
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: _tr('market.search_hint', 'Cari Saham BEI (e.g. BBCA, BBRI, GOTO)...', 'Search IDX Stocks (e.g. BBCA, BBRI, GOTO)...'),
                      hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 12, color: colorScheme.onSurfaceVariant.withOpacity(0.8)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = "";
                      });
                    },
                    child: Icon(Icons.close_rounded, color: colorScheme.onSurfaceVariant, size: 18),
                  ),
              ],
            ),
          ),

          // Dynamic "Tambahkan ke Watchlist" button when ticker not found
          if (_searchQuery.isNotEmpty && _isSearchQueryAValidTicker && !_isSearchedTickerAlreadyInList && _filteredStocks.isEmpty)
            GestureDetector(
              onTap: _isSearchingNewStock ? null : () => _addDynamicStock(_searchQuery.trim().toUpperCase()),
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xff10b981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xff10b981).withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSearchingNewStock) ...[
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(color: Color(0xff10b981), strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Mencari di Bursa Efek Indonesia...",
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xff34d399)),
                      ),
                    ] else ...[
                      const Icon(Icons.add_circle_outline_rounded, color: Color(0xff34d399), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Tambahkan ${_searchQuery.trim().toUpperCase()} ke Watchlist",
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff34d399),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),

          SizedBox(
            height: 28,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sectors.length,
              itemBuilder: (context, idx) {
                final sec = sectors[idx];
                final isSel = _selectedSector == sec;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSector = sec;
                      _selectedStockIdx = 0;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xff059669) : (isDark ? colorScheme.surface : const Color(0xfff1f5f9)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSel ? const Color(0xff10b981) : colorScheme.outline.withOpacity(isDark ? 0.12 : 0.2),
                      ),
                    ),
                    child: Text(
                      _getSectorLabel(sec),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: isSel ? Colors.white : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 3. Watchlist Bar
  Widget _buildStockWatchlistBar(List<Map<String, dynamic>> filteredList) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (filteredList.isEmpty) {
      return Container(
        height: 44,
        color: isDark ? theme.scaffoldBackgroundColor : colorScheme.surface,
        alignment: Alignment.center,
        child: Text(
          _tr('market.watchlist_empty', 'Tidak ada saham yang cocok dengan pencarian', 'No stocks match your search'),
          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? theme.scaffoldBackgroundColor : colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(isDark ? 0.12 : 0.15))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: filteredList.length,
        itemBuilder: (context, idx) {
          final st = filteredList[idx];
          final isSelected = idx == _selectedStockIdx;
          final isUp = st['changePct'] >= 0;

          final upColor = isDark ? const Color(0xff34d399) : const Color(0xff059669);
          final downColor = isDark ? const Color(0xfff87171) : const Color(0xffdc2626);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedStockIdx = idx;
              });
              _fetchRealMarketData();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xff059669) : (isDark ? colorScheme.surface : const Color(0xfff1f5f9)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color(0xff10b981) : colorScheme.outline.withOpacity(isDark ? 0.12 : 0.2),
                  width: isSelected ? 1.4 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    st['ticker'],
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Rp ${st['price'].toInt()}",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${isUp ? '+' : ''}${st['changePct']}%",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? (isUp ? const Color(0xffa7f3d0) : const Color(0xfffca5a5))
                          : (isUp ? upColor : downColor),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 4. Pro Terminal Tab Bar with Vector Material Icons
  Widget _buildTerminalTabSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final tabs = [
      {'label': _tr('market.tab_chart', 'Grafik', 'Chart'), 'icon': Icons.candlestick_chart_rounded},
      {'label': _tr('market.tab_ai_chat', 'Tanya AI', 'Ask AI'), 'icon': Icons.smart_toy_rounded},
      {'label': _tr('market.tab_news', 'Berita', 'News'), 'icon': Icons.newspaper_rounded},
    ];

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? theme.scaffoldBackgroundColor : colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(isDark ? 0.12 : 0.15))),
      ),
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSelected = _selectedTabIdx == idx;
          final item = tabs[idx];

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIdx = idx;
                });
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? const Color(0xff10b981) : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 14,
                          color: isSelected ? const Color(0xff10b981) : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                            color: isSelected ? const Color(0xff10b981) : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // TAB 1: TRADINGVIEW ULTRA CHART ENGINE
  Widget _buildTradingViewUltraChartTab(Map<String, dynamic> stock, Color mainColor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bool isUp = ((stock['changePct'] as num?)?.toDouble() ?? 0.0) >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stock Detail Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        stock['ticker']?.toString() ?? '',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getSectorLabel(stock['sector']?.toString() ?? ''),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xff064e3b) : const Color(0xffd1fae5),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xff10b981).withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Color(0xff10b981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isLoadingRealData ? _tr('market.refreshing', 'REFRESHING...', 'REFRESHING...') : _tr('market.live_badge', 'LIVE BEI', 'LIVE IDX'),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xff10b981) : const Color(0xff059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                    Text(
                      stock['name']?.toString() ?? '',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Rp ${(stock['price'] as num?)?.toStringAsFixed(0) ?? '0'}",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: mainColor,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "${isUp ? '+' : ''}${(stock['change'] as num?)?.toInt() ?? 0} (${isUp ? '+' : ''}${stock['changePct'] ?? 0}%)",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: mainColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Financial Metrics Grid
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff111827) : colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : colorScheme.outline.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCell(_tr('market.metric_open', 'Open', 'Open'), "Rp ${(stock['open'] as num?)?.toInt() ?? 0}"),
                _buildMetricCell(_tr('market.metric_high', 'High', 'High'), "Rp ${(stock['high'] as num?)?.toInt() ?? 0}"),
                _buildMetricCell(_tr('market.metric_low', 'Low', 'Low'), "Rp ${(stock['low'] as num?)?.toInt() ?? 0}"),
                _buildMetricCell(_tr('market.metric_value', 'Val (Rp)', 'Val (IDR)'), stock['value']?.toString() ?? "-"),
                _buildMetricCell(_tr('market.metric_foreign', 'Foreign', 'Foreign'), stock['foreignNet']?.toString() ?? "-"),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // TRADINGVIEW OFFICIAL ADVANCED REAL-TIME CHART
          SizedBox(
            height: 520,
            child: TradingViewChart(
              key: ValueKey('${stock['ticker']}_$isDark'),
              ticker: stock['ticker']?.toString() ?? 'BBCA',
              timeframe: '1D',
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCell(String label, String val) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9.5,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // TAB 2: AI STOCK ANALYST CHATBOT
  void _initChatForStock(Map<String, dynamic> stock) {
    final ticker = stock['ticker']?.toString() ?? 'BBCA';
    if (_lastChatTicker == ticker && _chatMessages.isNotEmpty) return;
    _lastChatTicker = ticker;
    _chatMessages.clear();
    final p = stock['price'] != null ? "Rp ${(stock['price'] as num).toInt()}" : "-";
    final chg = stock['changePct'] != null ? "${(stock['changePct'] as num) >= 0 ? '+' : ''}${stock['changePct']}%" : "";
    final isEn = Provider.of<AppState>(context, listen: false).language.startsWith('en');
    _chatMessages.add({
      'isUser': false,
      'time': _formatCurrentTime(),
      'text': isEn
          ? "Hello! I'm **SAI Tech AI Chatbot** 🤖.\n\nYou are monitoring **$ticker** (${stock['name'] ?? ''}) at **$p** ($chg).\n\nWhat would you like to ask about technical analysis, valuation ratios, or trading strategies for this stock?"
          : "Halo! Saya **SAI Tech AI Chatbot** 🤖.\n\nKamu sedang memantau saham **$ticker** (${stock['name'] ?? ''}) di harga **$p** ($chg).\n\nAda yang ingin kamu tanyakan mengenai analisa teknikal, valuasi fundamental, atau strategi trading untuk saham ini?",
    });
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _sendChatMessage(String question, Map<String, dynamic> stock) async {
    final q = question.trim();
    if (q.isEmpty || _isAiResponding) return;

    AudioService.playClick();
    _chatController.clear();

    setState(() {
      _chatMessages.add({
        'isUser': true,
        'time': _formatCurrentTime(),
        'text': q,
      });
      _isAiResponding = true;
    });

    _scrollToChatBottom();

    // Prepare multi-turn conversational history
    final history = _chatMessages
        .take(_chatMessages.length - 1)
        .map((m) => {
              'role': m['isUser'] == true ? 'user' : 'assistant',
              'content': m['text']?.toString() ?? '',
            })
        .toList();
    if (history.length > 8) {
      history.removeRange(0, history.length - 8);
    }

    String answer = '';
    try {
      final res = await http.post(
        Uri.parse('/api/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': q,
          'ticker': stock['ticker']?.toString() ?? 'BBCA',
          'history': history,
          'stock': {
            'name': stock['name'] ?? '',
            'price': stock['price'],
            'change': stock['change'],
            'changePct': stock['changePct'],
            'sector': stock['sector'] ?? 'Umum',
            'per': stock['per'] ?? '15.0',
            'pbv': stock['pbv'] ?? '2.0',
            'mcap': stock['mcap'] ?? '-',
            'foreignNet': stock['foreignNet'] ?? '-',
          },
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['reply'] != null && (data['reply'] as String).trim().isNotEmpty) {
          answer = data['reply'];
        }
      }
    } catch (e) {
      debugPrint("9Router AI chat error: $e, using local fallback");
    }

    // Fallback to local intelligent analysis if 9Router is unreachable
    if (answer.isEmpty) {
      answer = _generateAiAnswer(q, stock);
    }

    if (mounted) {
      setState(() {
        _chatMessages.add({
          'isUser': false,
          'time': _formatCurrentTime(),
          'text': answer,
        });
        _isAiResponding = false;
      });
      _scrollToChatBottom();
    }
  }

  void _scrollToChatBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  Future<void> _playVoiceForMessage(String text) async {
    if (_currentlySpeakingText == text) {
      LiveVoiceService.stopAudio();
      setState(() => _currentlySpeakingText = null);
      return;
    }

    AudioService.playClick();
    LiveVoiceService.stopAudio();
    setState(() => _currentlySpeakingText = text);

    try {
      final res = await http.post(
        Uri.parse('/api/ai/tts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'voice': 'auto'}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final audioUri = (data['audio'] ?? '').toString();
        if (audioUri.isNotEmpty && audioUri.startsWith('data:audio/')) {
          LiveVoiceService.playAudio(
            audioUri,
            onEnded: () {
              if (mounted && _currentlySpeakingText == text) {
                setState(() => _currentlySpeakingText = null);
              }
            },
          );
          return;
        }
      }
    } catch (e) {
      debugPrint("TTS play error: $e");
    }

    if (mounted) setState(() => _currentlySpeakingText = null);
  }

  String _generateAiAnswer(String question, Map<String, dynamic> stock) {
    final qLower = question.toLowerCase();
    final ticker = stock['ticker']?.toString() ?? 'BBCA';
    final name = stock['name']?.toString() ?? '';
    final price = stock['price'] != null ? (stock['price'] as num).toDouble() : 1000.0;
    final pInt = price.toInt();
    final per = stock['per']?.toString() ?? '15.0';
    final pbv = stock['pbv']?.toString() ?? '2.0';
    final sector = stock['sector']?.toString() ?? 'Umum';

    // Support and resistance levels
    final r2 = (price * 1.05).round();
    final r1 = (price * 1.025).round();
    final s1 = (price * 0.975).round();
    final s2 = (price * 0.95).round();

    if (qLower.contains('support') || qLower.contains('resistance') || qLower.contains('snr') || qLower.contains('level')) {
      return "🎯 **Level Kunci Teknikal $ticker:**\n\n"
          "• **Resistance 2 (Target Kuat):** Rp $r2 (+5.0%)\n"
          "• **Resistance 1 (Uji Breakout):** Rp $r1 (+2.5%)\n"
          "• **Harga Saat Ini:** Rp $pInt\n"
          "• **Support 1 (Area Rebound):** Rp $s1 (-2.5%)\n"
          "• **Support 2 (Batas Stop Loss):** Rp $s2 (-5.0%)\n\n"
          "💡 **Saran Aksi:** Jika harga mampu bertahan di atas Rp $s1 dengan volume transaksi yang meningkat, saham ini memiliki peluang teknikal untuk menguji Resistance Rp $r1.";
    }

    if (qLower.contains('valuasi') || qLower.contains('rasio') || qLower.contains('per') || qLower.contains('pbv') || qLower.contains('murah') || qLower.contains('mahal')) {
      return "📊 **Ringkasan Valuasi Fundamental $ticker:**\n\n"
          "• **Sektor:** $sector\n"
          "• **P/E Ratio (PER):** ${per}x\n"
          "• **P/BV Ratio (PBV):** ${pbv}x\n"
          "• **Kapitalisasi Pasar:** ${stock['mcap'] ?? '-'}\n"
          "• **Foreign Flow:** ${stock['foreignNet'] ?? '-'}\n\n"
          "📌 **Catatan Analis:** Di sektor $sector, PER ${per}x mencerminkan ekspektasi pertumbuhan laba yang solid. Sebagai emiten market leader, $ticker kerap diperdagangkan dengan *premium valuation* karena kualitas neraca yang stabil.";
    }

    if (qLower.contains('masuk') || qLower.contains('keluar') || qLower.contains('beli') || qLower.contains('jual') || qLower.contains('strategi') || qLower.contains('target') || qLower.contains('sl')) {
      return "⚡ **Trading Plan & Strategi Eksekusi $ticker:**\n\n"
          "1. **Area Buy / Entry:** Sekitar Rp $s1 - Rp $pInt saat terjadi konfirmasi pantulan.\n"
          "2. **Target Profit (TP 1):** Rp $r1 (+2.5%)\n"
          "3. **Target Profit (TP 2):** Rp $r2 (+5.0%)\n"
          "4. **Stop Loss (SL):** Rp $s2 (disiplin cut loss jika breakdown di bawah support untuk membatasi risiko).\n\n"
          "🛡️ **Money Management:** Gunakan alokasi maksimal 10-15% dari total portofolio untuk satu emiten agar risiko terkontrol.";
    }

    if (qLower.contains('pemula') || qLower.contains('tips') || qLower.contains('nabung') || qLower.contains('dca') || qLower.contains('aman')) {
      return "📚 **Panduan & Tips Pemula untuk Saham $ticker:**\n\n"
          "1. **Karakter Emiten:** $ticker ($name) merupakan saham kategori **Blue Chip (LQ45)** dengan likuiditas tinggi, sehingga relatif lebih aman dan tidak mudah digerakkan oleh spekulan.\n"
          "2. **Metode Akumulasi:** Sangat cocok menggunakan strategi **Dollar Cost Averaging (DCA)** — membeli secara rutin tiap bulan tanpa pusing menebak titik terendah pasar.\n"
          "3. **Dividen Tahunan:** Perusahaan ini konsisten membagikan dividen tunai kepada pemegang saham setiap tahun buku.\n\n"
          "💡 **Langkah Awal:** Cukup beli 1 lot (100 lembar) terlebih dahulu untuk membiasakan diri memantau fluktuasi harga.";
    }

    if (qLower.contains('smc') || qLower.contains('fvg') || qLower.contains('imbalance') || qLower.contains('smart money') || qLower.contains('order block')) {
      return "🏛️ **Smart Money Concepts (SMC) & FVG $ticker:**\n\n"
          "• **Konsep Dasar:** SMC melacak jejak transaksi investor institusi besar melalui area ketidakseimbangan likuiditas (*Fair Value Gap / FVG*).\n"
          "• **Zona Imbalance (FVG):** Celah harga yang ditinggalkan saat ada pembelian/penjualan agresif satu arah. Celah ini cenderung menjadi magnet yang akan dikunjungi kembali oleh harga.\n"
          "• **Order Block (Demand/Supply):** Area harga di mana institusi menumpuk order akumulasi sebelum terjadi kenaikan tajam.\n\n"
          "💡 **Tips Pemula:** Jangan buru-buru membeli saat harga melesat meninggalkan FVG. Tunggu harga melakukan *pullback* (koreksi sehat) kembali ke area bantalan support untuk rasio *risk-to-reward* terbaik.";
    }

    if (qLower.contains('zerolag') || qLower.contains('zero-lag') || qLower.contains('momentum') || qLower.contains('jenuh') || qLower.contains('volatilitas')) {
      return "⚡ **Zero-Lag Momentum & Volatilitas $ticker:**\n\n"
          "• **Prinsip Zero-Lag:** Indikator pergerakan harga tanpa keterlambatan (*lag-free*), mengukur apakah dorongan harga didukung oleh volume institusi nyata atau spekulasi sesaat.\n"
          "• **Kondisi Pasar:** Harga saat ini di Rp $pInt bergerak dalam pita volatilitas yang sehat.\n"
          "• **Status Akumulasi:** Momentum menunjukkan fase konsolidasi terarah, menandakan pergerakan harga sedang mengumpulkan tenaga sebelum menentukan arah ekspansi.\n\n"
          "💡 **Strategi Edukatif:** Saat volatilitas sedang kompresi (menyempit), hindari trading agresif. Tunggu konfirmasi penembusan (*breakout*) dengan lonjakan volume.";
    }

    // Default Prospek Analysis
    return "💡 **Analisa Prospek Bisnis & Tren $ticker:**\n\n"
        "• **Model Bisnis:** Sebagai pemain dominan di sektor $sector, $name memiliki *economic moat* yang kuat dan basis pelanggan yang loyal.\n"
        "• **Arus Dana Institusi:** Aktivitas net foreign tercatat ${stock['foreignNet'] ?? '-'}, menandakan minat investor institusi tetap aktif.\n"
        "• **Sentimen Pasar:** Tren harga di Rp $pInt menunjukkan konsolidasi sehat di area support teknikal.\n\n"
        "🎯 **Kesimpulan AI:** Saham ini menarik untuk dijadikan fondasi portofolio jangka menengah-panjang. Silakan manfaatkan koreksi wajar di area Rp $s1 untuk akumulasi bertahap.";
  }

  Widget _buildAiThinkingBubble() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xff10b981).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Color(0xff10b981), size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff1e293b) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xff334155) : const Color(0xffe2e8f0),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xff10b981)),
                ),
                const SizedBox(width: 8),
                Text(
                  _tr(
                    'market.ai_thinking',
                    'AI sedang menganalisis data pasar...',
                    'AI is analyzing market data...',
                  ),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessageItem(Map<String, dynamic> msg) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUser = msg['isUser'] == true;
    final text = msg['text']?.toString() ?? '';
    final time = msg['time']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xff10b981).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xff10b981).withOpacity(0.3)),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Color(0xff10b981), size: 15),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xff064e3b)
                    : (isDark ? const Color(0xff1e293b) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: isUser ? const Radius.circular(14) : const Radius.circular(2),
                  bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(14),
                ),
                border: Border.all(
                  color: isUser
                      ? const Color(0xff10b981).withOpacity(0.4)
                      : (isDark ? const Color(0xff334155) : const Color(0xffe2e8f0)),
                ),
                boxShadow: (isUser || isDark)
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: isUser
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xff0f172a)),
                        height: 1.5,
                      ),
                      strong: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isUser
                            ? const Color(0xffa7f3d0)
                            : (isDark ? const Color(0xff34d399) : const Color(0xff059669)),
                      ),
                      em: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: isUser
                            ? const Color(0xffa7f3d0)
                            : (isDark ? const Color(0xffcbd5e1) : const Color(0xff475569)),
                      ),
                      listBullet: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: isUser
                            ? const Color(0xffa7f3d0)
                            : (isDark ? const Color(0xff10b981) : const Color(0xff059669)),
                      ),
                      h1: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: isUser
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xff0f172a)),
                      ),
                      h2: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: isUser
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xff0f172a)),
                      ),
                      h3: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isUser
                            ? const Color(0xffa7f3d0)
                            : (isDark ? const Color(0xff38bdf8) : const Color(0xff0284c7)),
                      ),
                      code: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11.5,
                        color: isUser
                            ? Colors.white
                            : (isDark ? const Color(0xff38bdf8) : const Color(0xff0284c7)),
                        backgroundColor: isUser
                            ? const Color(0xff047857)
                            : (isDark ? const Color(0xff0f172a) : const Color(0xfff1f5f9)),
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: isUser
                            ? const Color(0xff047857)
                            : (isDark ? const Color(0xff0f172a) : const Color(0xfff1f5f9)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isUser
                              ? const Color(0xff10b981).withOpacity(0.5)
                              : (isDark ? const Color(0xff334155) : const Color(0xffe2e8f0)),
                        ),
                      ),
                      blockquote: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: isUser
                            ? const Color(0xffa7f3d0)
                            : (isDark ? const Color(0xff94a3b8) : const Color(0xff64748b)),
                      ),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: isUser ? const Color(0xff34d399) : const Color(0xff10b981),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9.5,
                          color: isUser
                              ? const Color(0xff6ee7b7)
                              : (isDark ? const Color(0xff64748b) : const Color(0xff94a3b8)),
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            AudioService.playClick();
                            _playVoiceForMessage(text);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _currentlySpeakingText == text
                                  ? const Color(0xff10b981).withOpacity(0.2)
                                  : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xfff1f5f9)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _currentlySpeakingText == text ? Icons.stop_rounded : Icons.volume_up_rounded,
                                  color: _currentlySpeakingText == text
                                      ? const Color(0xff10b981)
                                      : (isDark ? const Color(0xff94a3b8) : const Color(0xff64748b)),
                                  size: 11,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _currentlySpeakingText == text
                                      ? _tr('live_voice.btn_stop', 'Hentikan', 'Stop')
                                      : _tr('live_voice.btn_listen', 'Dengarkan', 'Listen'),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: _currentlySpeakingText == text
                                        ? const Color(0xff10b981)
                                        : (isDark ? const Color(0xff94a3b8) : const Color(0xff64748b)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xff059669).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 15),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiChatbotTab(Map<String, dynamic> stock) {
    _initChatForStock(stock);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final quickChips = [
      _tr('market.chip_prospects', 'Analisa Prospek', 'Prospect Analysis'),
      _tr('market.chip_snr', 'Support & Resistance (SNR)', 'Support & Resistance (SNR)'),
      _tr('market.chip_smc', 'Smart Money (SMC / FVG)', 'Smart Money (SMC / FVG)'),
      _tr('market.chip_momentum', 'Momentum Zero-Lag', 'Zero-Lag Momentum'),
      _tr('market.chip_valuation', 'Valuasi & Rasio', 'Valuation & Ratios'),
      _tr('market.chip_entry_exit', 'Strategi Masuk/Keluar', 'Entry/Exit Strategy'),
      _tr('market.chip_beginner_tips', 'Tips Pemula', 'Beginner Tips'),
    ];

    return Container(
      color: isDark ? const Color(0xff0b0f19) : theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header Info Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff0f172a) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _tr('market.ai_title', 'SAI Tech AI Chatbot', 'SAI Tech AI Chatbot'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xff0f172a),
                    letterSpacing: 0.3,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    AudioService.playClick();
                    LiveVoiceModal.show(
                      context,
                      stock: stock,
                      onConversationEnd: (q, a) {
                        setState(() {
                          _chatMessages.add({
                            'isUser': true,
                            'time': _formatCurrentTime(),
                            'text': q,
                          });
                          _chatMessages.add({
                            'isUser': false,
                            'time': _formatCurrentTime(),
                            'text': a,
                          });
                        });
                        _scrollToChatBottom();
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: const Color(0xff10b981).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xff10b981).withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.graphic_eq_rounded, color: Color(0xff10b981), size: 14),
                        const SizedBox(width: 5),
                        Text(
                          _tr('market.ai_live_voice', 'Live Voice', 'Live Voice'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: isDark ? const Color(0xff34d399) : const Color(0xff059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quick Question Chips Carousel
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: quickChips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final label = quickChips[i];
                return GestureDetector(
                  onTap: () {
                    AudioService.playClick();
                    _sendChatMessage(label, stock);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff1e293b) : const Color(0xfff1f5f9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xff334155) : const Color(0xffcbd5e1),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xffcbd5e1) : const Color(0xff334155),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _chatScrollController,
              padding: const EdgeInsets.all(14),
              itemCount: _chatMessages.length + (_isAiResponding ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _chatMessages.length && _isAiResponding) {
                  return _buildAiThinkingBubble();
                }
                final msg = _chatMessages[index];
                return _buildChatMessageItem(msg);
              },
            ),
          ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff0f172a) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff1e293b) : const Color(0xfff1f5f9),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark ? const Color(0xff334155) : const Color(0xffcbd5e1),
                      ),
                    ),
                    child: TextField(
                      controller: _chatController,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xff0f172a),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (val) => _sendChatMessage(val, stock),
                      decoration: InputDecoration(
                        hintText: _tr(
                          'market.ai_input_hint',
                          'Tanya AI tentang ${stock['ticker']}...',
                          'Ask AI about ${stock['ticker']}...',
                          params: {'ticker': '${stock['ticker']}'},
                        ),
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: isDark ? const Color(0xff64748b) : const Color(0xff94a3b8),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    AudioService.playClick();
                    LiveVoiceModal.show(
                      context,
                      stock: stock,
                      onConversationEnd: (q, a) {
                        setState(() {
                          _chatMessages.add({
                            'isUser': true,
                            'time': _formatCurrentTime(),
                            'text': q,
                          });
                          _chatMessages.add({
                            'isUser': false,
                            'time': _formatCurrentTime(),
                            'text': a,
                          });
                        });
                        _scrollToChatBottom();
                      },
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff1e293b) : const Color(0xfff1f5f9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xff334155) : const Color(0xffcbd5e1),
                      ),
                    ),
                    child: const Icon(Icons.mic_rounded, color: Color(0xff38bdf8), size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    AudioService.playClick();
                    _sendChatMessage(_chatController.text, stock);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff10b981), Color(0xff059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff10b981).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }





  // TAB 3: REAL-TIME MARKET NEWS WITH AI IMPACT ANALYSIS
  Future<void> _fetchRealNews(String ticker, {bool force = false}) async {
    final cleanTicker = ticker.split('_').first.toUpperCase().replaceAll('.JK', '');
    if (!force && _loadedNewsTicker == cleanTicker && _liveNews.isNotEmpty) return;

    if (mounted) setState(() => _isLoadingNews = true);
    try {
      final res = await http.get(Uri.parse('/api/news?ticker=$cleanTicker')).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['articles'] != null && data['articles'] is List) {
          if (mounted) {
            setState(() {
              _liveNews = List<Map<String, dynamic>>.from(data['articles']);
              _loadedNewsTicker = cleanTicker;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching real news: $e");
    } finally {
      if (mounted) setState(() => _isLoadingNews = false);
    }
  }

  void _analyzeNewsImpactWithAi(Map<String, dynamic> newsItem, Map<String, dynamic> stock) {
    AudioService.playClick();
    final cleanTicker = stock['ticker']?.toString() ?? 'BBCA';
    final headline = newsItem['title'] ?? '';
    final source = newsItem['source'] ?? '';

    // Switch to Tanya AI tab (index 1)
    setState(() {
      _selectedTabIdx = 1;
    });

    final prompt = "Analisa dampak berita dari $source berikut ini untuk saham $cleanTicker:\n\n"
        "\"$headline\"\n\n"
        "Tolong jelaskan secara terstruktur:\n"
        "1. Makna berita ini dengan bahasa sederhana yang mudah dipahami pemula.\n"
        "2. Apakah ini katalis positif atau sentimen waspada, dan bagaimana dampaknya ke tren harga & level support/resistance saat ini?\n"
        "3. Saran strategi taktis bagi trader & investor.";

    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) {
        _sendChatMessage(prompt, stock);
      }
    });
  }

  void _openNewsUrl(String url) {
    AudioService.playClick();
    if (url.isNotEmpty) {
      BrowserHelper.openTab(url);
    }
  }

  Widget _buildNewsTab(Map<String, dynamic> stock) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cleanTicker = stock['ticker']?.toString() ?? 'BBCA';
    if (_loadedNewsTicker != cleanTicker && !_isLoadingNews) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchRealNews(cleanTicker);
      });
    }

    final categories = [
      {'key': 'Semua', 'label': _tr('market.news_cat_all', 'Semua', 'All')},
      {'key': 'Dividen & Kinerja', 'label': _tr('market.news_cat_dividend', 'Dividen & Kinerja', 'Dividends & Earnings')},
      {'key': 'Aksi Korporasi', 'label': _tr('market.news_cat_corporate', 'Aksi Korporasi', 'Corporate Actions')},
      {'key': 'Sentimen Pasar', 'label': _tr('market.news_cat_sentiment', 'Sentimen Pasar', 'Market Sentiment')},
      {'key': 'Analisa Pasar', 'label': _tr('market.news_cat_analysis', 'Analisa Pasar', 'Market Analysis')},
    ];
    final filteredNews = _selectedNewsCategory == "Semua"
        ? _liveNews
        : _liveNews.where((n) => n['category'] == _selectedNewsCategory).toList();

    return Container(
      color: isDark ? const Color(0xff0b0f19) : theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Header info strip with real-time status & manual refresh
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff0f172a) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xff10b981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _tr(
                        'market.news_header',
                        'Berita Bursa Terkini • $cleanTicker',
                        'Latest IDX Market News • $cleanTicker',
                        params: {'ticker': cleanTicker},
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xff0f172a),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    AudioService.playClick();
                    _fetchRealNews(cleanTicker, force: true);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff1e293b) : const Color(0xfff1f5f9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? const Color(0xff334155) : const Color(0xffcbd5e1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 12,
                          color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _tr('market.news_refresh', 'Perbarui', 'Refresh'),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category Filter Chips Carousel
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final catItem = categories[i];
                final catKey = catItem['key']!;
                final catLabel = catItem['label']!;
                final isSel = _selectedNewsCategory == catKey;
                return GestureDetector(
                  onTap: () {
                    AudioService.playClick();
                    setState(() => _selectedNewsCategory = catKey);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSel
                          ? (isDark ? const Color(0xff064e3b) : const Color(0xffd1fae5))
                          : (isDark ? const Color(0xff1e293b) : const Color(0xfff1f5f9)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSel
                            ? (isDark ? const Color(0xff10b981) : const Color(0xff059669))
                            : (isDark ? const Color(0xff334155) : const Color(0xffcbd5e1)),
                        width: 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      catLabel,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isSel
                            ? (isDark ? const Color(0xff34d399) : const Color(0xff065f46))
                            : (isDark ? const Color(0xff94a3b8) : const Color(0xff64748b)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // News Article List or Loading / Empty state
          Expanded(
            child: _isLoadingNews && _liveNews.isEmpty
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Color(0xff10b981), strokeWidth: 2.2),
                    ),
                  )
                : filteredNews.isEmpty
                    ? Center(
                        child: Text(
                          _tr(
                            'market.news_empty',
                            'Tidak ada artikel untuk kategori ini.',
                            'No articles found for this category.',
                          ),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: isDark ? const Color(0xff64748b) : const Color(0xff94a3b8),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                        itemCount: filteredNews.length,
                        itemBuilder: (context, idx) {
                          final n = filteredNews[idx];
                          final sent = (n['sentiment'] ?? 'NETRAL').toString();
                          final isPos = sent == 'POSITIF';
                          final isNeg = sent == 'WASPADA';

                          Color sentColor = const Color(0xff94a3b8);
                          Color sentBg = const Color(0xff1e293b);
                          Color sentBorder = const Color(0xff334155);
                          String sentLabel = _tr('market.news_sentiment_neutral', 'NETRAL', 'NEUTRAL');

                          if (isPos) {
                            sentColor = isDark ? const Color(0xff34d399) : const Color(0xff065f46);
                            sentBg = isDark ? const Color(0xff064e3b) : const Color(0xffd1fae5);
                            sentBorder = const Color(0xff059669);
                            sentLabel = _tr('market.news_sentiment_positive', 'POSITIF', 'POSITIVE');
                          } else if (isNeg) {
                            sentColor = isDark ? const Color(0xfff87171) : const Color(0xffb91c1c);
                            sentBg = isDark ? const Color(0xff451a1a) : const Color(0xfffee2e2);
                            sentBorder = const Color(0xff991b1b);
                            sentLabel = _tr('market.news_sentiment_caution', 'WASPADA', 'CAUTION');
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xff111827) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0),
                              ),
                              boxShadow: isDark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Source badge, category, sentiment
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xff1e293b) : const Color(0xfff1f5f9),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: isDark ? const Color(0xff334155) : const Color(0xffcbd5e1),
                                        ),
                                      ),
                                      child: Text(
                                        n['source']?.toString() ?? 'Media',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xff334155),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "• ${n['category'] ?? 'Analisa'}",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10,
                                        color: isDark ? const Color(0xff64748b) : const Color(0xff94a3b8),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: sentBg,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(color: sentBorder, width: 0.8),
                                      ),
                                      child: Text(
                                        sentLabel,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: sentColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Headline title
                                Text(
                                  n['title']?.toString() ?? '',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xff0f172a),
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Bottom row: Relative time & action buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      n['timeAgo']?.toString() ?? 'Baru saja',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10.5,
                                        color: isDark ? const Color(0xff64748b) : const Color(0xff94a3b8),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        // Baca button
                                        GestureDetector(
                                          onTap: () => _openNewsUrl(n['url']?.toString() ?? ''),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xff1e293b) : const Color(0xfff1f5f9),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isDark ? const Color(0xff334155) : const Color(0xffcbd5e1),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.open_in_new_rounded,
                                                  size: 11,
                                                  color: isDark ? const Color(0xffcbd5e1) : const Color(0xff334155),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _tr('market.news_btn_read', 'Baca', 'Read'),
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark ? const Color(0xffcbd5e1) : const Color(0xff334155),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        // Analisa Dampak button
                                        GestureDetector(
                                          onTap: () => _analyzeNewsImpactWithAi(n, stock),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xff10b981).withOpacity(0.12)
                                                  : const Color(0xffd1fae5),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isDark
                                                    ? const Color(0xff10b981).withOpacity(0.4)
                                                    : const Color(0xff059669),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.auto_awesome_rounded,
                                                  size: 12,
                                                  color: isDark ? const Color(0xff34d399) : const Color(0xff065f46),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _tr('market.news_btn_analyze_impact', 'Analisa Dampak', 'Analyze Impact'),
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w900,
                                                    color: isDark ? const Color(0xff34d399) : const Color(0xff065f46),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // 6. Sticky Bottom Trading Bar
  Widget _buildBottomTradingBar(Map<String, dynamic> stock, AppState appState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final holdingLots = appState.getHoldingLots(stock['ticker']);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff0f172a) : colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xff1e293b) : colorScheme.outline.withOpacity(0.15),
            width: 1.2,
          ),
        ),
      ),
      child: Row(
        children: [
          // Cash & Holdings Indicator
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      _tr('market.cash_label', 'Kas: ', 'Cash: '),
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      formatRupiah(appState.virtualBalance),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: isDark ? const Color(0xff10b981) : const Color(0xff059669),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  holdingLots > 0
                      ? _tr('market.holding_status', "Memiliki: $holdingLots Lot ${stock['ticker']}", "Holding: $holdingLots Lots of ${stock['ticker']}", params: {'lots': '$holdingLots', 'ticker': '${stock['ticker']}'})
                      : _tr('market.no_holding_status', 'Belum punya saham ini', 'No holdings in this stock'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    color: holdingLots > 0
                        ? (isDark ? const Color(0xff60a5fa) : const Color(0xff2563eb))
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Jual Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffdc2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => _showOrderSheet(context, appState, stock, isBuy: false),
            child: Text(
              _tr('market.btn_sell', 'JUAL', 'SELL'),
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(width: 8),

          // Beli Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => _showOrderSheet(context, appState, stock, isBuy: true),
            child: Text(
              _tr('market.btn_buy', 'BELI', 'BUY'),
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // 7. Interactive Order Bottom Sheet
  void _showOrderSheet(BuildContext context, AppState appState, Map<String, dynamic> stock, {required bool isBuy}) {
    AudioService.playConfirm();
    final currentPrice = (stock['price'] as num).toDouble();
    final holdingLots = appState.getHoldingLots(stock['ticker']);
    int lotCount = 1;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    String tr(String key, String fallbackId, String fallbackEn, {Map<String, String> params = const {}}) =>
        _t(appState, key, fallbackId, fallbackEn, params: params);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xff0f172a) : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: isDark ? const Color(0xff1e293b) : colorScheme.outline.withOpacity(0.15)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final int totalShares = lotCount * 100;
            final double subtotal = currentPrice * totalShares;
            final double feePct = isBuy ? 0.0015 : 0.0025;
            final double fee = subtotal * feePct;
            final double total = isBuy ? (subtotal + fee) : (subtotal - fee);
            final bool canAfford = isBuy ? (appState.virtualBalance >= total) : (holdingLots >= lotCount);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xff475569) : const Color(0xffcbd5e1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title & Ticker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isBuy
                                  ? (isDark ? const Color(0xff065f46) : const Color(0xffd1fae5))
                                  : (isDark ? const Color(0xff7f1d1d) : const Color(0xfffee2e2)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isBuy ? tr('market.order_buy_badge', 'ORDER BELI', 'BUY ORDER') : tr('market.order_sell_badge', 'ORDER JUAL', 'SELL ORDER'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isBuy
                                    ? (isDark ? const Color(0xff34d399) : const Color(0xff059669))
                                    : (isDark ? const Color(0xfff87171) : const Color(0xffdc2626)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            stock['ticker'],
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        formatRupiah(currentPrice),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    stock['name'] ?? '',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),

                  // Lot Selector Controls
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff1e293b) : const Color(0xfff8fafc),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : colorScheme.outline.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr('market.lot_amount_label', 'Jumlah Lot', 'Lot Quantity'),
                              style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                            ),
                            Text(
                              tr('market.shares_count', '$totalShares Lembar', '$totalShares Shares', params: {'shares': '$totalShares'}),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: isDark ? const Color(0xff60a5fa) : const Color(0xff2563eb),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xff334155) : const Color(0xffe2e8f0),
                                foregroundColor: isDark ? Colors.white : colorScheme.onSurface,
                              ),
                              onPressed: lotCount > 1
                                  ? () => setSheetState(() => lotCount--)
                                  : null,
                              icon: const Icon(Icons.remove_rounded, size: 18),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  tr('market.lots_count', '$lotCount Lot', '$lotCount Lots', params: {'lots': '$lotCount'}),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xff334155) : const Color(0xffe2e8f0),
                                foregroundColor: isDark ? Colors.white : colorScheme.onSurface,
                              ),
                              onPressed: () => setSheetState(() => lotCount++),
                              icon: const Icon(Icons.add_rounded, size: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Quick buttons: +1, +5, +10, +50, MAX
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQuickLotBtn("+1", () => setSheetState(() => lotCount += 1)),
                            _buildQuickLotBtn("+5", () => setSheetState(() => lotCount += 5)),
                            _buildQuickLotBtn("+10", () => setSheetState(() => lotCount += 10)),
                            _buildQuickLotBtn("+50", () => setSheetState(() => lotCount += 50)),
                            _buildQuickLotBtn("MAX", () {
                              if (isBuy) {
                                final pricePerLot = currentPrice * 100 * 1.0015;
                                final maxLots = (appState.virtualBalance / pricePerLot).floor();
                                setSheetState(() => lotCount = max(1, maxLots));
                              } else {
                                setSheetState(() => lotCount = max(1, holdingLots));
                              }
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Calculation Breakdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff1e293b).withOpacity(0.5) : const Color(0xfff1f5f9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _buildCalcRow(tr('market.calc_subtotal', 'Subtotal', 'Subtotal'), formatRupiah(subtotal)),
                        const SizedBox(height: 6),
                        _buildCalcRow(
                          tr('market.calc_fee_broker', "Fee Sekuritas BEI (${isBuy ? '0.15%' : '0.25%'})", "IDX Broker Fee (${isBuy ? '0.15%' : '0.25%'})", params: {'pct': isBuy ? '0.15%' : '0.25%'}),
                          formatRupiah(fee),
                        ),
                        Divider(color: isDark ? const Color(0xff334155) : colorScheme.outline.withOpacity(0.15), height: 14),
                        _buildCalcRow(
                          isBuy ? tr('market.calc_total_payment', 'Total Pembayaran', 'Total Payment') : tr('market.calc_net_proceeds', 'Total Penerimaan Bersih', 'Net Proceeds'),
                          formatRupiah(total),
                          isBold: true,
                          valueColor: isBuy
                              ? (isDark ? const Color(0xff34d399) : const Color(0xff059669))
                              : (isDark ? const Color(0xfff87171) : const Color(0xffdc2626)),
                        ),
                        const SizedBox(height: 6),
                        _buildCalcRow(
                          isBuy ? tr('market.calc_available_balance', 'Saldo Kas Tersedia', 'Available Cash Balance') : tr('market.calc_current_lots', 'Lot Dimiliki Saat Ini', 'Current Lots Held'),
                          isBuy ? formatRupiah(appState.virtualBalance) : tr('market.lots_count', '$holdingLots Lot', '$holdingLots Lots', params: {'lots': '$holdingLots'}),
                          valueColor: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Confirm Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBuy ? const Color(0xff059669) : const Color(0xffdc2626),
                      disabledBackgroundColor: isDark ? const Color(0xff334155) : const Color(0xffcbd5e1),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                    ),
                    onPressed: (!canAfford || lotCount <= 0)
                        ? null
                        : () {
                            Navigator.of(ctx).pop();
                            if (isBuy) {
                              final res = appState.buyStock(
                                ticker: stock['ticker'],
                                price: currentPrice,
                                lots: lotCount,
                              );
                              if (appState.soundHaptic) HapticFeedback.mediumImpact();
                              final String msg = res['success']
                                  ? tr('market.buy_success_msg',
                                      'Berhasil beli $lotCount Lot ${stock['ticker']} @ ${formatRupiah(currentPrice)}',
                                      'Successfully bought $lotCount Lots of ${stock['ticker']} @ ${formatRupiah(currentPrice)}',
                                      params: {
                                        'lots': '$lotCount',
                                        'ticker': '${stock['ticker']}',
                                        'price': formatRupiah(currentPrice),
                                      })
                                  : (res['message'] == 'Jumlah lot harus lebih dari 0'
                                      ? tr('market.error_zero_lots', 'Jumlah lot harus lebih dari 0', 'Lot quantity must be greater than 0')
                                      : tr('market.error_insufficient_cash',
                                          'Saldo kas virtual tidak cukup untuk beli $lotCount Lot ${stock['ticker']}',
                                          'Insufficient virtual cash to buy $lotCount Lots of ${stock['ticker']}',
                                          params: {
                                            'lots': '$lotCount',
                                            'ticker': '${stock['ticker']}',
                                          }));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: res['success'] ? const Color(0xff059669) : const Color(0xffdc2626),
                                  content: Text(msg),
                                ),
                              );
                            } else {
                              final res = appState.sellStock(
                                ticker: stock['ticker'],
                                price: currentPrice,
                                lots: lotCount,
                              );
                              if (appState.soundHaptic) HapticFeedback.mediumImpact();
                              final pnl = res['pnl'] as double?;
                              final pnlStr = pnl != null ? " (PnL: ${formatRupiah(pnl)})" : "";
                              final String msg = res['success']
                                  ? tr('market.sell_success_msg',
                                      'Berhasil jual $lotCount Lot ${stock['ticker']} @ ${formatRupiah(currentPrice)}$pnlStr',
                                      'Successfully sold $lotCount Lots of ${stock['ticker']} @ ${formatRupiah(currentPrice)}$pnlStr',
                                      params: {
                                        'lots': '$lotCount',
                                        'ticker': '${stock['ticker']}',
                                        'price': formatRupiah(currentPrice),
                                      })
                                  : (res['message'] == 'Jumlah lot harus lebih dari 0'
                                      ? tr('market.error_zero_lots', 'Jumlah lot harus lebih dari 0', 'Lot quantity must be greater than 0')
                                      : (res['message'] != null && res['message'].toString().contains('belum memiliki portofolio')
                                          ? tr('market.error_no_portfolio',
                                              'Anda belum memiliki portofolio saham ${stock['ticker']}',
                                              'You do not own any shares of ${stock['ticker']}',
                                              params: {'ticker': '${stock['ticker']}'})
                                          : tr('market.error_insufficient_lots',
                                              'Lot tidak cukup (Anda hanya memiliki $holdingLots Lot ${stock['ticker']})',
                                              'Insufficient lots (You only have $holdingLots Lots of ${stock['ticker']})',
                                              params: {'currentLots': '$holdingLots', 'ticker': '${stock['ticker']}'})));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: res['success'] ? const Color(0xff059669) : const Color(0xffdc2626),
                                  content: Text(msg),
                                ),
                              );
                            }
                          },
                    child: Text(
                      !canAfford
                          ? (isBuy ? tr('market.btn_insufficient_balance', 'SALDO TIDAK CUKUP', 'INSUFFICIENT BALANCE') : tr('market.btn_insufficient_lots', 'LOT TIDAK MENCUKUPI', 'INSUFFICIENT LOTS'))
                          : (isBuy
                              ? tr('market.btn_confirm_buy', 'KONFIRMASI BELI $lotCount LOT', 'CONFIRM BUY $lotCount LOTS', params: {'lots': '$lotCount'})
                              : tr('market.btn_confirm_sell', 'KONFIRMASI JUAL $lotCount LOT', 'CONFIRM SELL $lotCount LOTS', params: {'lots': '$lotCount'})),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 8. Pro Portfolio Tab View
  Widget _buildPortfolioTab(AppState appState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    String tr(String key, String fallbackId, String fallbackEn, {Map<String, String> params = const {}}) =>
        _t(appState, key, fallbackId, fallbackEn, params: params);

    double totalStockValue = 0.0;
    double totalCostBasis = 0.0;

    for (var pos in appState.portfolio) {
      final ticker = pos['ticker'] as String;
      final lots = (pos['lots'] as num).toInt();
      final avgPrice = (pos['avgPrice'] as num).toDouble();

      final stockMatch = _allStocks.firstWhere(
        (st) => st['ticker'] == ticker,
        orElse: () => {'price': avgPrice},
      );
      final currentPrice = (stockMatch['price'] as num).toDouble();
      final shares = lots * 100;
      totalStockValue += (currentPrice * shares);
      totalCostBasis += (avgPrice * shares);
    }

    final totalEquity = appState.virtualBalance + totalStockValue;
    final floatingPnl = totalStockValue - totalCostBasis;
    final floatingPnlPct = totalCostBasis > 0 ? (floatingPnl / totalCostBasis) * 100 : 0.0;
    final bool isOverallProfit = floatingPnl >= 0;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Total Portfolio Valuation Header Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xff1e293b), Color(0xff0f172a)]
                  : [colorScheme.surface, colorScheme.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xff334155) : colorScheme.outline.withOpacity(0.2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('market.portfolio_total_value', 'TOTAL NILAI PORTOFOLIO', 'TOTAL PORTFOLIO VALUE'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showResetTradingConfirmation(context, appState),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xff334155).withOpacity(0.6) : const Color(0xffe2e8f0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 12,
                            color: isDark ? const Color(0xffcbd5e1) : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tr('market.reset_balance_btn', 'Reset Saldo', 'Reset Balance'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10,
                              color: isDark ? const Color(0xffcbd5e1) : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                formatRupiah(totalEquity),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOverallProfit
                          ? (isDark ? const Color(0xff064e3b) : const Color(0xffd1fae5))
                          : (isDark ? const Color(0xff450a0a) : const Color(0xfffee2e2)),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isOverallProfit ? const Color(0xff10b981) : const Color(0xffef4444),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isOverallProfit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 13,
                          color: isOverallProfit
                              ? (isDark ? const Color(0xff34d399) : const Color(0xff059669))
                              : (isDark ? const Color(0xfff87171) : const Color(0xffdc2626)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${isOverallProfit ? '+' : ''}${formatRupiah(floatingPnl)} (${floatingPnlPct.toStringAsFixed(2)}%)",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: isOverallProfit
                                ? (isDark ? const Color(0xff34d399) : const Color(0xff059669))
                                : (isDark ? const Color(0xfff87171) : const Color(0xffdc2626)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr('market.floating_pnl', 'Floating PnL', 'Floating PnL'),
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              Divider(
                color: isDark ? const Color(0xff334155) : colorScheme.outline.withOpacity(0.15),
                height: 24,
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildPortfolioStatTile(
                      tr('market.virtual_cash_balance', 'Saldo Kas Virtual', 'Virtual Cash Balance'),
                      formatRupiah(appState.virtualBalance),
                      isDark ? const Color(0xff10b981) : const Color(0xff059669),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: isDark ? const Color(0xff334155) : colorScheme.outline.withOpacity(0.15),
                  ),
                  Expanded(
                    child: _buildPortfolioStatTile(
                      tr('market.stock_market_value', 'Nilai Pasar Saham', 'Stock Market Value'),
                      formatRupiah(totalStockValue),
                      isDark ? const Color(0xff60a5fa) : const Color(0xff2563eb),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Holdings Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart_rounded, color: Color(0xff10b981), size: 18),
                const SizedBox(width: 6),
                Text(
                  tr('market.owned_stocks_header', 'Saham yang Dimiliki (${appState.portfolio.length})', 'Owned Stocks (${appState.portfolio.length})', params: {'count': '${appState.portfolio.length}'}),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            Text(
              tr('market.regular_market', 'Pasar Reguler BEI', 'IDX Regular Market'),
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (appState.portfolio.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff111827) : colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : colorScheme.outline.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 40,
                  color: isDark ? const Color(0xff475569) : const Color(0xff94a3b8),
                ),
                const SizedBox(height: 10),
                Text(
                  tr('market.portfolio_empty_title', 'Belum Ada Saham di Portofolio', 'No Stocks in Portfolio Yet'),
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('market.portfolio_empty_desc', 'Gunakan saldo kas virtual Rp 100 Juta Anda untuk membeli saham pilihan di tab Grafik atau Order Book.', 'Use your virtual cash balance of IDR 100 Million to buy selected stocks in the Chart or Order Book tab.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: colorScheme.onSurfaceVariant, height: 1.4),
                ),
              ],
            ),
          )
        else
          ...appState.portfolio.map((pos) {
            final ticker = pos['ticker'] as String;
            final lots = (pos['lots'] as num).toInt();
            final avgPrice = (pos['avgPrice'] as num).toDouble();

            final stockMatch = _allStocks.firstWhere(
              (st) => st['ticker'] == ticker,
              orElse: () => {'ticker': ticker, 'name': ticker, 'price': avgPrice, 'sector': 'Saham'},
            );
            final currentPrice = (stockMatch['price'] as num).toDouble();
            final shares = lots * 100;
            final totalVal = currentPrice * shares;
            final cost = avgPrice * shares;
            final pnl = totalVal - cost;
            final pnlPct = cost > 0 ? (pnl / cost) * 100 : 0.0;
            final isGreen = pnl >= 0;

            final pnlColor = isGreen
                ? (isDark ? const Color(0xff34d399) : const Color(0xff059669))
                : (isDark ? const Color(0xfff87171) : const Color(0xffdc2626));

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff111827) : colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : colorScheme.outline.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            ticker,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xff1e293b) : const Color(0xffeff6ff),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tr('market.lots_count', '$lots Lot', '$lots Lots', params: {'lots': '$lots'}),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xff60a5fa) : const Color(0xff2563eb),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${isGreen ? '+' : ''}${formatRupiah(pnl)}",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: pnlColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr('market.portfolio_avg_current', "Avg: ${formatRupiah(avgPrice)} • Saat ini: ${formatRupiah(currentPrice)}", "Avg: ${formatRupiah(avgPrice)} • Current: ${formatRupiah(currentPrice)}", params: {'avg': formatRupiah(avgPrice), 'current': formatRupiah(currentPrice)}),
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        "${isGreen ? '+' : ''}${pnlPct.toStringAsFixed(2)}%",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: pnlColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        tr('market.portfolio_total_val', "Total: ${formatRupiah(totalVal)}", "Total: ${formatRupiah(totalVal)}", params: {'val': formatRupiah(totalVal)}),
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 11.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xffef4444),
                          side: const BorderSide(color: Color(0xffef4444)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: const Size(0, 30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showOrderSheet(context, appState, stockMatch, isBuy: false),
                        child: Text(tr('market.btn_sell', 'JUAL', 'SELL'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff10b981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: const Size(0, 30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: () => _showOrderSheet(context, appState, stockMatch, isBuy: true),
                        child: Text(tr('market.btn_buy_more', 'BELI LAGI', 'BUY MORE'), style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 20),

        // Trade History Section
        Row(
          children: [
            const Icon(Icons.history_rounded, color: Color(0xfff59e0b), size: 18),
            const SizedBox(width: 6),
            Text(
              tr('market.history_header', 'Riwayat Transaksi (${appState.tradeHistory.length})', 'Trade History (${appState.tradeHistory.length})', params: {'count': '${appState.tradeHistory.length}'}),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (appState.tradeHistory.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: Text(
              tr('market.history_empty', 'Belum ada riwayat transaksi', 'No transaction history yet'),
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          )
        else
          ...appState.tradeHistory.map((th) {
            final isBuy = th['type'] == 'BUY';
            final pnl = th['realizedPnl'] as double?;
            final pnlCol = pnl != null
                ? (pnl >= 0
                    ? (isDark ? const Color(0xff34d399) : const Color(0xff059669))
                    : (isDark ? const Color(0xfff87171) : const Color(0xffdc2626)))
                : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff111827) : colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : colorScheme.outline.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isBuy
                          ? (isDark ? const Color(0xff064e3b) : const Color(0xffd1fae5))
                          : (isDark ? const Color(0xff450a0a) : const Color(0xfffee2e2)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isBuy ? tr('market.badge_buy', 'BELI', 'BUY') : tr('market.badge_sell', 'JUAL', 'SELL'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isBuy
                            ? (isDark ? const Color(0xff34d399) : const Color(0xff059669))
                            : (isDark ? const Color(0xfff87171) : const Color(0xffdc2626)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('market.history_item', "${th['ticker']} • ${th['lots']} Lot @ ${formatRupiah(th['price'] as num)}", "${th['ticker']} • ${th['lots']} Lots @ ${formatRupiah(th['price'] as num)}", params: {'ticker': "${th['ticker']}", 'lots': "${th['lots']}", 'price': formatRupiah(th['price'] as num)}),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          th['timestamp'] as String? ?? '',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatRupiah(th['total'] as num),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (pnl != null)
                        Text(
                          tr('market.pnl_prefix', "PnL: ${pnl >= 0 ? '+' : ''}${formatRupiah(pnl)}", "PnL: ${pnl >= 0 ? '+' : ''}${formatRupiah(pnl)}", params: {'val': "${pnl >= 0 ? '+' : ''}${formatRupiah(pnl)}"}),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: pnlCol,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 24),
      ],
    );
  }

  void _showResetTradingConfirmation(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    String tr(String key, String fallbackId, String fallbackEn, {Map<String, String> params = const {}}) =>
        _t(appState, key, fallbackId, fallbackEn, params: params);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xff1e293b) : colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          tr('market.dialog_reset_title', 'Reset Portofolio Simulator?', 'Reset Simulator Portfolio?'),
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        content: Text(
          tr('market.dialog_reset_content',
              'Seluruh posisi saham dan riwayat transaksi akan dihapus, dan saldo kas virtual akan dikembalikan ke Rp 100.000.000.',
              'All stock positions and transaction history will be cleared, and virtual cash balance will be reset to IDR 100,000,000.'),
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              tr('market.btn_cancel', 'Batal', 'Cancel'),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffdc2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              appState.resetVirtualTrading();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xff059669),
                  content: Text(
                    tr('market.snackbar_reset_success',
                        'Portofolio simulator berhasil di-reset ke Rp 100 Juta!',
                        'Simulator portfolio successfully reset to IDR 100 Million!'),
                  ),
                ),
              );
            },
            child: Text(
              tr('market.btn_reset', 'Reset', 'Reset'),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioStatTile(String label, String value, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCalcRow(String label, String val, {bool isBold = false, Color? valueColor}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: isBold ? 14 : 12.5,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            color: valueColor ?? colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLotBtn(String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        AudioService.playClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff334155) : const Color(0xffe2e8f0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

String formatRupiah(num number) {
  final str = number.toInt().abs().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(str[i]);
  }
  final sign = number < 0 ? '-Rp ' : 'Rp ';
  return '$sign$buffer';
}

class TradingViewUltraPainter extends CustomPainter {
  final List<Map<String, dynamic>> candles;
  final double stockPrice;
  final double highPrice;
  final double lowPrice;
  final bool showMA;
  final Offset? touchOffset;
  final Color gridColor;
  final Color textColor;
  final Color bullishColor;
  final Color bearishColor;
  final Color maColor;
  final Color crosshairColor;
  final Color lastPriceBadgeColor;
  final Color lastPriceTextColor;
  final Function(int) onHoverIndex;

  TradingViewUltraPainter({
    required this.candles,
    required this.stockPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.showMA,
    required this.touchOffset,
    required this.gridColor,
    required this.textColor,
    required this.bullishColor,
    required this.bearishColor,
    required this.maColor,
    required this.crosshairColor,
    required this.lastPriceBadgeColor,
    required this.lastPriceTextColor,
    required this.onHoverIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const yAxisWidth = 48.0;
    const xAxisHeight = 22.0;

    final chartWidth = size.width - yAxisWidth;
    final chartHeight = size.height - xAxisHeight;

    final candlePaneHeight = chartHeight * 0.74;
    final volPaneHeight = chartHeight * 0.22;

    // 1. Draw Grid Lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final textStyle = TextStyle(
      fontFamily: 'Outfit',
      fontSize: 9,
      fontWeight: FontWeight.bold,
      color: textColor,
    );

    // Draw Horizontal Y-Axis Price Grid Lines & Labels
    final minP = lowPrice * 0.99;
    final maxP = highPrice * 1.01;
    final pStep = (maxP - minP) / 4;

    for (int i = 0; i <= 4; i++) {
      final priceVal = maxP - (pStep * i);
      final y = (candlePaneHeight / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);

      // Y-Axis Price Text Label
      final tp = TextPainter(
        text: TextSpan(text: priceVal.toInt().toString(), style: textStyle),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(chartWidth + 6, y - 6));
    }

    if (candles.isEmpty) return;

    final candleWidth = chartWidth / candles.length;
    final maPoints = <Offset>[];

    // 2. Draw Candlesticks & Volume Histogram Bars
    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final x = i * candleWidth + (candleWidth * 0.15);

      final openP = (c['o'] as num).toDouble();
      final closeP = (c['c'] as num).toDouble();
      final highP = (c['h'] as num).toDouble();
      final lowP = (c['l'] as num).toDouble();

      final openY = candlePaneHeight * (1.0 - ((openP - minP) / (maxP - minP)));
      final closeY = candlePaneHeight * (1.0 - ((closeP - minP) / (maxP - minP)));
      final highY = candlePaneHeight * (1.0 - ((highP - minP) / (maxP - minP)));
      final lowY = candlePaneHeight * (1.0 - ((lowP - minP) / (maxP - minP)));

      final isGreen = closeP >= openP;
      final candleColor = isGreen ? bullishColor : bearishColor;

      // Draw High/Low Wick Line
      final wickPaint = Paint()
        ..color = candleColor
        ..strokeWidth = 1.4;
      canvas.drawLine(Offset(x + (candleWidth * 0.35), highY), Offset(x + (candleWidth * 0.35), lowY), wickPaint);

      // Draw Candle Body
      final bodyPaint = Paint()..color = candleColor;
      final topY = min(openY, closeY);
      final bottomY = max(openY, closeY);
      final height = max(3.0, (bottomY - topY));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, topY, candleWidth * 0.7, height),
          const Radius.circular(1.5),
        ),
        bodyPaint,
      );

      // Draw Volume Bar
      final vol = (c['vol'] as num).toDouble();
      final volH = (volPaneHeight * (vol / 100000.0)).clamp(3.0, volPaneHeight);
      final volY = chartHeight - volH;
      final volPaint = Paint()..color = candleColor.withOpacity(0.4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, volY, candleWidth * 0.7, volH),
          const Radius.circular(1.5),
        ),
        volPaint,
      );

      maPoints.add(Offset(x + (candleWidth * 0.35), (openY + closeY) / 2));

      // Draw X-Axis Time Labels every 6 candles
      if (i % 6 == 0 && c['time'] != null) {
        final tp = TextPainter(
          text: TextSpan(text: c['time'], style: textStyle),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x, chartHeight + 4));
      }
    }

    // 3. Draw Moving Average (EMA20) Smooth Curve
    if (showMA && maPoints.length > 1) {
      final maPaint = Paint()
        ..color = maColor // Amber MA Line
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;

      final maPath = Path();
      maPath.moveTo(maPoints[0].dx, maPoints[0].dy);
      for (int i = 1; i < maPoints.length; i++) {
        maPath.lineTo(maPoints[i].dx, maPoints[i].dy);
      }
      canvas.drawPath(maPath, maPaint);
    }

    // 4. Current Price Horizontal Dashed Line
    final lastCandle = candles.last;
    final lastPriceY = candlePaneHeight * (1.0 - (((lastCandle['c'] as num) - minP) / (maxP - minP)));
    final dashPaint = Paint()
      ..color = bullishColor.withOpacity(0.7)
      ..strokeWidth = 1.0;

    for (double dx = 0; dx < chartWidth; dx += 8) {
      canvas.drawLine(Offset(dx, lastPriceY), Offset(dx + 4, lastPriceY), dashPaint);
    }

    // Latest Price Pill on Y-Axis
    final priceBadgePaint = Paint()..color = lastPriceBadgeColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(chartWidth + 2, lastPriceY - 8, 44, 16),
        const Radius.circular(4),
      ),
      priceBadgePaint,
    );

    final lastPriceText = TextPainter(
      text: TextSpan(
        text: "${(lastCandle['c'] as num).toInt()}",
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: lastPriceTextColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    lastPriceText.layout();
    lastPriceText.paint(canvas, Offset(chartWidth + 6, lastPriceY - 6));

    // 5. INTERACTIVE TOUCH CROSSHAIR INSPECTION TOOL
    if (touchOffset != null) {
      final crosshairX = touchOffset!.dx.clamp(0.0, chartWidth);
      final crosshairY = touchOffset!.dy.clamp(0.0, candlePaneHeight);

      final crossPaint = Paint()
        ..color = crosshairColor.withOpacity(0.85)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      // Draw Crosshair Lines
      canvas.drawLine(Offset(0, crosshairY), Offset(chartWidth, crosshairY), crossPaint);
      canvas.drawLine(Offset(crosshairX, 0), Offset(crosshairX, chartHeight), crossPaint);

      // Hovered Candle Index
      int hoveredIdx = (crosshairX / candleWidth).floor().clamp(0, candles.length - 1);
      onHoverIndex(hoveredIdx);

      // Y-Axis Touch Price Tooltip Badge
      final touchPrice = maxP - ((crosshairY / candlePaneHeight) * (maxP - minP));
      final touchPillPaint = Paint()..color = crosshairColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(chartWidth + 2, crosshairY - 9, 44, 18),
          const Radius.circular(4),
        ),
        touchPillPaint,
      );

      final touchPriceText = TextPainter(
        text: TextSpan(
          text: touchPrice.toInt().toString(),
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.black),
        ),
        textDirection: TextDirection.ltr,
      );
      touchPriceText.layout();
      touchPriceText.paint(canvas, Offset(chartWidth + 6, crosshairY - 7));
    }
  }

  @override
  bool shouldRepaint(covariant TradingViewUltraPainter oldDelegate) {
    return oldDelegate.touchOffset != touchOffset ||
        oldDelegate.stockPrice != stockPrice ||
        oldDelegate.showMA != showMA ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.bullishColor != bullishColor ||
        oldDelegate.bearishColor != bearishColor ||
        oldDelegate.candles != candles;
  }
}
