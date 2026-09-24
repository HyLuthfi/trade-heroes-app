import 'dart:js_interop';

@JS('playTradeSound')
external void _rawPlayTradeSound(JSString name, JSNumber vol);

@JS('startTradeBgm')
external void _rawStartTradeBgm(JSNumber vol);

@JS('stopTradeBgm')
external void _rawStopTradeBgm();

@JS('setTradeAudioMuted')
external void _rawSetTradeAudioMuted(JSBoolean muted);

@JS('setTradeBgmTrack')
external void _rawSetTradeBgmTrack(JSString track);

void jsPlayTradeSound(String name, double vol) {
  try {
    _rawPlayTradeSound(name.toJS, vol.toJS);
  } catch (_) {}
}

void jsStartTradeBgm(double vol) {
  try {
    _rawStartTradeBgm(vol.toJS);
  } catch (_) {}
}

void jsStopTradeBgm() {
  try {
    _rawStopTradeBgm();
  } catch (_) {}
}

void jsSetTradeAudioMuted(bool muted) {
  try {
    _rawSetTradeAudioMuted(muted.toJS);
  } catch (_) {}
}

void jsSetTradeBgmTrack(String track) {
  try {
    _rawSetTradeBgmTrack(track.toJS);
  } catch (_) {}
}
