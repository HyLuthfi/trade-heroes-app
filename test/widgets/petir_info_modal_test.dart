import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kursus_saham/state/app_state.dart';
import 'package:kursus_saham/widgets/petir_info_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppState appState;

  setUp(() {
    SharedPreferences.setMockInitialValues({'app_language': 'id'});
    appState = AppState();
  });

  tearDown(() {
    appState.dispose();
  });

  Widget buildTestApp({
    required Widget child,
    ThemeMode themeMode = ThemeMode.dark,
    String language = 'id',
  }) {
    appState.setLanguage(language);
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MaterialApp(
        themeMode: themeMode,
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xfff8fafc),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xff0b0f19),
        ),
        home: Scaffold(body: child),
      ),
    );
  }

  group('Petir Overflow & PetirInfoModal Tests', () {
    test('AppState handles petir overflow up to 15 correctly', () {
      // Daily claim with petir adds and clamps up to 15
      appState.claimDailyReward(1, xpReward: 10, petirReward: 8);
      expect(appState.petir, greaterThan(5));
      expect(appState.petir, lessThanOrEqualTo(15));

      // Fraction should be 1.0 when >= 5
      expect(appState.getPetirRegenFraction(), equals(1.0));

      // Deducting decreases petir
      final initialPetir = appState.petir;
      appState.deductPetir();
      expect(appState.petir, equals(initialPetir - 1));
    });

    test('Option A 5-minute petir recovery countdown and fraction', () {
      // Drain petir below 5
      while (appState.petir >= 5) {
        appState.deductPetir();
      }
      expect(appState.petir, equals(4));

      // Initial countdown should start near 5 minutes (e.g., 5m 00s or 4m 59s)
      final timeStr = appState.getPetirRegenTime();
      expect(timeStr, contains('m'));
      expect(timeStr, contains('s'));

      // Fraction should be between 0.0 and 1.0
      final fraction = appState.getPetirRegenFraction();
      expect(fraction, greaterThanOrEqualTo(0.0));
      expect(fraction, lessThan(1.0));
    });

    testWidgets('Renders PetirInfoModal correctly in Dark Mode (Indonesian)', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const PetirInfoModal(),
          themeMode: ThemeMode.dark,
          language: 'id',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('STATUS NYAWA PETIR'), findsOneWidget);
      expect(find.text('Jaminan Belajar Bebas Khawatir'), findsOneWidget);
      expect(find.text('TUTUP'), findsOneWidget);
    });

    testWidgets('Renders PetirInfoModal correctly in Light Mode (English)', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const PetirInfoModal(),
          themeMode: ThemeMode.light,
          language: 'en',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('LIGHTNING LIVES STATUS'), findsOneWidget);
      expect(find.text('Worry-Free Learning Guarantee'), findsOneWidget);
      expect(find.text('CLOSE'), findsOneWidget);
    });
  });
}
