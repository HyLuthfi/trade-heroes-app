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

@JS('setTradeBgmTrack')
external void _jsSetTradeBgmTrack(JSString track);

class AudioService {
  static final AudioPlayer _mobileBgmPlayer = AudioPlayer();
  static bool _bgmPlaying = false;
  static bool _isAudioEnabled = true;
  static String _currentTheme = 'default';
  static String _currentBgm = 'default';

  // === SFX THEMES ===
  static const List<String> availableThemes = [
    'default', 'minimal', 'arcade', 'nature', 'mechanical', 'bubble',
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

  // === BGM TRACKS ===
  static const List<String> availableBgms = [
    'default',
    'ambient_piano',
    'gentle_piano',
    'chill_piano',
    'lofi_study',
    'jazz_cafe',
    'deep_space',
    'rain_meditation',
  ];

  static const Map<String, String> bgmLabels = {
    'default': 'Acoustic Calm',
    'ambient_piano': 'Ambient Piano & Strings',
    'gentle_piano': 'Gentle Piano',
    'chill_piano': 'Chill Light Piano',
    'lofi_study': 'Lo-Fi Study Beats',
    'jazz_cafe': 'Jazz Cafe',
    'deep_space': 'Deep Space Ambient',
    'rain_meditation': 'Rain Meditation',
  };

  static const Map<String, String> bgmDescriptions = {
    'default': 'Piano akustik lembut, tenang',
    'ambient_piano': 'Piano & strings ambient mengalun',
    'gentle_piano': 'Piano solo halus & minimalis',
    'chill_piano': 'Piano ringan, santai sepanjang hari',
    'lofi_study': 'Lo-Fi beat santai untuk fokus belajar',
    'jazz_cafe': 'Suasana kafe jazz yang hangat',
    'deep_space': 'Drone ambient, floating, kosmik',
    'rain_meditation': 'Pad ethereal untuk meditasi',
  };

  static String get currentTheme => _currentTheme;
  static String get currentBgm => _currentBgm;

  static void setTheme(String theme) {
    if (!availableThemes.contains(theme)) return;
    _currentTheme = theme;
    if (kIsWeb) {
      try { _jsSetTradeAudioTheme(theme.toJS); } catch (_) {}
    }
  }

  static void setBgmTrack(String track) {
    if (!availableBgms.contains(track)) return;
    _currentBgm = track;
    if (kIsWeb) {
      try { _jsSetTradeBgmTrack(track.toJS); } catch (_) {}
    }
    // If BGM is playing, restart with new track
    if (_bgmPlaying) {
      stopBgm().then((_) => startBgm());
    }
  }

  static void setAudioEnabled(bool enabled) {
    _isAudioEnabled = enabled;
    if (kIsWeb) {
      try { _jsSetTradeAudioMuted((!enabled).toJS); } catch (_) {}
    } else {
      if (!enabled) stopBgm();
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

  /// Preview a SFX theme
  static void previewTheme(String theme, String soundName) {
    if (!_isAudioEnabled) return;
    if (kIsWeb) {
      try {
        final oldTheme = _currentTheme;
        _jsSetTradeAudioTheme(theme.toJS);
        Future.delayed(const Duration(milliseconds: 50), () {
          try { _jsPlayTradeSound(soundName.toJS, (0.4).toJS); } catch (_) {}
          Future.delayed(const Duration(milliseconds: 600), () {
            _currentTheme = oldTheme;
            try { _jsSetTradeAudioTheme(oldTheme.toJS); } catch (_) {}
          });
        });
        return;
      } catch (_) {}
    }
    final oldTheme = _currentTheme;
    _currentTheme = theme;
    _play(soundName, 0.4).then((_) { _currentTheme = oldTheme; });
  }

  /// Preview a BGM track (play 8 seconds then stop)
  static void previewBgm(String track) {
    if (!_isAudioEnabled) return;
    
    // Force stop any current playback first
    _bgmPlaying = false;
    if (kIsWeb) {
      try { _jsStopTradeBgm(); } catch (_) {}
      // Set new track and play directly via JS
      try { _jsSetTradeBgmTrack(track.toJS); } catch (_) {}
      Future.delayed(const Duration(milliseconds: 100), () {
        try { _jsStartTradeBgm((0.35).toJS); } catch (_) {}
        _bgmPlaying = true;
      });
    } else {
      _mobileBgmPlayer.stop().then((_) {
        _currentBgm = track;
        _bgmPlaying = true;
        _mobileBgmPlayer.setReleaseMode(ReleaseMode.loop);
        _mobileBgmPlayer.setVolume(0.35);
        final bgmPath = track == 'default' ? 'audio/bgm.mp3' : 'audio/bgm/$track.mp3';
        _mobileBgmPlayer.play(AssetSource(bgmPath));
      });
    }
  }

  /// Stop BGM preview explicitly
  static void stopPreview() {
    _bgmPlaying = false;
    if (kIsWeb) {
      try { _jsStopTradeBgm(); } catch (_) {}
    } else {
      _mobileBgmPlayer.stop();
    }
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
      final bgmPath = _currentBgm == 'default'
          ? 'audio/bgm.mp3'
          : 'audio/bgm/$_currentBgm.mp3';
      await _mobileBgmPlayer.play(AssetSource(bgmPath));
    } catch (e) {
      debugPrint("Mobile BGM error: $e");
    }
  }

  static Future<void> stopBgm() async {
    _bgmPlaying = false;
    if (kIsWeb) {
      try { _jsStopTradeBgm(); return; } catch (_) {}
    }
    try { await _mobileBgmPlayer.stop(); } catch (e) {
      debugPrint("Mobile BGM stop error: $e");
    }
  }

  static bool get isBgmPlaying => _bgmPlaying;
}
