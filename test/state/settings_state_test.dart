import 'package:flutter_test/flutter_test.dart';
import 'package:kursus_saham/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppState Settings and Profile State Tests', () {
    test('Default reminder hour is 19 and can be updated', () {
      final appState = AppState();
      expect(appState.reminderHour, 19);

      appState.setReminderHour(8);
      expect(appState.reminderHour, 8);

      appState.setReminderHour(16);
      expect(appState.reminderHour, 16);

      appState.setReminderHour(20);
      expect(appState.reminderHour, 20);
    });

    test('updateProfile updates name, email, and avatar', () {
      final appState = AppState();
      appState.updateProfile(
        name: 'Trader Hero 2026',
        email: 'trader@hero.com',
        avatar: 'chart',
      );

      expect(appState.userName, 'Trader Hero 2026');
      expect(appState.userEmail, 'trader@hero.com');
      expect(appState.userAvatar, 'chart');
    });

    test('resetProgress resets progress while retaining user identity', () {
      final appState = AppState();
      appState.updateProfile(
        name: 'Master Investor',
        email: 'investor@bei.co.id',
        avatar: 'bull',
      );

      // Simulate some progress
      appState.completeLevel(4);
      appState.completeLevel(5);
      expect(appState.completedLevels, contains(4));
      expect(appState.completedLevels, contains(5));

      // Reset
      appState.resetProgress();

      expect(appState.userName, 'Master Investor');
      expect(appState.userEmail, 'investor@bei.co.id');
      expect(appState.userAvatar, 'bull');
      expect(appState.readModules, isEmpty);
      expect(appState.completedLevels, [1, 2, 3]);
      expect(appState.virtualBalance, 100000000.0);
      expect(appState.petir, 5);
      expect(appState.streak, 0);
      expect(appState.xp, 0);
    });
  });
}
