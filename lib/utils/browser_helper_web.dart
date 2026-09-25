import 'dart:html' as html;

/// Web implementation of browser window and navigation helpers using dart:html.

bool jsIsOAuthRedirect() {
  try {
    final hash = html.window.location.hash;
    final search = html.window.location.search ?? '';
    final isOauthStored = html.window.sessionStorage['th_oauth_pending'] == '1';
    if (isOauthStored ||
        hash.contains('access_token') ||
        hash.contains('error') ||
        search.contains('code=')) {
      html.window.sessionStorage.remove('th_oauth_pending');
      return true;
    }
    return false;
  } catch (_) {
    return false;
  }
}

void jsOpenBrowserTab(String url) {
  try {
    html.window.open(url, '_blank');
  } catch (_) {}
}

String? jsGetLocalStorage(String key) {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    return null;
  }
}

void jsSetLocalStorage(String key, String value) {
  try {
    html.window.localStorage[key] = value;
  } catch (_) {}
}
