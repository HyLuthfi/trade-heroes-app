import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kursus_saham/main.dart';
import 'package:kursus_saham/state/app_state.dart';

void main() {
  testWidgets('Basic App initialization test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const KursusSahamApp(),
      ),
    );

    // Fast-forward past splash fallback timer
    await tester.pump(const Duration(seconds: 4));

    // Verify that basic widgets are rendered
    expect(find.byType(KursusSahamApp), findsOneWidget);
  });
}
