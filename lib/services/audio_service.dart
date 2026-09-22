import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioPlayer _bgmPlayer = AudioPlayer();
  static bool _bgmPlaying = false;
  static bool _isAudioEnabled = true;

  static void setAudioEnabled(bool enabled) {
    _isAudioEnabled = enabled;
    if (!enabled) {
      stopBgm();
    }
  }

  static Source _getSource(String file) {
    if (kIsWeb) {
      // In Flutter Web, direct absolute URL source works 100% reliably with browser HTML5 Audio
      return UrlSource('assets/assets/audio/$file');
    } else {
      return AssetSource('audio/$file');
    }
  }

  static Future<void> _playSfx(String file, double volume) async {
    if (!_isAudioEnabled) return;
    try {
      final player = AudioPlayer();
      await player.setVolume(volume);
      await player.play(_getSource(file));
      // Auto dispose player after playback
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (e) {
      debugPrint("Audio _playSfx ($file) error: $e");
    }
  }

  // Play Sound Effects
  static Future<void> playCorrect() async {
    await _playSfx('correct.mp3', 0.85);
  }

  static Future<void> playWrong() async {
    await _playSfx('wrong.mp3', 0.80);
  }

  static Future<void> playReward() async {
    await _playSfx('reward.mp3', 0.90);
  }

  static Future<void> playTrade() async {
    await _playSfx('trade.mp3', 0.85);
  }

  // Background Lo-Fi Ambient Chill Music
  static Future<void> startBgm() async {
    if (!_isAudioEnabled || _bgmPlaying) return;
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.20); // Soft, non-distracting ambient level
      await _bgmPlayer.play(_getSource('bgm.mp3'));
      _bgmPlaying = true;
    } catch (e) {
      debugPrint("Audio startBgm error: $e");
    }
  }

  static Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
      _bgmPlaying = false;
    } catch (e) {
      debugPrint("Audio stopBgm error: $e");
    }
  }

  static bool get isBgmPlaying => _bgmPlaying;
}
