// Native / VM Stub for Web Notification Interop
bool jsHasTradeNotificationSupport() => false;

String jsGetTradeNotificationPermission() => 'unsupported';

Future<String> jsRequestTradeNotificationPermission() async => 'unsupported';

bool jsSendTradeNotification(
    String title, String body, String iconUrl, String tag) =>
    false;
