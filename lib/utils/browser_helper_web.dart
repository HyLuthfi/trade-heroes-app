import 'dart:html' as html;

/// Web implementation of browser window and navigation helpers using dart:html.

bool jsIsOAuthRedirect() {
  try {
    final hash = html.window.location.hash;
    final search = html.window.location.search ?? '';
    return hash.contains('access_token') ||
           hash.contains('error') ||
           search.contains('code=');
  } catch (_) {
    return false;
  }
}

void jsOpenBrowserTab(String url) {
  try {
    html.window.open(url, '_blank');
  } catch (_) {}
}
