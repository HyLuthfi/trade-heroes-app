import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

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
      barrierColor: Colors.black.withOpacity(0.95),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => AdOverlay(onClose: () {
        Navigator.of(ctx).pop();
        onClose();
      }),
    );
  }

  @override
  State<AdOverlay> createState() => _AdOverlayState();
}

class _AdOverlayState extends State<AdOverlay> with SingleTickerProviderStateMixin {
  int _countdown = 5;
  Timer? _timer;
  late AnimationController _chartController;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return WillPopScope(
      onWillPop: () async => _countdown <= 0,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xff0f172a),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xff10b981), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff10b981).withOpacity(0.35),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Row (3D Sponsored Tag & Countdown Timer)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xff78350f), Color(0xffd97706)]),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xfff59e0b), width: 1.0),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.movie_rounded, color: Color(0xfffbbf24), size: 14),
                          SizedBox(width: 5),
                          Text(
                            "IKLAN SPONSOR BERHADIAH",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Countdown / Close Button
                    if (_countdown > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xff1e293b),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_rounded, color: Color(0xff94a3b8), size: 13),
                            const SizedBox(width: 4),
                            Text(
                              "${_countdown}s",
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xffcbd5e1),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                // Main 3D Sponsor Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xff1e293b).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xff064e3b),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xff10b981)),
                            ),
                            child: const Icon(Icons.show_chart_rounded, color: Color(0xff34d399), size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Trade Heroes PRO",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Analisis AI Saham & Prediksi Chart Realtime",
                                  style: TextStyle(
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

                      // Animated Chart Visual Canvas
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xff0f172a),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: AnimatedBuilder(
                          animation: _chartController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: AdChartPainter(_chartController.value),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 3D Action Button (Reward / Close)
                if (_countdown > 0)
                  Container(
                    width: double.infinity,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xff334155).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      "MENUTUP DALAM ${_countdown} DETIK...",
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff94a3b8),
                        letterSpacing: 0.8,
                      ),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff10b981),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    label: const Text(
                      "KLAIM HADIAH & TUTUP",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),
                // VIP Pass Promo Button
                GestureDetector(
                  onTap: () {
                    widget.onClose();
                    appState.upgradeToPremium(context);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.workspace_premium_rounded, color: Color(0xfff59e0b), size: 14),
                      SizedBox(width: 5),
                      Text(
                        "Ingin Bebas Iklan Selamanya? Upgrade VIP Gold 👑",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xfff59e0b),
                          decoration: TextDecoration.underline,
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
}

class AdChartPainter extends CustomPainter {
  final double animationValue;

  AdChartPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xff10b981)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xff10b981).withOpacity(0.15), const Color(0xff10b981).withOpacity(0.0)],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height * 0.8);

    // Create a wave path
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.7),
      Offset(size.width * 0.4, size.height * 0.85),
      Offset(size.width * 0.6, size.height * 0.4),
      Offset(size.width * 0.8, size.height * 0.5),
      Offset(size.width, size.height * 0.2),
    ];

    // Compute progress path based on animationValue
    final progressPath = Path();
    progressPath.moveTo(points[0].dx, points[0].dy);
    
    double currentLimitX = size.width * animationValue;
    
    for (int i = 1; i < points.length; i++) {
      if (points[i].dx <= currentLimitX) {
        progressPath.lineTo(points[i].dx, points[i].dy);
      } else {
        // Interpolate last point
        double ratio = (currentLimitX - points[i - 1].dx) / (points[i].dx - points[i - 1].dx);
        double interpY = points[i - 1].dy + (points[i].dy - points[i - 1].dy) * ratio;
        progressPath.lineTo(currentLimitX, interpY);
        break;
      }
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    for (double i = 0.2; i < 1.0; i += 0.2) {
      canvas.drawLine(Offset(0, size.height * i), Offset(size.width, size.height * i), gridPaint);
      canvas.drawLine(Offset(size.width * i, 0), Offset(size.width * i, size.height), gridPaint);
    }

    // Draw path fill
    final fillPath = Path.from(progressPath);
    fillPath.lineTo(currentLimitX, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Draw line path
    canvas.drawPath(progressPath, paint);

    // Draw glowing end dot
    if (animationValue > 0.05) {
      final dotPaint = Paint()
        ..color = const Color(0xff10b981)
        ..style = PaintingStyle.fill;
      final glowPaint = Paint()
        ..color = const Color(0xff10b981).withOpacity(0.4)
        ..style = PaintingStyle.fill;

      // Find current endpoint Y coordinate
      double endY = size.height * 0.8;
      for (int i = 1; i < points.length; i++) {
        if (points[i].dx >= currentLimitX) {
          double ratio = (currentLimitX - points[i - 1].dx) / (points[i].dx - points[i - 1].dx);
          endY = points[i - 1].dy + (points[i].dy - points[i - 1].dy) * ratio;
          break;
        }
      }

      canvas.drawCircle(Offset(currentLimitX, endY), 10, glowPaint);
      canvas.drawCircle(Offset(currentLimitX, endY), 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AdChartPainter oldDelegate) => true;
}
