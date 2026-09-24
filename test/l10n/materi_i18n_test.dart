import 'package:flutter_test/flutter_test.dart';
import 'package:kursus_saham/data/materi_data.dart';
import 'package:kursus_saham/l10n/app_translations.dart';

void main() {
  group('MateriData Bilingual Content Parity', () {
    test('Modules have matching counts, IDs, and valid bilingual fields', () {
      final idModules = MateriData.getModules('id');
      final enModules = MateriData.getModules('en');

      expect(idModules.length, 6);
      expect(enModules.length, 6);

      for (int i = 0; i < idModules.length; i++) {
        final idMod = idModules[i];
        final enMod = enModules[i];

        // IDs must match for state preservation
        expect(enMod['id'], idMod['id']);
        expect(enMod['xp'], idMod['xp']);
        expect(enMod['isPremium'], idMod['isPremium']);

        // Titles must be non-empty and translated
        expect((idMod['title'] as String).isNotEmpty, isTrue);
        expect((enMod['title'] as String).isNotEmpty, isTrue);
        expect(enMod['title'], isNot(idMod['title']));

        // Descriptions must be translated
        expect(enMod['desc'], isNot(idMod['desc']));

        // Content HTML must be translated
        expect(enMod['content'], isNot(idMod['content']));

        // Key takeaways count must match and be translated
        final idTakeaways = idMod['takeaways'] as List<String>;
        final enTakeaways = enMod['takeaways'] as List<String>;
        expect(enTakeaways.length, idTakeaways.length);
        for (int t = 0; t < idTakeaways.length; t++) {
          expect(enTakeaways[t], isNot(idTakeaways[t]));
        }
      }
    });

    test('Trading tips have matching counts, IDs, and valid bilingual fields', () {
      final idTips = MateriData.getTradingTips('id');
      final enTips = MateriData.getTradingTips('en');

      expect(idTips.length, 4);
      expect(enTips.length, 4);

      for (int i = 0; i < idTips.length; i++) {
        final idTip = idTips[i];
        final enTip = enTips[i];

        expect(enTip['id'], idTip['id']);
        expect(enTip['isPdf'], idTip['isPdf']);
        expect(enTip['isPremium'], idTip['isPremium']);

        expect(enTip['title'], isNot(idTip['title']));
        expect(enTip['desc'], isNot(idTip['desc']));
        expect(enTip['content'], isNot(idTip['content']));
      }
    });

    test('Glossary terms have matching counts and valid bilingual definitions', () {
      final idGlossary = MateriData.getGlossary('id');
      final enGlossary = MateriData.getGlossary('en');

      expect(idGlossary.length, 10);
      expect(enGlossary.length, 10);

      for (int i = 0; i < idGlossary.length; i++) {
        final idItem = idGlossary[i];
        final enItem = enGlossary[i];

        expect((enItem['term'] as String).isNotEmpty, isTrue);
        expect((idItem['term'] as String).isNotEmpty, isTrue);

        expect(enItem['def'], isNot(idItem['def']));
        expect(enItem['example'], isNot(idItem['example']));
      }
    });

    test('Materi UI keys resolve in Indonesian and English', () {
      const keys = <String>[
        'materi.tab_modules',
        'materi.tab_favorites',
        'materi.tab_tips',
        'materi.tab_glossary',
        'materi.read_now',
        'materi.locked',
        'materi.read_completed',
        'materi.premium_badge',
        'materi.summary_title',
        'materi.finish_reading',
        'materi.search_glossary_hint',
        'materi.no_favorites_title',
        'materi.no_favorites_desc',
        'materi.tip_unlock',
        'materi.tip_download_pdf',
        'materi.tip_read_tips',
        'materi.glossary_not_found',
        'materi.glossary_example',
        'materi.glossary_example_format',
        'materi.pronounce_snack',
        'materi.pdf_sim_title',
        'materi.pdf_sim_desc',
        'materi.pdf_sim_ok',
        'materi.pdf_saved',
        'materi.pdf_failed',
      ];

      for (final key in keys) {
        expect(AppTranslations.text('id', key), isNot(key), reason: 'Missing ID: $key');
        expect(AppTranslations.text('en', key), isNot(key), reason: 'Missing EN: $key');
      }

      expect(AppTranslations.text('en', 'materi.tip_unlock'), 'UNLOCK');
      expect(AppTranslations.text('en', 'materi.tip_download_pdf'), 'DOWNLOAD PDF');
      expect(AppTranslations.text('en', 'materi.tip_read_tips'), 'READ TIPS');
      expect(AppTranslations.text('en', 'materi.glossary_not_found'), 'No financial terms found.');
    });
  });
}
