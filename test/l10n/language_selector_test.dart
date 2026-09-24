import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kursus_saham/l10n/app_translations.dart';

void main() {
  group('Language widget rendering', () {
    testWidgets('renders Indonesian text for id locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('id'),
          home: Scaffold(
            body: Text(AppTranslations.text('id', 'settings.language')),
          ),
        ),
      );

      expect(find.text('Bahasa Aplikasi'), findsOneWidget);
    });

    testWidgets('renders English text for en locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Scaffold(
            body: Text(AppTranslations.text('en', 'settings.language')),
          ),
        ),
      );

      expect(find.text('App Language'), findsOneWidget);
    });

    testWidgets('simulates language switch in local state widget', (tester) async {
      String currentLang = 'id';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              locale: Locale(currentLang),
              home: Scaffold(
                appBar: AppBar(
                  title: Text(AppTranslations.text(currentLang, 'settings.language')),
                ),
                body: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentLang = 'en';
                    });
                  },
                  child: const Text('Switch to EN'),
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Bahasa Aplikasi'), findsOneWidget);

      await tester.tap(find.text('Switch to EN'));
      await tester.pumpAndSettle();

      expect(find.text('App Language'), findsOneWidget);
    });

    testWidgets('renders language selector dialog options and switches selection', (tester) async {
      String selected = 'id';

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(AppTranslations.text(selected, 'settings.language')),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: Text(AppTranslations.text(selected, 'settings.language_id')),
                              onTap: () {
                                setState(() => selected = 'id');
                                Navigator.pop(ctx);
                              },
                            ),
                            ListTile(
                              title: Text(AppTranslations.text(selected, 'settings.language_en')),
                              onTap: () {
                                setState(() => selected = 'en');
                                Navigator.pop(ctx);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Bahasa Aplikasi'), findsOneWidget);
      expect(find.text('Bahasa Indonesia'), findsOneWidget);
      expect(find.text('English (US)'), findsOneWidget);

      await tester.tap(find.text('English (US)'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(selected, 'en');
    });
  });
}
