import 'notification_stub.dart'
    if (dart.library.js_interop) 'notification_web.dart' as platform_notif;

class NotificationService {
  NotificationService._();

  static bool _notificationsEnabled = true;

  static void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
  }

  static bool get isNotificationsEnabled => _notificationsEnabled;

  /// Check whether W3C Notification API is supported in the current environment
  static bool get isSupported => platform_notif.jsHasTradeNotificationSupport();

  /// Returns current permission status: 'granted', 'denied', 'default', or 'unsupported'
  static String get permissionStatus =>
      platform_notif.jsGetTradeNotificationPermission();

  /// Whether notification permission is actively granted
  static bool get isPermissionGranted => permissionStatus == 'granted';

  /// Request browser notification permission (must be invoked from user gesture)
  static Future<bool> requestPermission() async {
    final status = await platform_notif.jsRequestTradeNotificationPermission();
    return status == 'granted';
  }

  /// Send a generic system notification
  static bool sendNotification({
    required String title,
    required String body,
    String? iconUrl,
    String? tag,
  }) {
    if (!_notificationsEnabled) return false;
    return platform_notif.jsSendTradeNotification(
      title,
      body,
      iconUrl ?? 'favicon.png',
      tag ?? 'trade-heroes-general',
    );
  }

  /// 1. Daily Streak Reminder (Triggered at 19:00 WIB)
  static bool sendDailyStreakReminder({
    required int streak,
    required String language,
  }) {
    if (!_notificationsEnabled) return false;
    final isEn = language.toLowerCase().startsWith('en');

    final title = isEn
        ? "🔥 Protect Your $streak-Day Streak!"
        : "🔥 Pertahankan Streak $streak Hari Belajarmu!";

    final body = isEn
        ? "Today's market quiz is waiting for you. Answer 3 quick questions before reset!"
        : "Kuis pasar modal hari ini menunggumu. Jawab 3 soal santai sebelum pergantian hari!";

    return sendNotification(
      title: title,
      body: body,
      tag: 'trade-heroes-daily-streak',
    );
  }

  /// 2. Lightning Energy (Petir) Fully Restored (5/5)
  static bool sendPetirFullReminder({required String language}) {
    if (!_notificationsEnabled) return false;
    final isEn = language.toLowerCase().startsWith('en');

    final title = isEn
        ? "⚡ Lightning Lives Fully Restored (5/5)!"
        : "⚡ Nyawa Petir Pulih Penuh (5/5)!";

    final body = isEn
        ? "Your trading energy is completely charged. Ready to conquer the next quiz level?"
        : "Energi belajarmu sudah penuh kembali. Siap menaklukkan level kuis berikutnya?";

    return sendNotification(
      title: title,
      body: body,
      tag: 'trade-heroes-petir-full',
    );
  }

  /// 3. Daily Reward Ready to Claim
  static bool sendDailyRewardReminder({required String language}) {
    if (!_notificationsEnabled) return false;
    final isEn = language.toLowerCase().startsWith('en');

    final title = isEn
        ? "🎁 Daily Chest Ready to Unlock!"
        : "🎁 Hadiah Login Harian Siap Diklaim!";

    final body = isEn
        ? "Claim your free XP and extra Lightning bonus for today's market session."
        : "Ambil bonus XP dan amunisi Petir gratis untuk modal belajar hari ini.";

    return sendNotification(
      title: title,
      body: body,
      tag: 'trade-heroes-daily-reward',
    );
  }

  /// 4. Test Notification Trigger (For immediate verification from Settings)
  static bool sendTestNotification({required String language}) {
    final isEn = language.toLowerCase().startsWith('en');

    final title = isEn
        ? "🔔 Trade Heroes Notification Active!"
        : "🔔 Notifikasi Trade Heroes Berhasil Aktif!";

    final body = isEn
        ? "You will receive learning streak reminders and energy alerts at 19:00 WIB."
        : "Kamu akan menerima pengingat streak belajar dan pemulihan nyawa setiap hari jam 19:00 WIB.";

    return sendNotification(
      title: title,
      body: body,
      tag: 'trade-heroes-test-alert',
    );
  }
}
