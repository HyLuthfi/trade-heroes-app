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

@JS('setTradeAudioTheme')
external void _jsSetTradeAudioTheme(JSString theme);

class AudioService {
  static final AudioPlayer _mobileBgmPlayer = AudioPlayer();
  static bool _bgmPlaying = false;
  static bool _isAudioEnabled = true;
  static String _currentTheme = 'default';

  static const List<String> availableThemes = [
    'default',
    'minimal',
    'arcade',
    'nature',
    'mechanical',
    'bubble',
  ];

  static const Map<String, String> themeLabels = {
    'default': 'Default',
    'minimal': 'Minimal',
    'arcade': 'Arcade 8-Bit',
    'nature': 'Nature',
    'mechanical': 'Mechanical',
    'bubble': 'Bubble Pop',
  };

  static const Map<String, String> themeDescriptions = {
    'default': 'Gentle water droplet, standar bawaan',
    'minimal': 'Ultra-halus, hampir tak terdengar',
    'arcade': 'Retro 8-bit ala game klasik',
    'nature': 'Organik: air, angin, kayu',
    'mechanical': 'Mesin ketik & industrial',
    'bubble': 'Gelembung sabun yang playful',
  };

  static const Map<String, String> themeIcons = {
    'default': 'water_drop',
    'minimal': 'lens_blur',
    'arcade': 'sports_esports',
    'nature': 'eco',
    'mechanical': 'precision_manufacturing',
    'bubble': 'bubble_chart',
  };

  static String get currentTheme => _currentTheme;

  static void setTheme(String theme) {
    if (!availableThemes.contains(theme)) return;
    _currentTheme = theme;
    if (kIsWeb) {
      try {
        _jsSetTradeAudioTheme(theme.toJS);
      } catch (_) {}
    }
  }

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
      final themePath = _currentTheme == 'default'
          ? 'audio/$name.mp3'
          : 'audio/themes/$_currentTheme/$name.mp3';
      await player.play(AssetSource(themePath));
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (e) {
      debugPrint("Native Audio error: $e");
    }
  }

  // --- SOUND EFFECTS ---
  static void playClick() => _play('click', 0.65);
  static void playCorrect() => _play('correct', 0.85);
  static void playWrong() => _play('wrong', 0.80);
  static void playReward() => _play('reward', 0.90);
  static void playTrade() => _play('trade', 0.85);

  /// Play a preview of a specific theme's sound
  static void previewTheme(String theme, String soundName) {
    if (!_isAudioEnabled) return;
    final oldTheme = _currentTheme;
    _currentTheme = theme;
    if (kIsWeb) {
      try {
        _jsSetTradeAudioTheme(theme.toJS);
        _jsPlayTradeSound(soundName.toJS, (0.5).toJS);
        // Restore after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          _currentTheme = oldTheme;
          try { _jsSetTradeAudioTheme(oldTheme.toJS); } catch (_) {}
        });
        return;
      } catch (_) {}
    }
    _play(soundName, 0.5).then((_) {
      _currentTheme = oldTheme;
    });
  }

  // --- BACKGROUND MUSIC ---
  static Future<void> startBgm() async {
    if (!_isAudioEnabled || _bgmPlaying) return;
    _bgmPlaying = true;

    if (kIsWeb) {
      try {
        _jsStartTradeBgm((0.14).toJS);
        return;
      } catch (_) {}
    }

    try {
      await _mobileBgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _mobileBgmPlayer.setVolume(0.14);
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
