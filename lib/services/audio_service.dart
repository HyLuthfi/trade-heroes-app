import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  static final AudioPlayer _bgmPlayer = AudioPlayer();
  static bool _bgmPlaying = false;
  static bool _isAudioEnabled = true;

  static void setAudioEnabled(bool enabled) {
    _isAudioEnabled = enabled;
    if (!enabled) {
      stopBgm();
    }
  }

  // Play Sound Effects
  static Future<void> playCorrect() async {
    if (!_isAudioEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(0.7);
      await _sfxPlayer.play(AssetSource('audio/correct.mp3'));
    } catch (e) {
      debugPrint("Audio playCorrect error: $e");
    }
  }

  static Future<void> playWrong() async {
    if (!_isAudioEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(0.65);
      await _sfxPlayer.play(AssetSource('audio/wrong.mp3'));
    } catch (e) {
      debugPrint("Audio playWrong error: $e");
    }
  }

  static Future<void> playReward() async {
    if (!_isAudioEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(0.75);
      await _sfxPlayer.play(AssetSource('audio/reward.mp3'));
    } catch (e) {
      debugPrint("Audio playReward error: $e");
    }
  }

  static Future<void> playTrade() async {
    if (!_isAudioEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(0.7);
      await _sfxPlayer.play(AssetSource('audio/trade.mp3'));
    } catch (e) {
      debugPrint("Audio playTrade error: $e");
    }
  }

  // Background Lo-Fi Ambient Chill Music
  static Future<void> startBgm() async {
    if (!_isAudioEnabled || _bgmPlaying) return;
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.18); // Soft, non-distracting ambient level
      await _bgmPlayer.play(AssetSource('audio/bgm.mp3'));
      _bgmPlaying = true;
    } catch (e) {
      debugPrint("Audio startBgm error: $e");
    }
  }

  static Future<void> stopBgm() async {
    if (!_bgmPlaying) return;
    try {
      await _bgmPlayer.stop();
      _bgmPlaying = false;
    } catch (e) {
      debugPrint("Audio stopBgm error: $e");
    }
  }

  static bool get isBgmPlaying => _bgmPlaying;
}
