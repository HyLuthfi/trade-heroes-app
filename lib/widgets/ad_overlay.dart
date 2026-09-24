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
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOut),
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
  final Random _rnd = Random();

  late Map<String, dynamic> _ad;

  final List<Map<String, dynamic>> _ads = [
    {
      'brand': 'Ajaib Sekuritas',
      'tagline': 'Investasi saham mulai Rp 10.000',
      'desc': 'Buka akun gratis dan dapatkan bonus saham senilai hingga Rp 150.000 untuk investor baru.',
      'cta': 'Daftar Gratis',
      'color': Color(0xff6C5CE7),
      'icon': Icons.rocket_launch_rounded,
      'rating': '4.8',
      'users': '10 Jt+',
    },
    {
      'brand': 'Stockbit',
      'tagline': 'Komunitas investor saham terbesar',
      'desc': 'Screening saham cerdas, forum diskusi aktif, dan streaming chart gratis tanpa batas.',
      'cta': 'Gabung Sekarang',
      'color': Color(0xff00B894),
      'icon': Icons.groups_rounded,
      'rating': '4.7',
      'users': '5 Jt+',
    },
    {
      'brand': 'Bareksa',
      'tagline': 'Reksadana & SBN online terpercaya',
      'desc': 'Investasi reksadana dan Surat Berharga Negara mulai Rp 10.000 tanpa biaya administrasi.',
      'cta': 'Mulai Investasi',
      'color': Color(0xffE84393),
      'icon': Icons.account_balance_rounded,
      'rating': '4.6',
      'users': '3 Jt+',
    },
    {
      'brand': 'Bibit',
      'tagline': 'Robo advisor reksadana pintar',
      'desc': 'AI memilihkan portofolio reksadana terbaik sesuai profil risiko dan tujuan keuangan Anda.',
      'cta': 'Coba Gratis',
      'color': Color(0xff0984E3),
      'icon': Icons.auto_awesome_rounded,
      'rating': '4.8',
      'users': '8 Jt+',
    },
    {
      'brand': 'IPOT Indo Premier',
      'tagline': 'Trading saham fee termurah',
      'desc': 'Fee beli 0.15% dan jual 0.25% paling kompetitif di Indonesia dengan verifikasi akun instan.',
      'cta': 'Buka Akun',
      'color': Color(0xffE17055),
      'icon': Icons.trending_up_rounded,
      'rating': '4.5',
      'users': '2 Jt+',
    },
  ];

  @override
  void initState() {
    super.initState();
    _ad = _ads[_rnd.nextInt(_ads.length)];
    _startTimer();

    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final Color c = _ad['color'] as Color;

    return WillPopScope(
      onWillPop: () async => _countdown <= 0,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xff111827),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: c.withOpacity(0.35), width: 1),
              boxShadow: [
                BoxShadow(color: c.withOpacity(0.12), blurRadius: 30),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Row 1: "Iklan" label + brand name ... close/timer
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xff1e293b),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        "Iklan",
                        style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, color: Color(0xff64748b)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _ad['brand'] as String,
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w700, color: c),
                      ),
                    ),
                    if (_countdown > 0)
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xff1e293b),
                        ),
                        child: Text(
                          "$_countdown",
                          style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xffcbd5e1)),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Row 2: Icon + Title block
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_ad['icon'] as IconData, color: c, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _ad['brand'] as String,
                            style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _ad['tagline'] as String,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xff94a3b8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Row 3: Animated chart
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xff0b0f19),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AnimatedBuilder(
                    animation: _chartController,
                    builder: (context, _) {
                      return CustomPaint(
                        size: const Size(double.infinity, 80),
                        painter: _AdChartPainter(_chartController.value, c),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Row 4: Description
                Text(
                  _ad['desc'] as String,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xffcbd5e1), height: 1.45),
                ),
                const SizedBox(height: 12),

                // Row 5: Metrics + CTA chip
                Row(
                  children: [
                    Icon(Icons.star_rounded, color: const Color(0xfffbbf24), size: 14),
                    const SizedBox(width: 3),
                    Text(_ad['rating'] as String, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xfffbbf24))),
                    const SizedBox(width: 12),
                    Icon(Icons.person_rounded, color: const Color(0xff94a3b8), size: 13),
                    const SizedBox(width: 3),
                    Text(_ad['users'] as String, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xff94a3b8))),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: c.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: c.withOpacity(0.35)),
                      ),
                      child: Text(
                        _ad['cta'] as String,
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 10.5, fontWeight: FontWeight.w800, color: c),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Row 6: Action button
                if (_countdown > 0)
                  Container(
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xff1e293b),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 13, height: 13, child: CircularProgressIndicator(color: c, strokeWidth: 2)),
                        const SizedBox(width: 10),
                        Text(
                          "Hadiah tersedia dalam $_countdown detik",
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xff94a3b8)),
                        ),
                      ],
                    ),
                  )
                else
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff10b981).withOpacity(0.1 + _pulseController.value * 0.12),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff10b981),
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: widget.onClose,
                          child: const Text(
                            "KLAIM HADIAH & TUTUP",
                            style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.3),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 10),

                // Row 7: VIP upsell
                GestureDetector(
                  onTap: () {
                    widget.onClose();
                    appState.upgradeToPremium(context);
                  },
                  child: const Center(
                    child: Text(
                      "Bebas iklan selamanya? Upgrade VIP Gold Pass",
                      style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xfff59e0b), decoration: TextDecoration.underline, decorationColor: Color(0xfff59e0b)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdChartPainter extends CustomPainter {
  final double t;
  final Color color;
  _AdChartPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Grid
    final gp = Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 0.5;
    for (double y = 0.25; y < 1.0; y += 0.25) {
      canvas.drawLine(Offset(0, size.height * y), Offset(size.width, size.height * y), gp);
    }

    // Price data (uptrend)
    final rng = Random(77);
    const n = 28;
    final prices = <double>[];
    double p = 0.65;
    for (int i = 0; i < n; i++) {
      p += (rng.nextDouble() - 0.38) * 0.08;
      p = p.clamp(0.12, 0.88);
      prices.add(p);
    }

    final segW = size.width / (n - 1);
    final limitX = size.width * t;

    // Build path
    double lastX = 0, lastY = size.height * prices[0];
    final line = Path()..moveTo(0, lastY);

    for (int i = 1; i < n; i++) {
      final x = segW * i;
      final y = size.height * prices[i];
      if (x <= limitX) {
        line.lineTo(x, y);
        lastX = x;
        lastY = y;
      } else {
        final r = (limitX - segW * (i - 1)) / segW;
        lastY = size.height * prices[i - 1] + (y - size.height * prices[i - 1]) * r;
        lastX = limitX;
        line.lineTo(lastX, lastY);
        break;
      }
    }

    // Fill
    final fill = Path.from(line)..lineTo(lastX, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(fill, Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.12), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height)));

    // Line
    canvas.drawPath(line, Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);

    // Dot
    if (t > 0.02) {
      canvas.drawCircle(Offset(lastX, lastY), 5, Paint()..color = color.withOpacity(0.25));
      canvas.drawCircle(Offset(lastX, lastY), 2.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _AdChartPainter old) => true;
}
