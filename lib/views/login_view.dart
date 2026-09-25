import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_translations.dart';
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
    final language = appState.language;

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage =
            AppTranslations.text(language, 'auth.email_invalid');
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage =
            AppTranslations.text(language, 'auth.password_short');
      });
      return;
    }

    if (_isSignUpMode && name.isEmpty) {
      setState(() {
        _errorMessage =
            AppTranslations.text(language, 'auth.name_required');
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
            SnackBar(
              backgroundColor: const Color(0xff059669),
              content: Text(
                AppTranslations.text(language, 'auth.signup_success'),
              ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final language = appState.language;
    String tr(String key) => AppTranslations.text(language, key);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        key: const ValueKey('login-root-surface'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [
                    Color(0xff064e3b),
                    Color(0xff0b0f19),
                  ]
                : const [
                    Color(0xffecfdf5),
                    Color(0xfff1f5f9),
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
                  Text(
                    "TRADE HEROES",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xff0f172a),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Akademi Belajar Pasar Modal & Simulator Saham BEI",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
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
                            color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/google_logo.png',
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              tr('auth.google_action'),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff111827),
                              ),
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
                      Expanded(
                        child: Divider(
                          color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xffcbd5e1),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "atau akun email",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            color: isDark ? const Color(0xff64748b) : const Color(0xff94a3b8),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xffcbd5e1),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Tab Switcher (Masuk vs Daftar)
                  Container(
                    key: const ValueKey('login-mode-switcher'),
                    height: 42,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff1e293b) : const Color(0xffe2e8f0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xffcbd5e1),
                      ),
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
                                tr('auth.login_tab'),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: !_isSignUpMode
                                      ? Colors.white
                                      : (isDark ? const Color(0xff94a3b8) : const Color(0xff64748b)),
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
                                tr('auth.signup_tab'),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _isSignUpMode
                                      ? Colors.white
                                      : (isDark ? const Color(0xff94a3b8) : const Color(0xff64748b)),
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
                        color: isDark ? const Color(0xff450a0a) : const Color(0xfffef2f2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xffef4444) : const Color(0xfff87171),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: isDark ? const Color(0xfff87171) : const Color(0xffdc2626),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.5,
                                color: isDark ? const Color(0xfffca5a5) : const Color(0xffb91c1c),
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
                    key: const ValueKey('login-form-surface'),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff1e293b).withOpacity(0.65) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0),
                      ),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Column(
                      children: [
                        if (_isSignUpMode) ...[
                          TextField(
                            controller: _nameController,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: isDark ? Colors.white : const Color(0xff0f172a),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              labelText: tr('auth.name_label'),
                              labelStyle: TextStyle(
                                fontFamily: 'Inter',
                                color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                                fontSize: 12,
                              ),
                              prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xff10b981), size: 19),
                              filled: true,
                              fillColor: isDark ? const Color(0xff0f172a) : const Color(0xfff8fafc),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xffcbd5e1),
                                ),
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
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: isDark ? Colors.white : const Color(0xff0f172a),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            labelText: tr('auth.email_label'),
                            labelStyle: TextStyle(
                              fontFamily: 'Inter',
                              color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                              fontSize: 12,
                            ),
                            prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xff10b981), size: 19),
                            filled: true,
                            fillColor: isDark ? const Color(0xff0f172a) : const Color(0xfff8fafc),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xffcbd5e1),
                              ),
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
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: isDark ? Colors.white : const Color(0xff0f172a),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            labelText: tr('auth.password_label'),
                            labelStyle: TextStyle(
                              fontFamily: 'Inter',
                              color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                              fontSize: 12,
                            ),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xff10b981), size: 19),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: isDark ? const Color(0xff64748b) : const Color(0xff94a3b8),
                                size: 19,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xff0f172a) : const Color(0xfff8fafc),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xffcbd5e1),
                              ),
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
                                      _isSignUpMode
                                          ? tr('auth.signup_action').toUpperCase()
                                          : tr('auth.login_action').toUpperCase(),
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
                    label: Text(
                      tr('auth.guest_action'),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xffcbd5e1) : const Color(0xff475569),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
