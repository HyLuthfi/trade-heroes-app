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
import '../state/app_state.dart';
import '../widgets/tradingview_chart.dart';

class MarketView extends StatefulWidget {
  const MarketView({Key? key}) : super(key: key);

  @override
  State<MarketView> createState() => _MarketViewState();
}

class _MarketViewState extends State<MarketView> with SingleTickerProviderStateMixin {
  int _selectedStockIdx = 0;
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

  @override
  Widget build(BuildContext context) {
    try {
      final filtered = _filteredStocks;
      if (_allStocks.isEmpty) {
        return const Scaffold(
          backgroundColor: Color(0xff0b0f19),
          body: Center(
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
        backgroundColor: const Color(0xff0b0f19), // TradingView Pro Dark
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
      return Scaffold(
        backgroundColor: const Color(0xff0b0f19),
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
    final sectors = ["Semua", "Perbankan", "Telko", "Teknologi", "Otomotif", "Tambang", "Konsumer"];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: const BoxDecoration(
        color: Color(0xff0f172a),
        border: Border(bottom: BorderSide(color: Color(0xff1e293b))),
      ),
      child: Column(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xff1e293b),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
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
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Cari Saham BEI (e.g. BBCA, BBRI, GOTO)...",
                      hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xff64748b)),
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
                    child: const Icon(Icons.close_rounded, color: Color(0xff94a3b8), size: 18),
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
                      color: isSel ? const Color(0xff059669) : const Color(0xff1e293b),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSel ? const Color(0xff10b981) : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      sec,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: isSel ? Colors.white : const Color(0xff94a3b8),
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
    if (filteredList.isEmpty) {
      return Container(
        height: 44,
        color: const Color(0xff0f172a),
        alignment: Alignment.center,
        child: const Text(
          "Tidak ada saham yang cocok dengan pencarian",
          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xff94a3b8)),
        ),
      );
    }

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xff0f172a),
        border: Border(bottom: BorderSide(color: Color(0xff1e293b))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: filteredList.length,
        itemBuilder: (context, idx) {
          final st = filteredList[idx];
          final isSelected = idx == _selectedStockIdx;
          final isUp = st['changePct'] >= 0;

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
                color: isSelected ? const Color(0xff059669) : const Color(0xff1e293b),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color(0xff10b981) : Colors.white.withOpacity(0.08),
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
                      color: isSelected ? Colors.white : const Color(0xffcbd5e1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Rp ${st['price'].toInt()}",
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${isUp ? '+' : ''}${st['changePct']}%",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isUp ? const Color(0xff34d399) : const Color(0xfff87171),
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
    final tabs = [
      {'label': 'Grafik', 'icon': Icons.candlestick_chart_rounded},
      {'label': 'Tanya AI', 'icon': Icons.smart_toy_rounded},
      {'label': 'Berita', 'icon': Icons.newspaper_rounded},
    ];

    return Container(
      height: 42,
      decoration: const BoxDecoration(
        color: Color(0xff0f172a),
        border: Border(bottom: BorderSide(color: Color(0xff1e293b))),
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
                          color: isSelected ? const Color(0xff10b981) : const Color(0xff94a3b8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                            color: isSelected ? const Color(0xff10b981) : const Color(0xff94a3b8),
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
    final bool isUp = ((stock['changePct'] as num?)?.toDouble() ?? 0.0) >= 0;
    List<Map<String, dynamic>> candles = [];
    final rawTfMap = stock['timeframesMap'];
    if (rawTfMap is Map && rawTfMap[_selectedTimeframe] is List) {
      candles = List<Map<String, dynamic>>.from(rawTfMap[_selectedTimeframe]);
    } else if (stock['candles'] is List) {
      candles = List<Map<String, dynamic>>.from(stock['candles']);
    }

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
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        stock['sector']?.toString() ?? '',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Color(0xff64748b),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xff064e3b),
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
                              _isLoadingRealData ? "REFRESHING..." : "LIVE BEI",
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff10b981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    stock['name']?.toString() ?? '',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xff94a3b8),
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
              color: const Color(0xff111827),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCell("Open", "Rp ${(stock['open'] as num?)?.toInt() ?? 0}"),
                _buildMetricCell("High", "Rp ${(stock['high'] as num?)?.toInt() ?? 0}"),
                _buildMetricCell("Low", "Rp ${(stock['low'] as num?)?.toInt() ?? 0}"),
                _buildMetricCell("Val (Rp)", stock['value']?.toString() ?? "-"),
                _buildMetricCell("Foreign", stock['foreignNet']?.toString() ?? "-"),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // TRADINGVIEW OFFICIAL ADVANCED REAL-TIME CHART
          SizedBox(
            height: 520,
            child: TradingViewChart(
              key: ValueKey('${stock['ticker']}'),
              ticker: stock['ticker']?.toString() ?? 'BBCA',
              timeframe: '1D',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCell(String label, String val) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 9.5, color: Color(0xff64748b)),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
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
    _chatMessages.add({
      'isUser': false,
      'time': _formatCurrentTime(),
      'text': "Halo! Saya **SAI Tech AI Chatbot** 🤖.\n\nKamu sedang memantau saham **$ticker** (${stock['name'] ?? ''}) di harga **$p** ($chg).\n\nAda yang ingin kamu tanyakan mengenai analisa teknikal, valuasi fundamental, atau strategi trading untuk saham ini?",
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

    String answer = '';
    try {
      final res = await http.post(
        Uri.parse('/api/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': q,
          'ticker': stock['ticker']?.toString() ?? 'BBCA',
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

    // Default Prospek Analysis
    return "💡 **Analisa Prospek Bisnis & Tren $ticker:**\n\n"
        "• **Model Bisnis:** Sebagai pemain dominan di sektor $sector, $name memiliki *economic moat* yang kuat dan basis pelanggan yang loyal.\n"
        "• **Arus Dana Institusi:** Aktivitas net foreign tercatat ${stock['foreignNet'] ?? '-'}, menandakan minat investor institusi tetap aktif.\n"
        "• **Sentimen Pasar:** Tren harga di Rp $pInt menunjukkan konsolidasi sehat di area support teknikal.\n\n"
        "🎯 **Kesimpulan AI:** Saham ini menarik untuk dijadikan fondasi portofolio jangka menengah-panjang. Silakan manfaatkan koreksi wajar di area Rp $s1 untuk akumulasi bertahap.";
  }

  Widget _buildAiThinkingBubble() {
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
              color: const Color(0xff1e293b),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xff334155)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xff10b981)),
                ),
                SizedBox(width: 8),
                Text(
                  "AI sedang menganalisis data pasar...",
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xff94a3b8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessageItem(Map<String, dynamic> msg) {
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
                color: isUser ? const Color(0xff064e3b) : const Color(0xff1e293b),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: isUser ? const Radius.circular(14) : const Radius.circular(2),
                  bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(14),
                ),
                border: Border.all(
                  color: isUser ? const Color(0xff10b981).withOpacity(0.4) : const Color(0xff334155),
                ),
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: Colors.white,
                        height: 1.5,
                      ),
                      strong: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isUser ? const Color(0xffa7f3d0) : const Color(0xff34d399),
                      ),
                      em: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: Color(0xffcbd5e1),
                      ),
                      listBullet: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: Color(0xff10b981),
                      ),
                      h1: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      h2: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      h3: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xff38bdf8),
                      ),
                      code: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11.5,
                        color: Color(0xff38bdf8),
                        backgroundColor: Color(0xff0f172a),
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: const Color(0xff0f172a),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xff334155)),
                      ),
                      blockquote: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xff94a3b8),
                      ),
                      blockquoteDecoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: Color(0xff10b981), width: 3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9.5,
                      color: isUser ? const Color(0xff6ee7b7) : const Color(0xff64748b),
                    ),
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

    final quickChips = [
      "Analisa Prospek",
      "Support & Resistance",
      "Valuasi & Rasio",
      "Strategi Masuk/Keluar",
      "Tips Pemula",
    ];

    return Container(
      color: const Color(0xff0b0f19),
      child: Column(
        children: [
          // Header Info Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xff0f172a),
              border: Border(bottom: BorderSide(color: Color(0xff1e293b))),
            ),
            alignment: Alignment.centerLeft,
            child: const Text(
              "SAI Tech AI Chatbot",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
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
                  onTap: () => _sendChatMessage(label, stock),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xff1e293b),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xff334155)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xffcbd5e1),
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
            decoration: const BoxDecoration(
              color: Color(0xff0f172a),
              border: Border(top: BorderSide(color: Color(0xff1e293b))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xff1e293b),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xff334155)),
                    ),
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (val) => _sendChatMessage(val, stock),
                      decoration: InputDecoration(
                        hintText: "Tanya AI tentang ${stock['ticker']}...",
                        hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xff64748b)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendChatMessage(_chatController.text, stock),
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





  // TAB 4: MARKET NEWS WITH VECTOR MATERIAL ICONS
  Widget _buildNewsTab(Map<String, dynamic> stock) {
    final newsList = [
      {
        'title': "${stock['ticker']} Catat Pertumbuhan Laba Bersih Kuartal II Naik 14.5% YoY",
        'source': "Market Insider • 25 menit lalu",
        'sentiment': "BULLISH",
        'isBullish': true,
      },
      {
        'title': "Investor Asing Kembali Net Buy Saham ${stock['ticker']} Sebesar Rp 142 Miliar",
        'source': "Financial Times • 2 jam lalu",
        'sentiment': "BULLISH",
        'isBullish': true,
      },
      {
        'title': "Analisis Teknikal: ${stock['ticker']} Menguji Level Resistance Psikologis Utama",
        'source': "Trade Heroes Research • 4 jam lalu",
        'sentiment': "NETRAL",
        'isBullish': false,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: newsList.length,
      itemBuilder: (context, idx) {
        final n = newsList[idx];
        final bool isB = n['isBullish'] as bool;
        final Color sentColor = isB ? const Color(0xff34d399) : const Color(0xff94a3b8);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xff111827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(n['source'] as String, style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xff64748b))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isB ? const Color(0xff064e3b) : const Color(0xff1e293b),
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
                          n['sentiment'] as String,
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 9.5, fontWeight: FontWeight.w900, color: sentColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(n['title'] as String, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13.5, fontWeight: FontWeight.w900, color: Colors.white, height: 1.3)),
            ],
          ),
        );
      },
    );
  }

  // 6. Sticky Bottom Trading Bar
  Widget _buildBottomTradingBar(Map<String, dynamic> stock, AppState appState) {
    final holdingLots = appState.getHoldingLots(stock['ticker']);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xff0f172a),
        border: Border(top: BorderSide(color: Color(0xff1e293b), width: 1.2)),
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
                    const Text(
                      "Kas: ",
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xff94a3b8)),
                    ),
                    Text(
                      formatRupiah(appState.virtualBalance),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xff10b981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  holdingLots > 0 ? "Memiliki: $holdingLots Lot ${stock['ticker']}" : "Belum punya saham ini",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    color: holdingLots > 0 ? const Color(0xff60a5fa) : const Color(0xff64748b),
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
            child: const Text(
              "JUAL",
              style: TextStyle(fontFamily: 'Outfit', fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
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
            child: const Text(
              "BELI",
              style: TextStyle(fontFamily: 'Outfit', fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff0f172a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0xff1e293b)),
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
                        color: const Color(0xff475569),
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
                              color: isBuy ? const Color(0xff065f46) : const Color(0xff7f1d1d),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isBuy ? "ORDER BELI" : "ORDER JUAL",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isBuy ? const Color(0xff34d399) : const Color(0xfff87171),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            stock['ticker'],
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        formatRupiah(currentPrice),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    stock['name'] ?? '',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xff94a3b8)),
                  ),
                  const SizedBox(height: 16),

                  // Lot Selector Controls
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xff1e293b),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Jumlah Lot",
                              style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              "$totalShares Lembar",
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xff60a5fa)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xff334155),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: lotCount > 1
                                  ? () => setSheetState(() => lotCount--)
                                  : null,
                              icon: const Icon(Icons.remove_rounded, size: 18),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  "$lotCount Lot",
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xff334155),
                                foregroundColor: Colors.white,
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
                      color: const Color(0xff1e293b).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _buildCalcRow("Subtotal", formatRupiah(subtotal)),
                        const SizedBox(height: 6),
                        _buildCalcRow("Fee Sekuritas BEI (${isBuy ? '0.15%' : '0.25%'})", formatRupiah(fee)),
                        const Divider(color: Color(0xff334155), height: 14),
                        _buildCalcRow(
                          isBuy ? "Total Pembayaran" : "Total Penerimaan Bersih",
                          formatRupiah(total),
                          isBold: true,
                          valueColor: isBuy ? const Color(0xff34d399) : const Color(0xfff87171),
                        ),
                        const SizedBox(height: 6),
                        _buildCalcRow(
                          isBuy ? "Saldo Kas Tersedia" : "Lot Dimiliki Saat Ini",
                          isBuy ? formatRupiah(appState.virtualBalance) : "$holdingLots Lot",
                          valueColor: const Color(0xff94a3b8),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Confirm Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBuy ? const Color(0xff059669) : const Color(0xffdc2626),
                      disabledBackgroundColor: const Color(0xff334155),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: res['success'] ? const Color(0xff059669) : const Color(0xffdc2626),
                                  content: Text(res['message']),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: res['success'] ? const Color(0xff059669) : const Color(0xffdc2626),
                                  content: Text("${res['message']}$pnlStr"),
                                ),
                              );
                            }
                          },
                    child: Text(
                      !canAfford
                          ? (isBuy ? "SALDO TIDAK CUKUP" : "LOT TIDAK MENCUKUPI")
                          : (isBuy ? "KONFIRMASI BELI $lotCount LOT" : "KONFIRMASI JUAL $lotCount LOT"),
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
            gradient: const LinearGradient(
              colors: [Color(0xff1e293b), Color(0xff0f172a)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xff334155), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
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
                  const Text(
                    "TOTAL NILAI PORTOFOLIO",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff94a3b8),
                      letterSpacing: 0.8,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showResetTradingConfirmation(context, appState),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xff334155).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.refresh_rounded, size: 12, color: Color(0xffcbd5e1)),
                          SizedBox(width: 4),
                          Text(
                            "Reset Saldo",
                            style: TextStyle(fontFamily: 'Outfit', fontSize: 10, color: Color(0xffcbd5e1)),
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
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOverallProfit ? const Color(0xff064e3b) : const Color(0xff450a0a),
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
                          color: isOverallProfit ? const Color(0xff34d399) : const Color(0xfff87171),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${isOverallProfit ? '+' : ''}${formatRupiah(floatingPnl)} (${floatingPnlPct.toStringAsFixed(2)}%)",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: isOverallProfit ? const Color(0xff34d399) : const Color(0xfff87171),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Floating PnL",
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xff64748b)),
                  ),
                ],
              ),
              const Divider(color: Color(0xff334155), height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildPortfolioStatTile(
                      "Saldo Kas Virtual",
                      formatRupiah(appState.virtualBalance),
                      const Color(0xff10b981),
                    ),
                  ),
                  Container(width: 1, height: 32, color: const Color(0xff334155)),
                  Expanded(
                    child: _buildPortfolioStatTile(
                      "Nilai Pasar Saham",
                      formatRupiah(totalStockValue),
                      const Color(0xff60a5fa),
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
                  "Saham yang Dimiliki (${appState.portfolio.length})",
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Text(
              "BEI Regular Market",
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xff64748b)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (appState.portfolio.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xff111827),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: const Column(
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 40, color: Color(0xff475569)),
                SizedBox(height: 10),
                Text(
                  "Belum Ada Saham di Portofolio",
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  "Gunakan saldo kas virtual Rp 100 Juta Anda untuk membeli saham pilihan di tab Grafik atau Order Book.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xff94a3b8), height: 1.4),
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

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xff111827),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
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
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xff1e293b),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "$lots Lot",
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff60a5fa),
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
                          color: isGreen ? const Color(0xff34d399) : const Color(0xfff87171),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Avg: ${formatRupiah(avgPrice)} • Saat ini: ${formatRupiah(currentPrice)}",
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xff94a3b8)),
                      ),
                      Text(
                        "${isGreen ? '+' : ''}${pnlPct.toStringAsFixed(2)}%",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: isGreen ? const Color(0xff34d399) : const Color(0xfff87171),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "Total: ${formatRupiah(totalVal)}",
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xffcbd5e1)),
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
                        child: const Text("JUAL", style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold)),
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
                        child: const Text("BELI LAGI", style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold)),
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
              "Riwayat Transaksi (${appState.tradeHistory.length})",
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (appState.tradeHistory.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: const Text(
              "Belum ada riwayat transaksi",
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xff64748b)),
            ),
          )
        else
          ...appState.tradeHistory.map((th) {
            final isBuy = th['type'] == 'BUY';
            final pnl = th['realizedPnl'] as double?;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xff111827),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isBuy ? const Color(0xff064e3b) : const Color(0xff450a0a),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isBuy ? "BELI" : "JUAL",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isBuy ? const Color(0xff34d399) : const Color(0xfff87171),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${th['ticker']} • ${th['lots']} Lot @ ${formatRupiah(th['price'] as num)}",
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          th['timestamp'] as String? ?? '',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xff64748b)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatRupiah(th['total'] as num),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      if (pnl != null)
                        Text(
                          "PnL: ${pnl >= 0 ? '+' : ''}${formatRupiah(pnl)}",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: pnl >= 0 ? const Color(0xff34d399) : const Color(0xfff87171),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Reset Portofolio Simulator?",
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: const Text(
          "Seluruh posisi saham dan riwayat transaksi akan dihapus, dan saldo kas virtual akan dikembalikan ke Rp 100.000.000.",
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xffcbd5e1), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Batal", style: TextStyle(color: Color(0xff94a3b8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffdc2626)),
            onPressed: () {
              Navigator.of(ctx).pop();
              appState.resetVirtualTrading();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xff059669),
                  content: Text("Portofolio simulator berhasil di-reset ke Rp 100 Juta!"),
                ),
              );
            },
            child: const Text("Reset", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioStatTile(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xff94a3b8)),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.white : const Color(0xff94a3b8),
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: isBold ? 14 : 12.5,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLotBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        AudioService.playClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xff334155),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
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
