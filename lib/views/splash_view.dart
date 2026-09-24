import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoSplashView extends StatefulWidget {
  final Widget child;
  const VideoSplashView({Key? key, required this.child}) : super(key: key);

  @override
  State<VideoSplashView> createState() => _VideoSplashViewState();
}

class _VideoSplashViewState extends State<VideoSplashView> {
  VideoPlayerController? _controller;
  bool _isVideoInitialized = false;
  bool _splashCompleted = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();

    // Instant bypass if returning from Google OAuth redirect (prevents black/frozen screen)
    if (kIsWeb) {
      try {
        final hash = html.window.location.hash;
        final search = html.window.location.search ?? '';
        final isOauthStored = html.window.sessionStorage['th_oauth_pending'] == '1';
        if (isOauthStored || hash.contains('access_token') || hash.contains('error') || search.contains('code=')) {
          html.window.sessionStorage.remove('th_oauth_pending');
          _splashCompleted = true;
          return;
        }
      } catch (_) {}
    }

    _initVideoPlayer();

    // Guaranteed 2.2-second transition fallback
    _fallbackTimer = Timer(const Duration(milliseconds: 2200), () {
      _finishSplash();
    });
  }

  Future<void> _initVideoPlayer() async {
    try {
      _controller = VideoPlayerController.asset('assets/Flash_Screen.mp4');
      await _controller!.initialize();
      await _controller!.setVolume(0.0); // Required by Chrome/Edge for autoplay without user interaction
      await _controller!.setLooping(false);

      _controller!.addListener(() {
        if (_controller!.value.isInitialized &&
            _controller!.value.position >= _controller!.value.duration) {
          _finishSplash();
        }
      });

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        await _controller!.play();
      }
    } catch (e) {
      debugPrint("Video splash load error: $e");
    }
  }

  void _finishSplash() {
    if (!_splashCompleted && mounted) {
      setState(() {
        _splashCompleted = true;
      });
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_splashCompleted) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: const Color(0xff060a12),
      body: Stack(
        children: [
          // Video Player Screen Canvas
          if (_isVideoInitialized && _controller != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else
            SizedBox.expand(
              child: Container(
                color: const Color(0xff060a12),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 72,
                      height: 72,
                      errorBuilder: (_, __, ___) => const Icon(Icons.show_chart_rounded, color: Color(0xff10b981), size: 64),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "TRADE HEROES",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Color(0xff10b981), strokeWidth: 2.5),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
