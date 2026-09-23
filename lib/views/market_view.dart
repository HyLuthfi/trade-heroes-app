import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../state/app_state.dart';

class MarketView extends StatefulWidget {
  const MarketView({Key? key}) : super(key: key);

  @override
  State<MarketView> createState() => _MarketViewState();
}

class _MarketViewState extends State<MarketView> with SingleTickerProviderStateMixin {
  int _selectedStockIdx = 0;
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
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _initStockDatabase();

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
    final filtered = _filteredStocks;
    final activeStock = filtered.isNotEmpty
        ? filtered[_selectedStockIdx.clamp(0, filtered.length - 1)]
        : _allStocks.first;
    final bool isBullish = activeStock['changePct'] >= 0;
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
                _touchOffset = null;
                _hoveredCandleIdx = null;
              });
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
      {'label': 'Order Book', 'icon': Icons.format_list_numbered_rounded},
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
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        stock['sector'],
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Color(0xff64748b),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    stock['name'],
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
              color: const Color(0xff111827),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCell("Open", "Rp ${stock['open'].toInt()}"),
                _buildMetricCell("High", "Rp ${stock['high'].toInt()}"),
                _buildMetricCell("Low", "Rp ${stock['low'].toInt()}"),
                _buildMetricCell("Val (Rp)", stock['value']),
                _buildMetricCell("Foreign", stock['foreignNet']),
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
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xff059669) : const Color(0xff1e293b),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tf,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isSel ? Colors.white : const Color(0xff94a3b8),
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
                    color: _showMA ? const Color(0xff78350f).withOpacity(0.4) : const Color(0xff1e293b),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _showMA ? const Color(0xfff59e0b) : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.show_chart_rounded, color: _showMA ? const Color(0xfff59e0b) : const Color(0xff94a3b8), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "EMA20",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: _showMA ? const Color(0xfffbbf24) : const Color(0xff94a3b8),
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
              final cColor = isCUp ? const Color(0xff34d399) : const Color(0xfff87171);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xff1e293b),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xff10b981).withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Time: ${c['time']}", style: const TextStyle(fontFamily: 'Outfit', fontSize: 10.5, color: Colors.white)),
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
                color: const Color(0xff0f172a),
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

  // TAB 2: ORDER BOOK
  Widget _buildOrderBookTab(Map<String, dynamic> stock) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ORDER BOOK (5-LEVEL BID / OFFER DEPTH)",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white,
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
                    color: const Color(0xff111827),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xff059669).withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: const BoxDecoration(
                          color: Color(0xff064e3b),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                        ),
                        alignment: Alignment.center,
                        child: const Text("BID (BELI)", style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xff34d399))),
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
                    color: const Color(0xff111827),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xffef4444).withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: const BoxDecoration(
                          color: Color(0xff78350f),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                        ),
                        alignment: Alignment.center,
                        child: const Text("OFFER (JUAL)", style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xfff87171))),
                      ),
                      ..._offers.map((o) => _buildProOrderBookRow(o['price'], o['vol'], o['pct'], false)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text(
            "RUNNING TRADE (LIVE EXECUTION FEED)",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xff111827),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: min(7, _runningTrade.length),
              separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
              itemBuilder: (context, idx) {
                final rt = _runningTrade[idx];
                final isBuy = rt['type'] == 'BUY';
                final col = isBuy ? const Color(0xff34d399) : const Color(0xfff87171);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(rt['time'], style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xff64748b))),
                      Text(rt['ticker'], style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text("Rp ${rt['price']}", style: TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w900, color: col)),
                      Text("${rt['vol']} Lot", style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold, color: col)),
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
    final barColor = isBid ? const Color(0xff059669).withOpacity(0.25) : const Color(0xffdc2626).withOpacity(0.25);
    final textColor = isBid ? const Color(0xff34d399) : const Color(0xfff87171);

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
                Text("${(vol / 1000).toStringAsFixed(1)}K", style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xffcbd5e1))),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "KEY FINANCIAL RATIOS & VALUATION",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _buildRatioRow("Market Capitalization", stock['marketCap']),
          const Divider(color: Color(0xff1e293b)),
          _buildRatioRow("Price to Earnings Ratio (PER)", "${stock['per']}x"),
          const Divider(color: Color(0xff1e293b)),
          _buildRatioRow("Price to Book Value (PBV)", "${stock['pbv']}x"),
          const Divider(color: Color(0xff1e293b)),
          _buildRatioRow("Foreign Net Buy / Sell", stock['foreignNet']),
        ],
      ),
    );
  }

  Widget _buildRatioRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xff94a3b8))),
          Text(val, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
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

// 30+ DENSE TRADINGVIEW ULTRA CANDLESTICK PAINTER WITH Y-AXIS PRICE LABELS & X-AXIS TIME LABELS & TOUCH CROSSHAIR
class TradingViewUltraPainter extends CustomPainter {
  final List<Map<String, dynamic>> candles;
  final double stockPrice;
  final double highPrice;
  final double lowPrice;
  final bool showMA;
  final Offset? touchOffset;
  final Function(int) onHoverIndex;

  TradingViewUltraPainter({
    required this.candles,
    required this.stockPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.showMA,
    required this.touchOffset,
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
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;

    final textStyle = TextStyle(
      fontFamily: 'Outfit',
      fontSize: 9,
      fontWeight: FontWeight.bold,
      color: Colors.white.withOpacity(0.45),
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
      final candleColor = isGreen ? const Color(0xff10b981) : const Color(0xffef4444);

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
        ..color = const Color(0xfff59e0b) // Amber MA Line
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
      ..color = const Color(0xff10b981).withOpacity(0.7)
      ..strokeWidth = 1.0;

    for (double dx = 0; dx < chartWidth; dx += 8) {
      canvas.drawLine(Offset(dx, lastPriceY), Offset(dx + 4, lastPriceY), dashPaint);
    }

    // Latest Price Pill on Y-Axis
    final priceBadgePaint = Paint()..color = const Color(0xff10b981);
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
        style: const TextStyle(fontFamily: 'Outfit', fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
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
        ..color = const Color(0xfff59e0b).withOpacity(0.85)
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
      final touchPillPaint = Paint()..color = const Color(0xfff59e0b);
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
    return oldDelegate.touchOffset != touchOffset || oldDelegate.stockPrice != stockPrice;
  }
}
