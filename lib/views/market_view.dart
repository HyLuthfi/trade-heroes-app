import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../services/market_data_service.dart';
import '../l10n/app_translations.dart';
import '../state/app_state.dart';

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
  bool _showMA = true;
  int _selectedTabIdx = 0; // 0: Chart, 1: Order Book, 2: Finansial, 3: Berita

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Interactive Crosshair Touch Offset
  Offset? _touchOffset;
  int? _hoveredCandleIdx;

  // Real Market Stocks Database with Generated 30+ Dense Historical Candles
  final List<Map<String, dynamic>> _allStocks = [];

  // Pro Order Book Data
  final List<Map<String, dynamic>> _bids = [
    {'price': 10250, 'vol': 18450, 'pct': 0.85},
    {'price': 10225, 'vol': 24120, 'pct': 1.00},
    {'price': 10200, 'vol': 19800, 'pct': 0.82},
    {'price': 10175, 'vol': 12350, 'pct': 0.51},
    {'price': 10150, 'vol': 8900, 'pct': 0.36},
  ];

  final List<Map<String, dynamic>> _offers = [
    {'price': 10275, 'vol': 15200, 'pct': 0.63},
    {'price': 10300, 'vol': 28900, 'pct': 1.00},
    {'price': 10325, 'vol': 19400, 'pct': 0.67},
    {'price': 10350, 'vol': 11200, 'pct': 0.38},
    {'price': 10375, 'vol': 7500, 'pct': 0.25},
  ];

  // Live Running Trade Logs
  final List<Map<String, dynamic>> _runningTrade = [
    {'time': '14:46:12', 'ticker': 'BBCA', 'price': 10250, 'vol': 100, 'type': 'BUY'},
    {'time': '14:46:10', 'ticker': 'BBRI', 'price': 5450, 'vol': 250, 'type': 'BUY'},
    {'time': '14:46:08', 'ticker': 'AMMN', 'price': 11450, 'vol': 300, 'type': 'BUY'},
    {'time': '14:46:05', 'ticker': 'TLKM', 'price': 3820, 'vol': 50, 'type': 'SELL'},
    {'time': '14:46:00', 'ticker': 'GOTO', 'price': 68, 'vol': 5000, 'type': 'BUY'},
  ];

  Timer? _liveTickTimer;
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

    _liveTickTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          final idx = _rnd.nextInt(_allStocks.length);
          final delta = (_rnd.nextDouble() - 0.48) * (_allStocks[idx]['price'] * 0.003);
          _allStocks[idx]['price'] = double.parse((_allStocks[idx]['price'] + delta).toStringAsFixed(1));

          final now = DateTime.now();
          final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
          _runningTrade.insert(0, {
            'time': timeStr,
            'ticker': _allStocks[idx]['ticker'],
            'price': _allStocks[idx]['price'].toInt(),
            'vol': (_rnd.nextInt(50) + 1) * 10,
            'type': delta >= 0 ? 'BUY' : 'SELL',
          });
          if (_runningTrade.length > 20) _runningTrade.removeLast();
        });
      }
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
              final realPrice = chartData['price'] > 0 ? chartData['price'] : candles.last['c'];
              activeStock['price'] = realPrice;

              final prevClose = chartData['prevClose'] > 0 ? chartData['prevClose'] : candles.first['o'];
              final change = realPrice - prevClose;
              final changePct = prevClose > 0 ? (change / prevClose) * 100 : 0.0;

              activeStock['change'] = change;
              activeStock['changePct'] = double.parse(changePct.toStringAsFixed(2));

              // Auto-generate realistic order book around real price
              _updateOrderBookAroundPrice(realPrice.toDouble());
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
              final realP = data['price'] > 0 ? data['price'] : target['price'];
              target['price'] = realP;
              final prevC = data['prevClose'] > 0 ? data['prevClose'] : realP;
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

  void _updateOrderBookAroundPrice(double price) {
    int step = price > 5000 ? 25 : (price > 2000 ? 10 : (price > 500 ? 5 : 1));
    int baseInt = (price / step).round() * step;

    _bids.clear();
    for (int i = 0; i < 5; i++) {
      int p = baseInt - (i * step);
      int vol = (_rnd.nextInt(150) + 50) * 100;
      _bids.add({'price': p, 'vol': vol, 'pct': (5 - i) / 5.0});
    }

    _offers.clear();
    for (int i = 0; i < 5; i++) {
      int p = baseInt + ((i + 1) * step);
      int vol = (_rnd.nextInt(150) + 50) * 100;
      _offers.add({'price': p, 'vol': vol, 'pct': (5 - i) / 5.0});
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
    _liveTickTimer?.cancel();
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final filtered = _filteredStocks;
    final activeStock = filtered.isNotEmpty
        ? filtered[_selectedStockIdx.clamp(0, filtered.length - 1)]
        : _allStocks.first;
    final bool isBullish = activeStock['changePct'] >= 0;
    final Color mainColor = isBullish
        ? (isDark ? const Color(0xff34d399) : const Color(0xff059669))
        : (isDark ? const Color(0xfff87171) : const Color(0xffdc2626));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                index: _selectedTabIdx,
                children: [
                  _buildTradingViewUltraChartTab(activeStock, mainColor),
                  _buildOrderBookTab(activeStock),
                  _buildNewsTab(activeStock),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Search Bar & Filter Chips
  Widget _buildSearchBarAndFilters() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final sectors = ["Semua", "Perbankan", "Telko", "Teknologi", "Otomotif", "Tambang", "Konsumer"];

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
                _touchOffset = null;
                _hoveredCandleIdx = null;
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
      {'label': _tr('market.tab_order_book', 'Order Book', 'Order Book'), 'icon': Icons.format_list_numbered_rounded},
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

    final bool isUp = stock['changePct'] >= 0;
    final Map<String, List<Map<String, dynamic>>> tfMap = stock['timeframesMap'] as Map<String, List<Map<String, dynamic>>>? ?? {};
    final candles = tfMap[_selectedTimeframe] ?? (stock['candles'] as List<Map<String, dynamic>>? ?? []);

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
                        stock['ticker'],
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getSectorLabel(stock['sector'] as String? ?? ''),
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
                    stock['name'],
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
                    "Rp ${stock['price'].toStringAsFixed(0)}",
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
                        "${isUp ? '+' : ''}${stock['change'].toInt()} (${isUp ? '+' : ''}${stock['changePct']}%)",
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
                _buildMetricCell(_tr('market.metric_open', 'Open', 'Open'), "Rp ${stock['open'].toInt()}"),
                _buildMetricCell(_tr('market.metric_high', 'High', 'High'), "Rp ${stock['high'].toInt()}"),
                _buildMetricCell(_tr('market.metric_low', 'Low', 'Low'), "Rp ${stock['low'].toInt()}"),
                _buildMetricCell(_tr('market.metric_value', 'Val (Rp)', 'Val (IDR)'), stock['value']),
                _buildMetricCell(_tr('market.metric_foreign', 'Foreign', 'Foreign'), stock['foreignNet']),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Timeframe & Indicator Selector Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: ["1D", "1W", "1M", "3M", "1Y"].map((tf) {
                  final isSel = _selectedTimeframe == tf;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTimeframe = tf;
                      });
                      _fetchRealMarketData();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xff059669) : (isDark ? const Color(0xff1e293b) : const Color(0xfff1f5f9)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSel ? const Color(0xff10b981) : (isDark ? Colors.transparent : colorScheme.outline.withOpacity(0.15)),
                        ),
                      ),
                      child: Text(
                        tf,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isSel ? Colors.white : (isDark ? const Color(0xff94a3b8) : colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              GestureDetector(
                onTap: () {
                  setState(() {
                    _showMA = !_showMA;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _showMA
                        ? (isDark ? const Color(0xff78350f).withOpacity(0.4) : const Color(0xfffef3c7))
                        : (isDark ? const Color(0xff1e293b) : const Color(0xfff1f5f9)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _showMA ? const Color(0xfff59e0b) : (isDark ? Colors.transparent : colorScheme.outline.withOpacity(0.15)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.show_chart_rounded,
                        color: _showMA
                            ? (isDark ? const Color(0xfff59e0b) : const Color(0xffd97706))
                            : colorScheme.onSurfaceVariant,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "EMA20",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: _showMA
                              ? (isDark ? const Color(0xfffbbf24) : const Color(0xffb45309))
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // INTERACTIVE CROSSHAIR TOOLTIP HEADER
          if (_hoveredCandleIdx != null && candles.isNotEmpty && _hoveredCandleIdx! < candles.length) ...[
            Builder(builder: (context) {
              final c = candles[_hoveredCandleIdx!];
              final isCUp = (c['c'] as num) >= (c['o'] as num);
              final cColor = isCUp
                  ? (isDark ? const Color(0xff34d399) : const Color(0xff059669))
                  : (isDark ? const Color(0xfff87171) : const Color(0xffdc2626));

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff1e293b) : colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xff10b981).withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_tr('market.crosshair_time', "Time: ${c['time']}", "Time: ${c['time']}", params: {'time': "${c['time']}"}), style: TextStyle(fontFamily: 'Outfit', fontSize: 10.5, color: colorScheme.onSurface)),
                    Text("O: ${c['o']}", style: TextStyle(fontFamily: 'Outfit', fontSize: 10.5, fontWeight: FontWeight.bold, color: cColor)),
                    Text("H: ${c['h']}", style: TextStyle(fontFamily: 'Outfit', fontSize: 10.5, fontWeight: FontWeight.bold, color: cColor)),
                    Text("L: ${c['l']}", style: TextStyle(fontFamily: 'Outfit', fontSize: 10.5, fontWeight: FontWeight.bold, color: cColor)),
                    Text("C: ${c['c']}", style: TextStyle(fontFamily: 'Outfit', fontSize: 10.5, fontWeight: FontWeight.bold, color: cColor)),
                  ],
                ),
              );
            }),
          ],

          // REAL 30+ DENSE TRADINGVIEW ULTRA CANDLESTICK ENGINE
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _touchOffset = details.localPosition;
              });
            },
            onPanEnd: (_) {
              setState(() {
                _touchOffset = null;
                _hoveredCandleIdx = null;
              });
            },
            onTapDown: (details) {
              setState(() {
                _touchOffset = details.localPosition;
              });
            },
            child: Container(
              height: 340,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff0f172a) : colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xff10b981).withOpacity(0.3), width: 1.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: TradingViewUltraPainter(
                      candles: candles,
                      stockPrice: stock['price'],
                      highPrice: stock['high'],
                      lowPrice: stock['low'],
                      showMA: _showMA,
                      touchOffset: _touchOffset,
                      gridColor: isDark ? Colors.white.withOpacity(0.04) : colorScheme.outline.withOpacity(0.12),
                      textColor: isDark ? Colors.white.withOpacity(0.45) : colorScheme.onSurfaceVariant.withOpacity(0.8),
                      bullishColor: const Color(0xff10b981),
                      bearishColor: const Color(0xffef4444),
                      maColor: const Color(0xfff59e0b),
                      crosshairColor: const Color(0xfff59e0b),
                      lastPriceBadgeColor: const Color(0xff10b981),
                      lastPriceTextColor: Colors.white,
                      onHoverIndex: (idx) {
                        if (_hoveredCandleIdx != idx) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _hoveredCandleIdx = idx;
                              });
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
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

  // TAB 2: ORDER BOOK
  Widget _buildOrderBookTab(Map<String, dynamic> stock) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr('market.order_book_title', 'ORDER BOOK (5-LEVEL BID / OFFER DEPTH)', 'ORDER BOOK (5-LEVEL BID / OFFER DEPTH)'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xff111827) : colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xff059669).withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xff064e3b) : const Color(0xffd1fae5),
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _tr('market.bid_label', 'BID (BELI)', 'BID (BUY)'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: isDark ? const Color(0xff34d399) : const Color(0xff059669),
                          ),
                        ),
                      ),
                      ..._bids.map((b) => _buildProOrderBookRow(b['price'], b['vol'], b['pct'], true)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xff111827) : colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xffef4444).withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xff78350f) : const Color(0xfffee2e2),
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _tr('market.offer_label', 'OFFER (JUAL)', 'OFFER (SELL)'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: isDark ? const Color(0xfff87171) : const Color(0xffdc2626),
                          ),
                        ),
                      ),
                      ..._offers.map((o) => _buildProOrderBookRow(o['price'], o['vol'], o['pct'], false)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            _tr('market.running_trade_title', 'RUNNING TRADE (LIVE EXECUTION FEED)', 'RUNNING TRADE (LIVE EXECUTION FEED)'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff111827) : colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : colorScheme.outline.withOpacity(0.15)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: min(7, _runningTrade.length),
              separatorBuilder: (_, __) => Divider(
                color: isDark ? Colors.white.withOpacity(0.05) : colorScheme.outline.withOpacity(0.1),
                height: 1,
              ),
              itemBuilder: (context, idx) {
                final rt = _runningTrade[idx];
                final isBuy = rt['type'] == 'BUY';
                final col = isBuy
                    ? (isDark ? const Color(0xff34d399) : const Color(0xff059669))
                    : (isDark ? const Color(0xfff87171) : const Color(0xffdc2626));

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(rt['time'], style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: colorScheme.onSurfaceVariant)),
                      Text(rt['ticker'], style: TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
                      Text("Rp ${rt['price']}", style: TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w900, color: col)),
                      Text(_tr('market.lot_unit', "${rt['vol']} Lot", "${rt['vol']} Lots", params: {'count': "${rt['vol']}"}), style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold, color: col)),
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

  Widget _buildProOrderBookRow(int price, int vol, double pct, bool isBid) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final barColor = isBid
        ? const Color(0xff059669).withOpacity(isDark ? 0.25 : 0.15)
        : const Color(0xffdc2626).withOpacity(isDark ? 0.25 : 0.15);
    final textColor = isBid
        ? (isDark ? const Color(0xff34d399) : const Color(0xff059669))
        : (isDark ? const Color(0xfff87171) : const Color(0xffdc2626));

    return Container(
      height: 32,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: pct.clamp(0.1, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${(vol / 1000).toStringAsFixed(1)}K", style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: colorScheme.onSurfaceVariant)),
                Text("$price", style: TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w900, color: textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: FINANCIALS & VALUATION
  Widget _buildFinancialsTab(Map<String, dynamic> stock) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr('market.financial_ratios_title', 'KEY FINANCIAL RATIOS & VALUATION', 'KEY FINANCIAL RATIOS & VALUATION'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildValuationCard(stock),
        ],
      ),
    );
  }

  Widget _buildValuationCard(Map<String, dynamic> stock) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff111827) : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : colorScheme.outline.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          _buildRatioRow(_tr('market.market_cap', 'Kapitalisasi Pasar', 'Market Capitalization'), stock['marketCap']),
          Divider(color: isDark ? const Color(0xff1e293b) : colorScheme.outline.withOpacity(0.15)),
          _buildRatioRow(_tr('market.per_ratio', 'Price to Earnings Ratio (PER)', 'Price to Earnings Ratio (PER)'), "${stock['per']}x"),
          Divider(color: isDark ? const Color(0xff1e293b) : colorScheme.outline.withOpacity(0.15)),
          _buildRatioRow(_tr('market.pbv_ratio', 'Price to Book Value (PBV)', 'Price to Book Value (PBV)'), "${stock['pbv']}x"),
          Divider(color: isDark ? const Color(0xff1e293b) : colorScheme.outline.withOpacity(0.15)),
          _buildRatioRow(_tr('market.foreign_flow', 'Arus Bersih Asing (Net Foreign)', 'Foreign Net Buy / Sell'), stock['foreignNet']),
        ],
      ),
    );
  }

  Widget _buildRatioRow(String label, String val) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: colorScheme.onSurfaceVariant)),
          Text(val, style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
        ],
      ),
    );
  }

  // TAB 4: MARKET NEWS WITH VECTOR MATERIAL ICONS
  Widget _buildNewsTab(Map<String, dynamic> stock) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isEn = Provider.of<AppState>(context, listen: false).language.toLowerCase().startsWith('en');

    final newsList = [
      {
        'title': isEn
            ? "${stock['ticker']} Reports Q2 Net Profit Growth Up 14.5% YoY"
            : "${stock['ticker']} Catat Pertumbuhan Laba Bersih Kuartal II Naik 14.5% YoY",
        'source': isEn ? "Market Insider • 25 mins ago" : "Market Insider • 25 menit lalu",
        'sentiment': "BULLISH",
        'sentimentLabel': _tr('market.sentiment_bullish', 'BULLISH', 'BULLISH'),
        'isBullish': true,
      },
      {
        'title': isEn
            ? "Foreign Investors Record Net Buy of IDR 142 Billion in ${stock['ticker']}"
            : "Investor Asing Kembali Net Buy Saham ${stock['ticker']} Sebesar Rp 142 Miliar",
        'source': isEn ? "Financial Times • 2 hours ago" : "Financial Times • 2 jam lalu",
        'sentiment': "BULLISH",
        'sentimentLabel': _tr('market.sentiment_bullish', 'BULLISH', 'BULLISH'),
        'isBullish': true,
      },
      {
        'title': isEn
            ? "Technical Analysis: ${stock['ticker']} Tests Key Psychological Resistance Level"
            : "Analisis Teknikal: ${stock['ticker']} Menguji Level Resistance Psikologis Utama",
        'source': isEn ? "Trade Heroes Research • 4 hours ago" : "Trade Heroes Research • 4 jam lalu",
        'sentiment': "NETRAL",
        'sentimentLabel': _tr('market.sentiment_neutral', 'NETRAL', 'NEUTRAL'),
        'isBullish': false,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: newsList.length,
      itemBuilder: (context, idx) {
        final n = newsList[idx];
        final bool isB = n['isBullish'] as bool;
        final Color sentColor = isB
            ? (isDark ? const Color(0xff34d399) : const Color(0xff059669))
            : colorScheme.onSurfaceVariant;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xff111827) : colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : colorScheme.outline.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(n['source'] as String, style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: colorScheme.onSurfaceVariant)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isB
                          ? (isDark ? const Color(0xff064e3b) : const Color(0xffd1fae5))
                          : (isDark ? const Color(0xff1e293b) : const Color(0xfff1f5f9)),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: sentColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isB ? Icons.trending_up_rounded : Icons.horizontal_rule_rounded,
                          color: sentColor,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (n['sentimentLabel'] ?? n['sentiment']) as String,
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 9.5, fontWeight: FontWeight.w900, color: sentColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(n['title'] as String, style: TextStyle(fontFamily: 'Outfit', fontSize: 13.5, fontWeight: FontWeight.w900, color: colorScheme.onSurface, height: 1.3)),
            ],
          ),
        );
      },
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

// 30+ DENSE TRADINGVIEW ULTRA CANDLESTICK PAINTER WITH Y-AXIS PRICE LABELS & X-AXIS TIME LABELS & TOUCH CROSSHAIR
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
