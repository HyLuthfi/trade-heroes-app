import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('playVoiceAudioUri')
external void _jsPlayVoiceAudioUri(JSString uri, JSFunction? onEnded);

@JS('stopVoiceAudio')
external void _jsStopVoiceAudio();

@JS('startLiveVoiceStream')
external void _jsStartLiveVoiceStream(
  JSString payloadJson,
  JSFunction onTextDelta,
  JSFunction onFirstAudio,
  JSFunction onAllDone,
  JSFunction onError,
);

@JS('startLiveSpeechRecognition')
external JSBoolean _jsStartLiveSpeechRecognition(
  JSString lang,
  JSFunction onTranscript,
  JSFunction onStateChange,
  JSFunction onError,
);

@JS('stopLiveSpeechRecognition')
external void _jsStopLiveSpeechRecognition();

void jsPlayVoiceAudioUri(String uri, VoidCallback? onEnded) {
  try {
    final jsCallback = ((JSObject? _) {
      if (onEnded != null) onEnded();
    }).toJS;

    _jsPlayVoiceAudioUri(uri.toJS, jsCallback);
  } catch (e) {
    debugPrint("LiveVoiceService playAudio error: $e");
    if (onEnded != null) onEnded();
  }
}

void jsStopVoiceAudio() {
  try {
    _jsStopVoiceAudio();
  } catch (e) {
    debugPrint("LiveVoiceService stopAudio error: $e");
  }
}

void jsStartLiveVoiceStream(
  String payloadJson,
  void Function(String delta, String accumulated) onTextDelta,
  VoidCallback onFirstAudio,
  VoidCallback onAllDone,
  void Function(String error) onError,
) {
  try {
    final jsTextCb = ((JSString jsDelta, JSString jsAcc) {
      onTextDelta(jsDelta.toDart, jsAcc.toDart);
    }).toJS;

    final jsFirstAudioCb = (() {
      onFirstAudio();
    }).toJS;

    final jsAllDoneCb = (() {
      onAllDone();
    }).toJS;

    final jsErrorCb = ((JSString jsErr) {
      onError(jsErr.toDart);
    }).toJS;

    _jsStartLiveVoiceStream(
      payloadJson.toJS,
      jsTextCb,
      jsFirstAudioCb,
      jsAllDoneCb,
      jsErrorCb,
    );
  } catch (e) {
    debugPrint("LiveVoiceService startVoiceStream error: $e");
    onError(e.toString());
  }
}

bool jsStartLiveSpeechRecognition(
  String lang,
  void Function(String text) onTranscript,
  void Function(String state) onStateChange,
  void Function(String error) onError,
) {
  try {
    final jsTranscriptCb = ((JSString jsText) {
      final text = jsText.toDart;
      onTranscript(text);
    }).toJS;

    final jsStateCb = ((JSString jsState) {
      final state = jsState.toDart;
      onStateChange(state);
    }).toJS;

    final jsErrorCb = ((JSString jsErr) {
      onError(jsErr.toDart);
    }).toJS;

    final res = _jsStartLiveSpeechRecognition(
      lang.toJS,
      jsTranscriptCb,
      jsStateCb,
      jsErrorCb,
    );
    return res.toDart;
  } catch (e) {
    debugPrint("LiveVoiceService startListening error: $e");
    onError(e.toString());
    return false;
  }
}

void jsStopLiveSpeechRecognition() {
  try {
    _jsStopLiveSpeechRecognition();
  } catch (e) {
    debugPrint("LiveVoiceService stopListening error: $e");
  }
}
