// Widget tests for LoginView i18n are blocked on this platform because
// lib/services/audio_service.dart imports dart:js_interop (Web-only), which
// prevents AppState from being constructed in the Dart VM test runner.
//
// Documented blocker:
//   Dart library 'dart:js_interop' is not available on this platform.
//
// To unblock: guard AudioService JS interop behind kIsWeb in a future phase.
// Do not modify audio_service.dart as part of i18n Phase 2.
//
// The tests below are pure translation-lookup tests that verify all auth
// labels and validation messages are correctly mapped for both locales.

import 'package:flutter_test/flutter_test.dart';
import 'package:kursus_saham/l10n/app_translations.dart';

void main() {
  group('LoginView i18n — tab and field labels', () {
    test('ID locale: tab labels correct', () {
      expect(AppTranslations.text('id', 'auth.login_tab'), 'Masuk');
      expect(AppTranslations.text('id', 'auth.signup_tab'), 'Daftar');
    });

    test('EN locale: tab labels correct', () {
      expect(AppTranslations.text('en', 'auth.login_tab'), 'Log In');
      expect(AppTranslations.text('en', 'auth.signup_tab'), 'Sign Up');
    });

    test('ID locale: field labels correct', () {
      expect(AppTranslations.text('id', 'auth.email_label'), 'Alamat Email');
      expect(AppTranslations.text('id', 'auth.password_label'), 'Kata Sandi');
      expect(
        AppTranslations.text('id', 'auth.name_label'),
        'Nama Lengkap / Nama Panggilan',
      );
    });

    test('EN locale: field labels correct', () {
      expect(
        AppTranslations.text('en', 'auth.email_label'),
        'Email Address',
      );
      expect(AppTranslations.text('en', 'auth.password_label'), 'Password');
      expect(
        AppTranslations.text('en', 'auth.name_label'),
        'Full Name / Nickname',
      );
    });

    test('ID locale: action labels correct', () {
      expect(AppTranslations.text('id', 'auth.login_action'), 'Masuk ke Akun');
      expect(AppTranslations.text('id', 'auth.signup_action'), 'Buat Akun');
      expect(
        AppTranslations.text('id', 'auth.google_action'),
        'Lanjutkan dengan Google',
      );
      expect(
        AppTranslations.text('id', 'auth.guest_action'),
        'Masuk sebagai Tamu',
      );
    });

    test('EN locale: action labels correct', () {
      expect(AppTranslations.text('en', 'auth.login_action'), 'Log In');
      expect(
        AppTranslations.text('en', 'auth.signup_action'),
        'Create Account',
      );
      expect(
        AppTranslations.text('en', 'auth.google_action'),
        'Continue with Google',
      );
      expect(
        AppTranslations.text('en', 'auth.guest_action'),
        'Continue as Guest',
      );
    });
  });

  group('LoginView i18n — validation messages', () {
    test('ID locale: empty/invalid email uses locale-specific message', () {
      expect(
        AppTranslations.text('id', 'auth.email_invalid'),
        'Silakan masukkan alamat email yang valid.',
      );
    });

    test('EN locale: empty/invalid email uses locale-specific message', () {
      expect(
        AppTranslations.text('en', 'auth.email_invalid'),
        'Please enter a valid email address.',
      );
    });

    test('ID locale: short password uses locale-specific message', () {
      expect(
        AppTranslations.text('id', 'auth.password_short'),
        'Kata sandi minimal harus 6 karakter.',
      );
    });

    test('EN locale: short password uses locale-specific message', () {
      expect(
        AppTranslations.text('en', 'auth.password_short'),
        'Password must be at least 6 characters.',
      );
    });

    test('ID locale: empty name uses locale-specific message', () {
      expect(
        AppTranslations.text('id', 'auth.name_required'),
        'Silakan masukkan nama lengkap atau panggilan Anda.',
      );
    });

    test('EN locale: empty name uses locale-specific message', () {
      expect(
        AppTranslations.text('en', 'auth.name_required'),
        'Please enter your full name or nickname.',
      );
    });

    test('ID locale: signup success message correct', () {
      expect(
        AppTranslations.text('id', 'auth.signup_success'),
        'Akun berhasil didaftarkan! Selamat datang di Trade Heroes.',
      );
    });

    test('EN locale: signup success message correct', () {
      expect(
        AppTranslations.text('en', 'auth.signup_success'),
        'Account created! Welcome to Trade Heroes.',
      );
    });
  });
}
