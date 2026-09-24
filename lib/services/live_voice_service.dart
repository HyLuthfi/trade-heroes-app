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

class LiveVoiceService {
  static bool _isPlaying = false;
  static bool _isListening = false;

  static bool get isPlaying => _isPlaying;
  static bool get isListening => _isListening;

  /// Play Base64 WAV audio data URI ('data:audio/wav;base64,...')
  static void playAudio(String dataUri, {VoidCallback? onEnded}) {
    if (!kIsWeb) return;
    try {
      _isPlaying = true;
      final jsCallback = ((JSObject? _) {
        _isPlaying = false;
        if (onEnded != null) onEnded();
      }).toJS;

      _jsPlayVoiceAudioUri(dataUri.toJS, jsCallback);
    } catch (e) {
      debugPrint("LiveVoiceService playAudio error: $e");
      _isPlaying = false;
      if (onEnded != null) onEnded();
    }
  }

  /// Stop current playing voice audio immediately (barge-in / interrupt)
  static void stopAudio() {
    if (!kIsWeb) return;
    try {
      _isPlaying = false;
      _jsStopVoiceAudio();
    } catch (e) {
      debugPrint("LiveVoiceService stopAudio error: $e");
    }
  }

  /// Start progressive SSE voice streaming (ChatGPT Voice Style)
  static void startVoiceStream({
    required String payloadJson,
    required Function(String delta, String accumulated) onTextDelta,
    required VoidCallback onFirstAudio,
    required VoidCallback onAllDone,
    required Function(String error) onError,
  }) {
    if (!kIsWeb) return;
    try {
      final jsTextCb = ((JSString jsDelta, JSString jsAcc) {
        onTextDelta(jsDelta.toDart, jsAcc.toDart);
      }).toJS;

      final jsFirstAudioCb = ((JSObject? _) {
        _isPlaying = true;
        onFirstAudio();
      }).toJS;

      final jsAllDoneCb = ((JSObject? _) {
        _isPlaying = false;
        onAllDone();
      }).toJS;

      final jsErrorCb = ((JSString jsErr) {
        _isPlaying = false;
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

  /// Start browser speech recognition
  static bool startListening({
    required Function(String text) onTranscript,
    required Function(String state) onStateChange,
    required Function(String error) onError,
    String lang = 'id-ID',
  }) {
    if (!kIsWeb) return false;
    try {
      final jsTranscriptCb = ((JSString jsText) {
        final text = jsText.toDart;
        onTranscript(text);
      }).toJS;

      final jsStateCb = ((JSString jsState) {
        final state = jsState.toDart;
        _isListening = (state == 'listening');
        onStateChange(state);
      }).toJS;

      final jsErrorCb = ((JSString jsErr) {
        _isListening = false;
        onError(jsErr.toDart);
      }).toJS;

      final res = _jsStartLiveSpeechRecognition(
        lang.toJS,
        jsTranscriptCb,
        jsStateCb,
        jsErrorCb,
      );
      _isListening = res.toDart;
      return _isListening;
    } catch (e) {
      debugPrint("LiveVoiceService startListening error: $e");
      onError(e.toString());
      return false;
    }
  }

  /// Stop speech recognition
  static void stopListening() {
    if (!kIsWeb) return;
    try {
      _isListening = false;
      _jsStopLiveSpeechRecognition();
    } catch (e) {
      debugPrint("LiveVoiceService stopListening error: $e");
    }
  }
}
