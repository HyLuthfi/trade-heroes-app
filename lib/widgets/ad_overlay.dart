import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/audio_service.dart';

class AdOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const AdOverlay({Key? key, required this.onClose}) : super(key: key);

  static void show(BuildContext context, VoidCallback onClose) {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.isPremium) {
      onClose();
      return;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Iklan",
      barrierColor: Colors.black.withOpacity(0.92),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, anim1, anim2) => AdOverlay(onClose: () {
        Navigator.of(ctx).pop();
        onClose();
      }),
    );
  }

  @override
  State<AdOverlay> createState() => _AdOverlayState();
}

class _AdOverlayState extends State<AdOverlay> with TickerProviderStateMixin {
  int _countdown = 5;
  Timer? _timer;
  late AnimationController _chartController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  final Random _rnd = Random();

  // Randomized ad content
  late Map<String, dynamic> _adContent;

  final List<Map<String, dynamic>> _adTemplates = [
    {
      'brand': 'Ajaib Sekuritas',
      'tagline': 'Investasi Saham Mulai Rp 10.000',
      'cta': 'Buka akun gratis, dapat bonus saham!',
      'desc': 'Daftar sekarang dan dapatkan bonus saham senilai hingga Rp 150.000 untuk investor baru.',
      'color': Color(0xff6C5CE7),
      'icon': Icons.rocket_launch_rounded,
      'rating': '4.8',
      'downloads': '10 Jt+',
    },
    {
      'brand': 'Stockbit',
      'tagline': 'Komunitas Investor Saham Terbesar',
      'cta': 'Analisa saham bareng 2 juta investor!',
      'desc': 'Screening saham cerdas, forum diskusi, dan streaming chart gratis tanpa batas.',
      'color': Color(0xff00B894),
      'icon': Icons.groups_rounded,
      'rating': '4.7',
      'downloads': '5 Jt+',
    },
    {
      'brand': 'Bareksa',
      'tagline': 'Investasi Reksadana & SBN Online',
      'cta': 'Mulai dari Rp 10.000, tanpa biaya!',
      'desc': 'Platform reksadana dan Surat Berharga Negara terpercaya dengan fitur auto-invest.',
      'color': Color(0xffFD79A8),
      'icon': Icons.account_balance_rounded,
      'rating': '4.6',
      'downloads': '3 Jt+',
    },
    {
      'brand': 'Bibit',
      'tagline': 'Robo Advisor Investasi Reksadana',
      'cta': 'Investasi otomatis sesuai profil risiko!',
      'desc': 'AI memilih portofolio reksadana terbaik berdasarkan tujuan keuangan dan profil risiko Anda.',
      'color': Color(0xff0984E3),
      'icon': Icons.auto_awesome_rounded,
      'rating': '4.8',
      'downloads': '8 Jt+',
    },
    {
      'brand': 'IPOT by Indo Premier',
      'tagline': 'Trading Saham & Reksadana Pro',
      'cta': 'Fee transaksi termurah di Indonesia!',
      'desc': 'Buka akun dengan verifikasi instan, fee beli 0.15% dan jual 0.25% paling kompetitif.',
      'color': Color(0xffE17055),
      'icon': Icons.trending_up_rounded,
      'rating': '4.5',
      'downloads': '2 Jt+',
    },
  ];

