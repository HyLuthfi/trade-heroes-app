import 'package:flutter_test/flutter_test.dart';
import 'package:kursus_saham/l10n/id.dart';
import 'package:kursus_saham/l10n/en.dart';
import 'package:kursus_saham/l10n/app_translations.dart';

void main() {
  group('Feature Module Localization Parity Tests', () {
    final expectedPrefixes = [
      'rank.',
      'xp_reward.',
      'leaderboard.',
      'live_voice.',
      'market.ai_',
      'market.chip_',
      'market.news_',
      'ad.',
      'kuis.review_',
      'kuis.refill_',
    ];

    test('All feature prefixes exist in both ID and EN dictionaries', () {
      for (final prefix in expectedPrefixes) {
        final idMatching = idTranslations.keys.where((k) => k.startsWith(prefix)).toList();
        final enMatching = enTranslations.keys.where((k) => k.startsWith(prefix)).toList();

        expect(idMatching.isNotEmpty, isTrue, reason: 'ID dictionary missing prefix: $prefix');
        expect(enMatching.isNotEmpty, isTrue, reason: 'EN dictionary missing prefix: $prefix');
        expect(idMatching.length, equals(enMatching.length),
            reason: 'Key count mismatch for prefix $prefix: ID=${idMatching.length} vs EN=${enMatching.length}');
      }
    });

    test('100% key parity for all feature keys between ID and EN', () {
      final allFeatureKeys = idTranslations.keys
          .where((k) => expectedPrefixes.any((p) => k.startsWith(p)))
          .toSet();

      expect(allFeatureKeys.length, greaterThanOrEqualTo(110),
          reason: 'Expected at least 110 feature keys');

      for (final key in allFeatureKeys) {
        expect(idTranslations.containsKey(key), isTrue, reason: 'Key $key missing from ID');
        expect(enTranslations.containsKey(key), isTrue, reason: 'Key $key missing from EN');

        final idVal = idTranslations[key]!;
        final enVal = enTranslations[key]!;

        expect(idVal.trim().isNotEmpty, isTrue, reason: 'Key $key has empty value in ID');
        expect(enVal.trim().isNotEmpty, isTrue, reason: 'Key $key has empty value in EN');

        // Verify named parameter consistency
        final paramRegex = RegExp(r'\{([a-zA-Z0-9_]+)\}');
        final idParams = paramRegex.allMatches(idVal).map((m) => m.group(1)).toSet();
        final enParams = paramRegex.allMatches(enVal).map((m) => m.group(1)).toSet();

        expect(idParams, equals(enParams),
            reason: 'Parameter mismatch for key $key: ID=$idParams vs EN=$enParams');
      }
    });

    test('Full dictionary mutual parity (excluding deliberate probe key)', () {
      final idKeys = idTranslations.keys.toSet();
      final enKeys = enTranslations.keys.toSet();

      // settings.language_fallback_probe is intentionally in ID only for fallback unit tests
      final missingInEn = idKeys.difference(enKeys).where((k) => k != 'settings.language_fallback_probe').toSet();
      final missingInId = enKeys.difference(idKeys).toSet();

      expect(missingInEn, isEmpty, reason: 'Keys present in ID but missing in EN: $missingInEn');
      expect(missingInId, isEmpty, reason: 'Keys present in EN but missing in ID: $missingInId');
    });

    test('AppTranslations resolves sample feature keys correctly in both locales', () {
      expect(AppTranslations.text('id', 'rank.title'), equals('Jenjang Karier'));
      expect(AppTranslations.text('en', 'rank.title'), equals('Career Progression'));

      expect(AppTranslations.text('id', 'xp_reward.title'), equals('Jalur Hadiah XP'));
      expect(AppTranslations.text('en', 'xp_reward.title'), equals('XP Reward Path'));

      expect(AppTranslations.text('id', 'leaderboard.title'), equals('Liga Trader BEI'));
      expect(AppTranslations.text('en', 'leaderboard.title'), equals('IDX Trader League'));

      expect(AppTranslations.text('id', 'live_voice.title'), equals('Live Voice Analyst'));
      expect(AppTranslations.text('en', 'live_voice.title'), equals('Live Voice Analyst'));

      expect(AppTranslations.text('id', 'kuis.review_start'), equals('ULANG LATIHAN'));
      expect(AppTranslations.text('en', 'kuis.review_start'), equals('REVIEW QUIZ'));
    });
  });
}
