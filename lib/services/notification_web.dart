import 'dart:js_interop';

@JS('hasTradeNotificationSupport')
external JSBoolean _rawHasSupport();

@JS('getTradeNotificationPermission')
external JSString _rawGetPermission();

@JS('requestTradeNotificationPermission')
external JSPromise<JSString> _rawRequestPermission();

@JS('sendTradeNotification')
external JSBoolean _rawSendNotification(
    JSString title, JSString body, JSString iconUrl, JSString tag);

bool jsHasTradeNotificationSupport() {
  try {
    return _rawHasSupport().toDart;
  } catch (_) {
    return false;
  }
}

String jsGetTradeNotificationPermission() {
  try {
    return _rawGetPermission().toDart;
  } catch (_) {
    return 'unsupported';
  }
}

Future<String> jsRequestTradeNotificationPermission() async {
  try {
    final jsRes = await _rawRequestPermission().toDart;
    return jsRes.toDart;
  } catch (_) {
    return 'denied';
  }
}

bool jsSendTradeNotification(
    String title, String body, String iconUrl, String tag) {
  try {
    return _rawSendNotification(
            title.toJS, body.toJS, iconUrl.toJS, tag.toJS)
        .toDart;
  } catch (_) {
    return false;
  }
}