  @override
  void initState() {
    super.initState();
    _adContent = _adTemplates[_rnd.nextInt(_adTemplates.length)];
    _startTimer();

    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..forward();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _timer?.cancel();
          AudioService.playCorrect();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chartController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final Color brandColor = _adContent['color'] as Color;

    return WillPopScope(
      onWillPop: () async => _countdown <= 0,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xff0f172a),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: brandColor.withOpacity(0.5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: brandColor.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar at the very top
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressController.value,
                        minHeight: 3,
                        backgroundColor: const Color(0xff1e293b),
                        valueColor: AlwaysStoppedAnimation<Color>(brandColor),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top bar: Sponsored label + timer/close
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xff1e293b),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xff334155)),
                                ),
                                child: const Text(
                                  "Iklan",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff94a3b8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _adContent['brand'] as String,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: brandColor,
                                ),
                              ),
                            ],
                          ),
                          if (_countdown > 0)
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xff1e293b),
                                border: Border.all(color: const Color(0xff334155)),
                              ),
                              child: Text(
                                "$_countdown",
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xffcbd5e1),
                                ),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: widget.onClose,
                              child: Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Main ad card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              brandColor.withOpacity(0.08),
                              const Color(0xff1e293b).withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: brandColor.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Brand icon + title row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: brandColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: brandColor.withOpacity(0.4)),
                                  ),
                                  child: Icon(
                                    _adContent['icon'] as IconData,
                                    color: brandColor,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _adContent['brand'] as String,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _adContent['tagline'] as String,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11.5,
                                          color: Color(0xff94a3b8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Animated chart visual
                            Container(
                              height: 90,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xff0b0f19),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.06)),
                              ),
                              child: AnimatedBuilder(
                                animation: _chartController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: AdChartPainter(
                                      _chartController.value,
                                      lineColor: brandColor,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Description text
                            Text(
                              _adContent['desc'] as String,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Color(0xffcbd5e1),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Metrics row: rating + downloads
                            Row(
                              children: [
                                _buildMetricChip(Icons.star_rounded, _adContent['rating'] as String, const Color(0xfffbbf24)),
                                const SizedBox(width: 8),
                                _buildMetricChip(Icons.download_rounded, _adContent['downloads'] as String, const Color(0xff94a3b8)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: brandColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: brandColor.withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    _adContent['cta'] as String,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: brandColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // CTA Button
                      if (_countdown > 0)
                        Container(
                          width: double.infinity,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xff1e293b),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xff334155)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  color: brandColor,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Hadiah tersedia dalam $_countdown detik...",
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  color: Color(0xff94a3b8),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xff10b981).withOpacity(0.15 + _pulseController.value * 0.15),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff10b981),
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                onPressed: widget.onClose,
                                icon: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                                label: const Text(
                                  "KLAIM HADIAH & TUTUP",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 10),

                      // VIP Pass upsell
                      GestureDetector(
                        onTap: () {
                          widget.onClose();
                          appState.upgradeToPremium(context);
                        },
                        child: const Text(
                          "Bebas iklan selamanya? Upgrade VIP Gold Pass",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: Color(0xfff59e0b),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xfff59e0b),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xff1e293b),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xff334155)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class AdChartPainter extends CustomPainter {
  final double animationValue;
  final Color lineColor;

  AdChartPainter(this.animationValue, {this.lineColor = const Color(0xff10b981)});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.5;
    for (double i = 0.25; i < 1.0; i += 0.25) {
      canvas.drawLine(Offset(0, size.height * i), Offset(size.width, size.height * i), gridPaint);
    }

    // Generate realistic looking candlestick-style price points
    final rng = Random(42);
    final int pointCount = 24;
    final List<double> prices = [];
    double p = 0.5;
    for (int i = 0; i < pointCount; i++) {
      p += (rng.nextDouble() - 0.42) * 0.12;
      p = p.clamp(0.15, 0.85);
      prices.add(p);
    }

    final double segW = size.width / (pointCount - 1);
    final double limitX = size.width * animationValue;

    // Area fill
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.12), lineColor.withOpacity(0.0)],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final fillPath = Path();
    fillPath.moveTo(0, size.height * prices[0]);

    double lastX = 0, lastY = size.height * prices[0];
    for (int i = 1; i < pointCount; i++) {
      final x = segW * i;
      final y = size.height * prices[i];
      if (x <= limitX) {
        fillPath.lineTo(x, y);
        lastX = x;
        lastY = y;
      } else {
        final ratio = (limitX - segW * (i - 1)) / segW;
        final interpY = size.height * prices[i - 1] + (y - size.height * prices[i - 1]) * ratio;
        fillPath.lineTo(limitX, interpY);
        lastX = limitX;
        lastY = interpY;
        break;
      }
    }
    fillPath.lineTo(lastX, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    linePath.moveTo(0, size.height * prices[0]);
    for (int i = 1; i < pointCount; i++) {
      final x = segW * i;
      final y = size.height * prices[i];
      if (x <= limitX) {
        linePath.lineTo(x, y);
      } else {
        final ratio = (limitX - segW * (i - 1)) / segW;
        final interpY = size.height * prices[i - 1] + (y - size.height * prices[i - 1]) * ratio;
        linePath.lineTo(limitX, interpY);
        break;
      }
    }
    canvas.drawPath(linePath, linePaint);

    // Glowing endpoint dot
    if (animationValue > 0.02) {
      canvas.drawCircle(Offset(lastX, lastY), 6, Paint()..color = lineColor.withOpacity(0.3));
      canvas.drawCircle(Offset(lastX, lastY), 3, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant AdChartPainter oldDelegate) => true;
}
