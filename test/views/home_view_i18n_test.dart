// Widget tests for HomeView i18n are blocked on this platform because
// lib/services/audio_service.dart imports dart:js_interop (Web-only), which
// prevents AppState from being constructed in the Dart VM test runner.
//
// Pure dictionary coverage for HomeView navigation labels is already
// provided by test/l10n/app_translations_test.dart which is runnable.
//
// Documented blocker:
//   Dart library 'dart:js_interop' is not available on this platform.
//
// To unblock: guard AudioService JS interop behind kIsWeb in a future phase.
// Do not modify audio_service.dart as part of i18n Phase 2.
//
// The tests below are pure translation-lookup tests that do NOT construct
// AppState or any Flutter widget, so they run on the Dart VM without issue.

import 'package:flutter_test/flutter_test.dart';
import 'package:kursus_saham/l10n/app_translations.dart';

void main() {
  group('HomeView i18n — nav labels', () {
    test('ID locale: four nav labels correct', () {
      expect(AppTranslations.text('id', 'home.nav_quiz'), 'Kuis');
      expect(AppTranslations.text('id', 'home.nav_market'), 'Market');
      expect(AppTranslations.text('id', 'home.nav_materi'), 'Materi');
      expect(AppTranslations.text('id', 'home.nav_profile'), 'Saya');
    });

    test('EN locale: four nav labels correct', () {
      expect(AppTranslations.text('en', 'home.nav_quiz'), 'Quiz');
      expect(AppTranslations.text('en', 'home.nav_market'), 'Market');
      expect(AppTranslations.text('en', 'home.nav_materi'), 'Academy');
      expect(AppTranslations.text('en', 'home.nav_profile'), 'Profile');
    });

    test('ID locale: dynamic app titles correct', () {
      expect(AppTranslations.text('id', 'home.title_market'), 'Live Market');
      expect(
        AppTranslations.text('id', 'home.title_materi'),
        'Materi Belajar',
      );
      expect(AppTranslations.text('id', 'home.title_profile'), 'Profil Anda');
    });

    test('EN locale: dynamic app titles correct', () {
      expect(AppTranslations.text('en', 'home.title_market'), 'Live Market');
      expect(
        AppTranslations.text('en', 'home.title_materi'),
        'Learning Academy',
      );
      expect(AppTranslations.text('en', 'home.title_profile'), 'Your Profile');
    });

    test('ID locale: tooltip messages correct', () {
      expect(
        AppTranslations.text('id', 'home.tooltip_premium_lives'),
        'Nyawa tak terbatas',
      );
      expect(
        AppTranslations.text('id', 'home.tooltip_lives'),
        'Nyawa petir Anda',
      );
      expect(
        AppTranslations.text('id', 'home.tooltip_total_xp'),
        'Total XP Terkumpul',
      );
    });

    test('EN locale: tooltip messages correct', () {
      expect(
        AppTranslations.text('en', 'home.tooltip_premium_lives'),
        'Unlimited lives',
      );
      expect(
        AppTranslations.text('en', 'home.tooltip_lives'),
        'Your lightning lives',
      );
      expect(
        AppTranslations.text('en', 'home.tooltip_total_xp'),
        'Total XP earned',
      );
    });
  });
}
