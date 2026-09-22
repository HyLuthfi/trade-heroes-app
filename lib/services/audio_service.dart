import 'dart:js_interop';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

@JS('playTradeSound')
external void _jsPlayTradeSound(JSString name, JSNumber vol);

@JS('startTradeBgm')
external void _jsStartTradeBgm(JSNumber vol);

@JS('stopTradeBgm')
external void _jsStopTradeBgm();

@JS('setTradeAudioMuted')
external void _jsSetTradeAudioMuted(JSBoolean muted);

class AudioService {
  static final AudioPlayer _mobileBgmPlayer = AudioPlayer();
  static bool _bgmPlaying = false;
  static bool _isAudioEnabled = true;

  static void setAudioEnabled(bool enabled) {
    _isAudioEnabled = enabled;
    if (kIsWeb) {
      try {
        _jsSetTradeAudioMuted((!enabled).toJS);
      } catch (_) {}
    } else {
      if (!enabled) {
        stopBgm();
      }
    }
  }

  static Future<void> _play(String name, double volume) async {
    if (!_isAudioEnabled) return;
    if (kIsWeb) {
      try {
        _jsPlayTradeSound(name.toJS, volume.toJS);
        return;
      } catch (e) {
        debugPrint("Web JS Audio error: $e");
      }
    }

    // Native mobile fallback
    try {
      final player = AudioPlayer();
      await player.setVolume(volume);
      await player.play(AssetSource('audio/$name.mp3'));
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (e) {
      debugPrint("Native Audio error: $e");
    }
  }

  // --- SOUND EFFECTS ---

  // 1. Crisp UI Button / Tab Tap Sound
  static void playClick() {
    _play('click', 0.65);
  }

  // 2. Quiz Correct
  static void playCorrect() {
    _play('correct', 0.85);
  }

  // 3. Quiz Wrong
  static void playWrong() {
    _play('wrong', 0.80);
  }

  // 4. Milestone / Chest / Reward
  static void playReward() {
    _play('reward', 0.90);
  }

  // 5. Market Buy / Sell Execution
  static void playTrade() {
    _play('trade', 0.85);
  }

  // --- BACKGROUND MUSIC ---

  static Future<void> startBgm() async {
    if (!_isAudioEnabled || _bgmPlaying) return;
    _bgmPlaying = true;

    if (kIsWeb) {
      try {
        _jsStartTradeBgm((0.28).toJS);
        return;
      } catch (_) {}
    }

    try {
      await _mobileBgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _mobileBgmPlayer.setVolume(0.25);
      await _mobileBgmPlayer.play(AssetSource('audio/bgm.mp3'));
    } catch (e) {
      debugPrint("Mobile BGM error: $e");
    }
  }

  static Future<void> stopBgm() async {
    _bgmPlaying = false;
    if (kIsWeb) {
      try {
        _jsStopTradeBgm();
        return;
      } catch (_) {}
    }

    try {
      await _mobileBgmPlayer.stop();
    } catch (e) {
      debugPrint("Mobile BGM stop error: $e");
    }
  }

  static bool get isBgmPlaying => _bgmPlaying;
}
