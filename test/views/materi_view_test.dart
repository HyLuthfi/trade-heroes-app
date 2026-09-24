import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kursus_saham/main.dart';
import 'package:kursus_saham/state/app_state.dart';
import 'package:kursus_saham/views/materi_view.dart';

void main() {
  testWidgets('MateriView renders tabs and modules without errors', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const KursusSahamApp(),
      ),
    );

    // Fast-forward past splash
    await tester.pump(const Duration(seconds: 4));

    // Pump MateriView directly in test harness
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: MaterialApp(
          home: const Scaffold(
            body: MateriView(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify TabBar and TabBarView exist
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(TabBarView), findsOneWidget);

    // Verify first module card title exists
    expect(find.text("Pengenalan Investasi Saham"), findsOneWidget);
  });
}
