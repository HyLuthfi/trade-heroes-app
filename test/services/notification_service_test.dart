import 'package:flutter_test/flutter_test.dart';
import 'package:kursus_saham/services/notification_service.dart';

void main() {
  group('NotificationService VM Environment Tests', () {
    test('NotificationService methods execute safely in Dart VM without crashing', () async {
      // In native VM, stub returns unsupported / false without throws
      expect(NotificationService.isSupported, isFalse);
      expect(NotificationService.permissionStatus, equals('unsupported'));
      expect(NotificationService.isPermissionGranted, isFalse);

      final perm = await NotificationService.requestPermission();
      expect(perm, isFalse);

      // Sending notification is safe no-op
      final sent = NotificationService.sendNotification(
        title: "Test",
        body: "Test Body",
      );
      expect(sent, isFalse);
    });

    test('NotificationService helper builders handle ID and EN without exceptions', () {
      NotificationService.setNotificationsEnabled(true);
      expect(NotificationService.isNotificationsEnabled, isTrue);

      expect(
        () => NotificationService.sendDailyStreakReminder(streak: 5, language: 'id'),
        returnsNormally,
      );
      expect(
        () => NotificationService.sendDailyStreakReminder(streak: 5, language: 'en'),
        returnsNormally,
      );

      expect(
        () => NotificationService.sendPetirFullReminder(language: 'id'),
        returnsNormally,
      );
      expect(
        () => NotificationService.sendPetirFullReminder(language: 'en'),
        returnsNormally,
      );

      expect(
        () => NotificationService.sendDailyRewardReminder(language: 'id'),
        returnsNormally,
      );
      expect(
        () => NotificationService.sendDailyRewardReminder(language: 'en'),
        returnsNormally,
      );

      expect(
        () => NotificationService.sendTestNotification(language: 'id'),
        returnsNormally,
      );
      expect(
        () => NotificationService.sendTestNotification(language: 'en'),
        returnsNormally,
      );
    });

    test('Disabling notifications prevents sending', () {
      NotificationService.setNotificationsEnabled(false);
      expect(NotificationService.isNotificationsEnabled, isFalse);

      final res = NotificationService.sendNotification(
        title: "Disabled",
        body: "Should not send",
      );
      expect(res, isFalse);

      NotificationService.setNotificationsEnabled(true);
    });
  });
}
