import 'package:flutter_test/flutter_test.dart';
import 'package:kursus_saham/data/kuis_data.dart';

void main() {
  group('KuisData Bilingual Parity Tests', () {
    test('Both ID and EN datasets have 10 levels with 3 questions each', () {
      final idLevels = KuisData.getLevelData('id');
      final enLevels = KuisData.getLevelData('en');

      expect(idLevels.length, 10);
      expect(enLevels.length, 10);

      for (int i = 0; i < 10; i++) {
        final idL = idLevels[i];
        final enL = enLevels[i];

        expect(idL['id'], enL['id'], reason: 'Level $i id parity');
        expect(idL['id'], i + 1);
        expect(idL['zone'], enL['zone'], reason: 'Level $i zone parity');
        expect(idL['xFactor'], enL['xFactor']);
        expect(idL['y'], enL['y']);
        expect(idL['icon'], enL['icon']);

        // Titles and descriptions must be translated and non-empty
        expect((idL['title'] as String).isNotEmpty, true);
        expect((enL['title'] as String).isNotEmpty, true);
        expect((idL['desc'] as String).isNotEmpty, true);
        expect((enL['desc'] as String).isNotEmpty, true);

        final idQList = idL['questions'] as List;
        final enQList = enL['questions'] as List;

        expect(idQList.length, 3, reason: 'Level $i has 3 questions');
        expect(enQList.length, 3, reason: 'Level $i EN has 3 questions');

        for (int q = 0; q < 3; q++) {
          final idQ = idQList[q] as Map<String, dynamic>;
          final enQ = enQList[q] as Map<String, dynamic>;

          expect(idQ['type'], enQ['type'], reason: 'Q$q type parity');
          expect((idQ['q'] as String).isNotEmpty, true);
          expect((enQ['q'] as String).isNotEmpty, true);
          expect((idQ['explanation'] as String).isNotEmpty, true);
          expect((enQ['explanation'] as String).isNotEmpty, true);

          if (idQ['type'] == 'pilgan') {
            final idOpts = idQ['options'] as List;
            final enOpts = enQ['options'] as List;
            expect(idOpts.length, 4);
            expect(enOpts.length, 4);
            expect(idQ['a'], enQ['a'], reason: 'Answer index parity');
            expect(idQ['a'] as int >= 0 && (idQ['a'] as int) < 4, true);
          } else {
            expect(idQ['a'] is String, true);
            expect(enQ['a'] is String, true);
            expect((idQ['a'] as String).isNotEmpty, true);
            expect((enQ['a'] as String).isNotEmpty, true);
          }
        }
      }
    });
  });
}
