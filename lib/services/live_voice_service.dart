import 'package:flutter/foundation.dart';
import 'live_voice_stub.dart'
    if (dart.library.js_interop) 'live_voice_web.dart' as platform_voice;

class LiveVoiceService {
  static bool _isPlaying = false;
  static bool _isListening = false;

  static bool get isPlaying => _isPlaying;
  static bool get isListening => _isListening;

  /// Play Base64 WAV audio data URI ('data:audio/wav;base64,...')
  static void playAudio(String dataUri, {VoidCallback? onEnded}) {
    if (!kIsWeb) return;
    _isPlaying = true;
    platform_voice.jsPlayVoiceAudioUri(dataUri, () {
      _isPlaying = false;
      if (onEnded != null) onEnded();
    });
  }

  /// Stop current playing voice audio immediately (barge-in / interrupt)
  static void stopAudio() {
    if (!kIsWeb) return;
    _isPlaying = false;
    platform_voice.jsStopVoiceAudio();
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
    platform_voice.jsStartLiveVoiceStream(
      payloadJson,
      onTextDelta,
      () {
        _isPlaying = true;
        onFirstAudio();
      },
      () {
        _isPlaying = false;
        onAllDone();
      },
      (err) {
        _isPlaying = false;
        onError(err);
      },
    );
  }

  /// Start browser speech recognition
  static bool startListening({
    required Function(String text) onTranscript,
    required Function(String state) onStateChange,
    required Function(String error) onError,
    String lang = 'id-ID',
  }) {
    if (!kIsWeb) return false;
    final started = platform_voice.jsStartLiveSpeechRecognition(
      lang,
      onTranscript,
      (state) {
        _isListening = (state == 'listening');
        onStateChange(state);
      },
      (err) {
        _isListening = false;
        onError(err);
      },
    );
    _isListening = started;
    return started;
  }

  /// Stop speech recognition
  static void stopListening() {
    if (!kIsWeb) return;
    _isListening = false;
    platform_voice.jsStopLiveSpeechRecognition();
  }
}
