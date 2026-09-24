import 'package:flutter/foundation.dart';

/// Native Dart VM & Test Stub for LiveVoiceService.
/// Provides safe no-op implementations for native test runners
/// without any browser-specific JavaScript interop (dart:js_interop).

void jsPlayVoiceAudioUri(String uri, VoidCallback? onEnded) {
  if (onEnded != null) onEnded();
}

void jsStopVoiceAudio() {}

void jsStartLiveVoiceStream(
  String payloadJson,
  void Function(String delta, String accumulated) onTextDelta,
  VoidCallback onFirstAudio,
  VoidCallback onAllDone,
  void Function(String error) onError,
) {
  onError("Live voice streaming is only available on Web.");
}

bool jsStartLiveSpeechRecognition(
  String lang,
  void Function(String text) onTranscript,
  void Function(String state) onStateChange,
  void Function(String error) onError,
) {
  onError("Speech recognition is only available on Web.");
  return false;
}

void jsStopLiveSpeechRecognition() {}
