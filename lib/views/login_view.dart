import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _isSignUpMode = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin(AppState appState) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await appState.signInWithGoogle();
    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        setState(() {
          _errorMessage = error;
        });
      }
    }
  }

  Future<void> _handleSubmit(AppState appState) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = "Silakan masukkan alamat email yang valid.";
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = "Kata sandi minimal harus 6 karakter.";
      });
      return;
    }

    if (_isSignUpMode && name.isEmpty) {
      setState(() {
        _errorMessage = "Silakan masukkan nama lengkap atau panggilan Anda.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_isSignUpMode) {
      final error = await appState.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        if (error != null) {
          setState(() {
            _errorMessage = error;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xff059669),
              content: Text("Akun berhasil didaftarkan! Selamat datang di Trade Heroes."),
            ),
          );
        }
      }
    } else {
      final error = await appState.signInWithEmail(
        email: email,
        password: password,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        if (error != null) {
          setState(() {
            _errorMessage = error;
          });
        }
      }
    }
  }

  void _handleGuestLogin(AppState appState) {
    appState.loginAsGuest();
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Brand Logo
                  Image.asset(
                    'assets/images/logo.png',
                    height: 76,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.trending_up_rounded, color: Color(0xff10b981), size: 64);
                    },
                  ),
                  const SizedBox(height: 10),

                  // App Title & Subtitle
                  const Text(
                    "TRADE HEROES",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Akademi Belajar Pasar Modal & Simulator Saham BEI",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xff94a3b8),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1. Google Sign-In Button
                  InkWell(
                    onTap: _isLoading ? null : () => _handleGoogleLogin(appState),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CustomPaint(
                              painter: AuthenticGoogleLogoPainter(),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Lanjutkan dengan Google",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.12), thickness: 1)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "atau akun email",
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xff64748b)),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.12), thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Tab Switcher (Masuk vs Daftar)
                  Container(
                    height: 42,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xff1e293b),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSignUpMode = false;
                                _errorMessage = null;
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: !_isSignUpMode ? const Color(0xff059669) : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                "Masuk",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: !_isSignUpMode ? Colors.white : const Color(0xff94a3b8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSignUpMode = true;
                                _errorMessage = null;
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _isSignUpMode ? const Color(0xff059669) : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                "Daftar Baru",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _isSignUpMode ? Colors.white : const Color(0xff94a3b8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Error Message Banner
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xff450a0a),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffef4444)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xfff87171), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.5,
                                color: Color(0xfffca5a5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xff1e293b).withOpacity(0.65),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      children: [
                        if (_isSignUpMode) ...[
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: "Nama Lengkap / Panggilan",
                              labelStyle: const TextStyle(fontFamily: 'Inter', color: Color(0xff94a3b8), fontSize: 12),
                              prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xff10b981), size: 19),
                              filled: true,
                              fillColor: const Color(0xff0f172a),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xff10b981), width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Email Field
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: "Alamat Email",
                            labelStyle: const TextStyle(fontFamily: 'Inter', color: Color(0xff94a3b8), fontSize: 12),
                            prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xff10b981), size: 19),
                            filled: true,
                            fillColor: const Color(0xff0f172a),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xff10b981), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Password Field
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: "Kata Sandi",
                            labelStyle: const TextStyle(fontFamily: 'Inter', color: Color(0xff94a3b8), fontSize: 12),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xff10b981), size: 19),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: const Color(0xff64748b),
                                size: 19,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: const Color(0xff0f172a),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xff10b981), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Action Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff059669),
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 3,
                          ),
                          onPressed: _isLoading ? null : () => _handleSubmit(appState),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isSignUpMode ? Icons.person_add_rounded : Icons.login_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isSignUpMode ? "DAFTAR SEKARANG" : "MASUK KE AKUN",
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Guest Mode (Coba Langsung)
                  TextButton.icon(
                    onPressed: () => _handleGuestLogin(appState),
                    icon: const Icon(Icons.flash_on_rounded, color: Color(0xfff59e0b), size: 16),
                    label: const Text(
                      "Coba dulu tanpa akun (Mode Tamu)",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xffcbd5e1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Cloud Integration Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xff1e293b),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.cloud_done_rounded, color: Color(0xff10b981), size: 13),
                        SizedBox(width: 5),
                        Text(
                          "Didukung oleh Supabase Cloud Sync",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            color: Color(0xff94a3b8),
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
