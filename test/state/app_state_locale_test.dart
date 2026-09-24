import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:kursus_saham/l10n/locale_resolver.dart';

void main() {
  group('LocaleResolver', () {
    test('saved app_language = en -> en', () {
      final locale = resolveInitialLocale(
        savedLanguage: 'en',
        deviceLocales: const [Locale('id', 'ID')],
      );
      expect(locale.languageCode, 'en');
    });

    test('saved app_language = EN or en_US -> en', () {
      final localeUpper = resolveInitialLocale(
        savedLanguage: 'EN',
        deviceLocales: const [Locale('id', 'ID')],
      );
      expect(localeUpper.languageCode, 'en');

      final localeRegional = resolveInitialLocale(
        savedLanguage: 'en_US',
        deviceLocales: const [Locale('id', 'ID')],
      );
      expect(localeRegional.languageCode, 'en');

      final localeHyphen = resolveInitialLocale(
        savedLanguage: 'en-GB',
        deviceLocales: const [Locale('id', 'ID')],
      );
      expect(localeHyphen.languageCode, 'en');
    });

    test('empty string or empty deviceLocales falls back safely', () {
      final localeEmpty = resolveLanguageCode(
        savedLanguage: '',
        deviceLocales: const [],
      );
      expect(localeEmpty, 'id');

      final localeNullEmpty = resolveLanguageCode(
        savedLanguage: null,
        deviceLocales: const [],
      );
      expect(localeNullEmpty, 'id');
    });

    test('saved app_language = unsupported value -> device match or id', () {
      final localeWithDeviceMatch = resolveInitialLocale(
        savedLanguage: 'fr',
        deviceLocales: const [Locale('en', 'US')],
      );
      expect(localeWithDeviceMatch.languageCode, 'en');

      final localeWithoutDeviceMatch = resolveInitialLocale(
        savedLanguage: 'fr',
        deviceLocales: const [Locale('ja', 'JP')],
      );
      expect(localeWithoutDeviceMatch.languageCode, 'id');
    });

    test('no saved value + device en_US -> en', () {
      final locale = resolveInitialLocale(
        savedLanguage: null,
        deviceLocales: const [Locale('en', 'US')],
      );
      expect(locale.languageCode, 'en');
    });

    test('no saved value + device id_ID -> id', () {
      final locale = resolveInitialLocale(
        savedLanguage: null,
        deviceLocales: const [Locale('id', 'ID')],
      );
      expect(locale.languageCode, 'id');
    });

    test('no saved value + unsupported device locale -> id', () {
      final locale = resolveInitialLocale(
        savedLanguage: null,
        deviceLocales: const [Locale('de', 'DE')],
      );
      expect(locale.languageCode, 'id');
    });
  });
}
