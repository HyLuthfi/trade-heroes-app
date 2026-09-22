import 'package:flutter_test/flutter_test.dart';
import 'package:kursus_saham/main.dart';

void main() {
  testWidgets('Basic App initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KursusSahamApp());

    // Verify that the title is present or basic widgets are rendered
    expect(find.byType(KursusSahamApp), findsOneWidget);
  });
}
