import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kursus_saham/data/avatar_data.dart';

void main() {
  group('AvatarData Integrity & Parity Tests', () {
    test('Contains exactly 12 defined avatar characters', () {
      expect(AvatarData.avatars.length, 12);
    });

    test('All avatars have distinct IDs, non-empty titles and descriptions in ID and EN', () {
      final ids = <String>{};

      for (final a in AvatarData.avatars) {
        expect(ids.contains(a.id), isFalse, reason: 'Duplicate ID: ${a.id}');
        ids.add(a.id);

        expect(a.titleId.trim(), isNotEmpty);
        expect(a.titleEn.trim(), isNotEmpty);
        expect(a.descId.trim(), isNotEmpty);
        expect(a.descEn.trim(), isNotEmpty);
        expect(a.icon, isNotNull);
        expect(a.color, isNotNull);
      }
    });

    test('AvatarData.getIcon and AvatarData.getColor match each avatar exactly', () {
      for (final a in AvatarData.avatars) {
        expect(AvatarData.getIcon(a.id), equals(a.icon), reason: 'Icon mismatch for ${a.id}');
        expect(AvatarData.getColor(a.id), equals(a.color), reason: 'Color mismatch for ${a.id}');
      }
    });

    test('Custom photo URL or base64 data returns default emerald theme color', () {
      expect(
        AvatarData.getColor('https://example.com/avatar.png'),
        equals(const Color(0xff10b981)),
      );
      expect(
        AvatarData.getColor('data:image/png;base64,iVBORw0KGgoAAAANSUhEUg=='),
        equals(const Color(0xff10b981)),
      );
    });

    test('Unknown avatar ID falls back safely to bull icon and color without throwing', () {
      expect(AvatarData.getIcon('unknown_id_xyz'), equals(Icons.trending_up_rounded));
      expect(AvatarData.getColor('unknown_id_xyz'), equals(const Color(0xff10b981)));
    });
  });
}
