import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'views/home_view.dart';
import 'views/login_view.dart';
import 'views/splash_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const KursusSahamApp(),
    ),
  );
}

class KursusSahamApp extends StatelessWidget {
  const KursusSahamApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Trade Heroes",
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff0f172a), // Duolingo Slate Dark
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xff3ec374), // Duolingo Green
          secondary: Color(0xff3f84c5), // Sky Blue
          surface: Color(0xff1e293b), // Slate Card
          background: Color(0xff0f172a),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white),
          titleMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white),
          headlineMedium: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white),
          bodyLarge: TextStyle(color: Color(0xfff1f5f9), fontSize: 15),
          bodyMedium: TextStyle(color: Color(0xff94a3b8), fontSize: 13),
        ),
      ),
      builder: (context, child) {
        return Container(
          color: const Color(0xff0b0f19),
          child: DeviceFrame(child: child ?? const SizedBox()),
        );
      },
      home: VideoSplashView(
        child: Consumer<AppState>(
          builder: (context, appState, child) {
            return appState.isLoggedIn ? const HomeView() : const LoginView();
          },
        ),
      ),
    );
  }
}

class DeviceFrame extends StatelessWidget {
  final Widget child;
  const DeviceFrame({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If the screen is small (like a real mobile phone screen), don't show the frame
        if (constraints.maxWidth < 600) {
          return child;
        }

        // Otherwise, show a beautiful premium iPhone mockup frame in the center
        return Scaffold(
          backgroundColor: const Color(0xff0b0f19), // Dark showcase background
          body: Stack(
            children: [
              // 1. Premium background radial gradient
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Color(0xff1e293b),
                        Color(0xff090d16),
                      ],
                      center: Alignment.center,
                      radius: 1.2,
                    ),
                  ),
                ),
              ),
              // 2. Centered Phone Mockup Container
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top description on desktop screen
                    const Text(
                      "TRADE HEROES MOBILE PREVIEW",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xff94a3b8),
                        letterSpacing: 3.0,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Phone frame outer shape
                    Container(
                      width: 390 + 24, // 390 screen width + 12px bezel on each side
                      height: 844 + 24, // 844 screen height + 12px bezel on top/bottom
                      decoration: BoxDecoration(
                        color: const Color(0xff090d16),
                        borderRadius: BorderRadius.circular(44), // Rounded outer bezel
                        border: Border.all(
                          color: const Color(0xff334155), // metallic rim highlight
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.65),
                            blurRadius: 36,
                            spreadRadius: 2,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0), // 10px thick bezel inner
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Main Screen content inside bezel
                            ClipRRect(
                              borderRadius: BorderRadius.circular(32), // Screen corner radius
                              child: MediaQuery(
                                // Override media query size to simulate mobile dimensions inside the frame
                                data: MediaQuery.of(context).copyWith(
                                  size: const Size(390, 844),
                                  padding: const EdgeInsets.only(top: 44, bottom: 34),
                                ),
                                child: SizedBox(
                                  width: 390,
                                  height: 844,
                                  child: child,
                                ),
                              ),
                            ),
                            // Simulated Phone Notch / Dynamic Island at the top
                            Positioned(
                              top: 14,
                              child: Container(
                                width: 110,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: const Color(0xff1e293b), width: 0.5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Camera lens simulation shine
                                    Container(
                                      margin: const EdgeInsets.only(right: 16),
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xff090d16),
                                        border: Border.all(color: const Color(0xff334155), width: 1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Bottom simulated iPhone Home Indicator bar
                            Positioned(
                              bottom: 8,
                              child: Container(
                                width: 134,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(2.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
