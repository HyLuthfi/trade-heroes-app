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

@JS('setTradeBgmTrack')
external void _jsSetTradeBgmTrack(JSString track);

/// Contextual SFX engine — sounds auto-match the interaction type.
/// Bubble sounds for casual UI taps, Arcade sounds for confirmations.
class AudioService {
  static final AudioPlayer _mobileBgmPlayer = AudioPlayer();
  static bool _bgmPlaying = false;
  static bool _isAudioEnabled = true;
  static String _currentBgm = 'default';

  // === BGM TRACKS ===
  static const List<String> availableBgms = [
    'default', 'ambient_piano', 'gentle_piano', 'chill_piano',
    'lofi_study', 'jazz_cafe', 'deep_space', 'rain_meditation',
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

  static String get currentBgm => _currentBgm;

  static void setBgmTrack(String track) {
    if (!availableBgms.contains(track)) return;
    _currentBgm = track;
    if (kIsWeb) {
      try { _jsSetTradeBgmTrack(track.toJS); } catch (_) {}
    }
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

  /// Play a sound by file name from a specific theme folder
  static Future<void> _playFromTheme(String theme, String name, double volume) async {
    if (!_isAudioEnabled) return;
    if (kIsWeb) {
      try {
        // Play via JS with theme prefix: "bubble/click" or "arcade/correct"
        _jsPlayTradeSound('$theme/$name'.toJS, volume.toJS);
        return;
      } catch (e) {
        debugPrint("Web JS Audio error: $e");
      }
    }
    try {
      final player = AudioPlayer();
      await player.setVolume(volume);
      await player.play(AssetSource('audio/themes/$theme/$name.mp3'));
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (e) {
      debugPrint("Native Audio error: $e");
    }
  }

  // ===================================================================
  // CONTEXTUAL SFX — auto-picks the right sound for the interaction
  // ===================================================================

  /// Casual UI tap: toggle, klik level, navigasi ringan → Bubble pop
  static void playClick() => _playFromTheme('bubble', 'click', 0.50);

  /// Quiz: jawaban benar → Arcade coin collect!
  static void playCorrect() => _playFromTheme('arcade', 'correct', 0.70);

  /// Quiz: jawaban salah → Arcade game fail
  static void playWrong() => _playFromTheme('arcade', 'wrong', 0.65);

  /// Klaim hadiah, chest, daily reward → Arcade level up fanfare
  static void playReward() => _playFromTheme('arcade', 'reward', 0.75);

  /// Eksekusi order Beli/Jual → Arcade game bonus
  static void playTrade() => _playFromTheme('arcade', 'trade', 0.70);

  /// Konfirmasi aksi penting: Mulai Kuis, submit order → Arcade blip
  static void playConfirm() => _playFromTheme('arcade', 'click', 0.60);

  // ===================================================================
  // BGM
  // ===================================================================

  static void previewBgm(String track) {
    if (!_isAudioEnabled) return;
    _bgmPlaying = false;
    if (kIsWeb) {
      try { _jsStopTradeBgm(); } catch (_) {}
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

  static void stopPreview() {
    _bgmPlaying = false;
    if (kIsWeb) {
      try { _jsStopTradeBgm(); } catch (_) {}
    } else {
      _mobileBgmPlayer.stop();
    }
  }

  static Future<void> startBgm() async {
    if (!_isAudioEnabled || _bgmPlaying) return;
    _bgmPlaying = true;
    if (kIsWeb) {
      try { _jsStartTradeBgm((0.14).toJS); return; } catch (_) {}
    }
    try {
      await _mobileBgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _mobileBgmPlayer.setVolume(0.14);
      final bgmPath = _currentBgm == 'default'
          ? 'audio/bgm.mp3' : 'audio/bgm/$_currentBgm.mp3';
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
