/// Conditionally exports the native stub on VM/tests or the iframe implementation on Web.
export 'tradingview_chart_stub.dart'
    if (dart.library.js_interop) 'tradingview_chart_web.dart';
