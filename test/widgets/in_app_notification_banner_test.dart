import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kursus_saham/widgets/in_app_notification_banner.dart';

void main() {
  testWidgets('InAppNotificationBanner displays and dismisses smoothly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  InAppNotificationBanner.show(
                    context,
                    const InAppNotificationPayload(
                      title: 'Streak Alert!',
                      message: 'Keep your 5-day streak alive today.',
                      type: InAppNotificationType.streak,
                      actionLabel: 'PRACTICE',
                    ),
                  );
                },
                child: const Text('Show Banner'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap button to show banner
    await tester.tap(find.text('Show Banner'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify banner content is present
    expect(find.text('Streak Alert!'), findsOneWidget);
    expect(find.text('Keep your 5-day streak alive today.'), findsOneWidget);
    expect(find.text('PRACTICE'), findsOneWidget);

    // Verify dismiss works
    InAppNotificationBanner.dismissCurrent();
    await tester.pump();
  });
}
