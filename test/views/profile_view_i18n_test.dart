import 'package:flutter_test/flutter_test.dart';
import 'package:kursus_saham/l10n/app_translations.dart';

void main() {
  test('Profile and Settings labels resolve in Indonesian and English', () {
    const keys = <String>[
      'profile.title',
      'profile.edit_info',
      'profile.save',
      'profile.cancel',
      'profile.statistics',
      'profile.settings',
      'profile.logout',
      'settings.dark_mode_title',
      'settings.daily_reminder_title',
      'settings.sound_haptic_title',
      'settings.bgm_title',
      'settings.choose_bgm',
      'settings.reminder_time',
      'settings.reminder_time_title',
      'settings.reminder_time_desc',
      'settings.reminder_time_8',
      'settings.reminder_time_16',
      'settings.reminder_time_19',
      'settings.reminder_time_20',
      'settings.reset_progress',
      'settings.reset_progress_confirm_title',
      'settings.reset_progress_confirm_desc',
      'settings.reset_progress_action',
      'settings.reset_progress_success',
      'profile.edit_name',
      'profile.edit_name_desc',
      'profile.name_updated',
      'profile.name_empty',
    ];

    for (final key in keys) {
      expect(AppTranslations.text('id', key), isNot(key), reason: 'Missing ID: $key');
      expect(AppTranslations.text('en', key), isNot(key), reason: 'Missing EN: $key');
    }
  });

  test('Profile settings use distinct English translations', () {
    expect(AppTranslations.text('en', 'profile.settings'), 'Settings & Preferences');
    expect(AppTranslations.text('en', 'settings.daily_reminder_title'), 'Daily Learning Notifications');
    expect(AppTranslations.text('en', 'settings.sound_haptic_title'), 'Sound & Haptics');
    expect(AppTranslations.text('en', 'settings.bgm_title'), 'Background Music (Lo-Fi BGM)');
  });
}
