import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController(text: "trader.pemula@gmail.com");
  final TextEditingController _passwordController = TextEditingController(text: "12345678");
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _handleEmailLogin(AppState appState) {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan masukkan alamat email Anda")),
      );
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
        final name = email.contains('@') ? email.split('@')[0] : email;
        final capitalizedName = name[0].toUpperCase() + name.substring(1);
        appState.login(name: capitalizedName, email: email, avatar: "bull");
      }
    });
  }

  void _handleGoogleLogin(AppState appState) {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isLoading = false);
        appState.login(
          name: "Trader Google",
          email: "trader.google@gmail.com",
          avatar: "vip",
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xff0b0f19),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff064e3b),
              Color(0xff0b0f19),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. CLEAN OFFICIAL BRAND LOGO (NO BULKY DARK CIRCLE CONTAINER!)
                  Image.asset(
                    'assets/images/logo.png',
                    height: 84,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.trending_up_rounded, color: Color(0xff10b981), size: 72);
                    },
                  ),
                  const SizedBox(height: 14),

                  // App Title & Subtitle
                  const Text(
                    "TRADE HEROES",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Akademi Belajar Trading Saham & Bandarmologi #1",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: Color(0xff94a3b8),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // 2. AUTHENTIC 4-COLOR GOOGLE SIGN-IN BUTTON
                  InkWell(
                    onTap: _isLoading ? null : () => _handleGoogleLogin(appState),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Authentic 4-Color Google Logo Canvas
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CustomPaint(
                              painter: AuthenticGoogleLogoPainter(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Masuk dengan Google",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Elegant Divider Line
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.12), thickness: 1)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "atau dengan email",
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xff64748b)),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.12), thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Email Input Field
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: "Alamat Email",
                      labelStyle: const TextStyle(fontFamily: 'Inter', color: Color(0xff94a3b8), fontSize: 13),
                      prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xff10b981), size: 20),
                      filled: true,
                      fillColor: const Color(0xff1e293b).withOpacity(0.8),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xff10b981), width: 1.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Password Input Field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: "Kata Sandi",
                      labelStyle: const TextStyle(fontFamily: 'Inter', color: Color(0xff94a3b8), fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xff10b981), size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xff64748b),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: const Color(0xff1e293b).withOpacity(0.8),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xff10b981), width: 1.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. PRIMARY MASUK AKUN BUTTON (NO EMOJI!)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff059669),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    onPressed: _isLoading ? null : () => _handleEmailLogin(appState),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.login_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "MASUK AKUN",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 36),

                  // Minimal Version Footer
                  const Text(
                    "Trade Heroes v2.4.0 PRO • Privacy & Terms Supported",
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xff64748b)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Painter for Crisp 4-Color Official Google "G" Logo
class AuthenticGoogleLogoPainter extends CustomPainter {
  const AuthenticGoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double stroke = w * 0.22;
    final Rect rect = Rect.fromLTWH(stroke / 2, stroke / 2, w - stroke, h - stroke);

    final Paint redPaint = Paint()
      ..color = const Color(0xffea4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    final Paint yellowPaint = Paint()
      ..color = const Color(0xfffbbc05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    final Paint greenPaint = Paint()
      ..color = const Color(0xff34a853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    final Paint bluePaint = Paint()
      ..color = const Color(0xff4285f4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Draw Google 4-Color Ring Segments
    canvas.drawArc(rect, -2.2, 1.5, false, redPaint);
    canvas.drawArc(rect, -3.7, 1.5, false, yellowPaint);
    canvas.drawArc(rect, 0.7, 1.4, false, greenPaint);
    canvas.drawArc(rect, -0.7, 1.4, false, bluePaint);

    // Draw Blue Center Bar
    final Paint blueFill = Paint()..color = const Color(0xff4285f4)..style = PaintingStyle.fill;
    final Rect barRect = Rect.fromLTWH(w * 0.45, h * 0.40, w * 0.48, stroke * 0.9);
    canvas.drawRect(barRect, blueFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
