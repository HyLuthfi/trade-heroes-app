import 'browser_helper_stub.dart'
    if (dart.library.js_interop) 'browser_helper_web.dart' as platform_browser;

class BrowserHelper {
  BrowserHelper._();

  /// Check whether the current browser window URL indicates a return from OAuth redirect
  static bool isOAuthRedirect() => platform_browser.jsIsOAuthRedirect();

  /// Open external URL in a new browser tab
  static void openTab(String url) => platform_browser.jsOpenBrowserTab(url);

  /// Safe local storage getter (returns null on VM)
  static String? getLocalStorage(String key) => platform_browser.jsGetLocalStorage(key);

  /// Safe local storage setter (no-op on VM)
  static void setLocalStorage(String key, String value) => platform_browser.jsSetLocalStorage(key, value);
}
