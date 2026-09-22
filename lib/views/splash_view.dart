import 'dart:async';
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
    _initVideoPlayer();

    // Guaranteed 3.2-second transition fallback
    _fallbackTimer = Timer(const Duration(milliseconds: 3200), () {
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
            const SizedBox.expand(
              child: ColoredBox(
                color: Color(0xff060a12),
              ),
            ),
        ],
      ),
    );
  }
}
