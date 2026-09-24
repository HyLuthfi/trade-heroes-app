import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kursus_saham/l10n/app_translations.dart';
import 'package:kursus_saham/services/audio_service.dart';
import 'package:kursus_saham/state/app_state.dart';
import 'package:kursus_saham/widgets/ad_overlay.dart';
import 'package:kursus_saham/widgets/live_voice_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppState appState;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appState = AppState();
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

  group('LiveVoiceModal Tests', () {
    testWidgets('Renders LiveVoiceModal correctly in Dark Mode (Indonesian)', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const LiveVoiceModal(
            stock: {
              'ticker': 'BBCA',
              'name': 'Bank Central Asia',
              'price': 10250,
            },
          ),
          themeMode: ThemeMode.dark,
          language: 'id',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Live Voice Analyst'), findsOneWidget);
      expect(find.textContaining('BBCA'), findsWidgets);
      expect(find.byIcon(Icons.mic_rounded), findsWidgets);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('Renders LiveVoiceModal correctly in Light Mode (English)', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const LiveVoiceModal(
            stock: {
              'ticker': 'TLKM',
              'name': 'Telkom Indonesia',
              'price': 3800,
            },
          ),
          themeMode: ThemeMode.light,
          language: 'en',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Live Voice Analyst'), findsOneWidget);
      expect(find.textContaining('TLKM'), findsWidgets);
      expect(find.byIcon(Icons.mic_rounded), findsWidgets);
    });

    testWidgets('LiveVoiceModal handles BGM ducking on mount and dispose', (tester) async {
      // Simulate BGM was already playing
      AudioService.startBgm();
      expect(AudioService.isBgmPlaying, isTrue);

      await tester.pumpWidget(
        buildTestApp(
          child: const LiveVoiceModal(
            stock: {'ticker': 'BBRI'},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // BGM must be stopped/ducked during live voice
      expect(AudioService.isBgmPlaying, isFalse);

      // Rebuild with different child to trigger dispose
      await tester.pumpWidget(
        buildTestApp(
          child: const Text('Disposed Screen'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // BGM must be restored
      expect(AudioService.isBgmPlaying, isTrue);
      AudioService.stopBgm();
    });
  });

  group('AdOverlay Tests', () {
    testWidgets('Renders AdOverlay with bilingual countdown badge and elements', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: AdOverlay(
            onClose: () {},
          ),
          language: 'id',
        ),
      );
      await tester.pump();

      expect(find.text(AppTranslations.text('id', 'ad.badge')), findsOneWidget);
      expect(find.textContaining(AppTranslations.text('id', 'ad.vip_upgrade_prompt')), findsOneWidget);
    });

    testWidgets('Renders AdOverlay in English locale properly', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: AdOverlay(
            onClose: () {},
          ),
          language: 'en',
        ),
      );
      await tester.pump();

      expect(find.text(AppTranslations.text('en', 'ad.badge')), findsOneWidget);
      expect(find.textContaining(AppTranslations.text('en', 'ad.vip_upgrade_prompt')), findsOneWidget);
    });
  });

  group('Bilingual Market Chips & News Localization Check', () {
    test('All 7 AI prompt chips resolve in ID and EN', () {
      final chipKeys = [
        'market.chip_prospects',
        'market.chip_snr',
        'market.chip_smc',
        'market.chip_momentum',
        'market.chip_valuation',
        'market.chip_entry_exit',
        'market.chip_beginner_tips',
      ];

      for (final key in chipKeys) {
        final idText = AppTranslations.text('id', key);
        final enText = AppTranslations.text('en', key);

        expect(idText, isNotEmpty, reason: '$key missing in ID');
        expect(enText, isNotEmpty, reason: '$key missing in EN');
        expect(idText != key, isTrue, reason: '$key not localized in ID');
        expect(enText != key, isTrue, reason: '$key not localized in EN');
      }
    });

    test('All 5 News categories and action labels resolve in ID and EN', () {
      final newsKeys = [
        'market.news_cat_all',
        'market.news_cat_dividend',
        'market.news_cat_corporate',
        'market.news_cat_sentiment',
        'market.news_cat_analysis',
        'market.news_btn_read',
        'market.news_btn_analyze',
      ];

      for (final key in newsKeys) {
        final idText = AppTranslations.text('id', key);
        final enText = AppTranslations.text('en', key);

        expect(idText, isNotEmpty, reason: '$key missing in ID');
        expect(enText, isNotEmpty, reason: '$key missing in EN');
      }
    });
  });
}
