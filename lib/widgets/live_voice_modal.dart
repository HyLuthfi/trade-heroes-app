import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/audio_service.dart';
import '../services/live_voice_service.dart';

enum VoiceState { listening, thinking, speaking, idle }

class LiveVoiceModal extends StatefulWidget {
  final Map<String, dynamic> stock;
  final Function(String userText, String aiText)? onConversationEnd;

  const LiveVoiceModal({
    Key? key,
    required this.stock,
    this.onConversationEnd,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required Map<String, dynamic> stock,
    Function(String userText, String aiText)? onConversationEnd,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LiveVoiceModal(
        stock: stock,
        onConversationEnd: onConversationEnd,
      ),
    );
  }

  @override
  State<LiveVoiceModal> createState() => _LiveVoiceModalState();
}

class _LiveVoiceModalState extends State<LiveVoiceModal> with TickerProviderStateMixin {
  VoiceState _state = VoiceState.idle;
  String _userTranscript = "";
  String _aiTranscript = "";
  String _errorMessage = "";
  bool _isMicMuted = false;
  final String _selectedEngine = "gemini_charon";

  late AnimationController _orbController;
  late Animation<double> _orbPulse;
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _orbPulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _orbController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // Start auto listening on modal open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListeningCycle();
    });
  }

  @override
  void dispose() {
    LiveVoiceService.stopAudio();
    LiveVoiceService.stopListening();
    _orbController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _startListeningCycle() {
    if (!mounted || _isMicMuted) return;

    LiveVoiceService.stopAudio();
    setState(() {
      _state = VoiceState.listening;
      _errorMessage = "";
    });

    final success = LiveVoiceService.startListening(
      lang: 'id-ID',
      onTranscript: (text) {
        if (!mounted) return;
        final clean = text.trim();
        if (clean.isNotEmpty) {
          setState(() {
            _userTranscript = clean;
          });
          _sendVoicePrompt(clean);
        }
      },
      onStateChange: (st) {
        if (!mounted) return;
        if (st == 'idle' && _state == VoiceState.listening && _userTranscript.isEmpty) {
          // If stopped without speech, restart listening gently
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted && _state == VoiceState.listening && !_isMicMuted) {
              _startListeningCycle();
            }
          });
        }
      },
      onError: (err) {
        if (!mounted) return;
        debugPrint("Speech recognition notice: $err");
        if (_state == VoiceState.listening) {
          setState(() {
            _errorMessage = "Ketuk Orb untuk mulai bicara";
          });
        }
      },
    );

    if (!success && mounted) {
      setState(() {
        _errorMessage = "Mikrofon tidak aktif atau belum diizinkan";
      });
    }
  }

  Future<void> _sendVoicePrompt(String prompt) async {
    LiveVoiceService.stopListening();
    setState(() {
      _state = VoiceState.thinking;
    });

    final stock = widget.stock;
    final ticker = stock['ticker']?.toString() ?? 'BBCA';

    final payloadJson = jsonEncode({
      'prompt': prompt,
      'ticker': ticker,
      'liveVoice': true,
      'voiceEngine': _selectedEngine,
      'stock': {
        'name': stock['name'] ?? '',
        'price': stock['price'],
        'change': stock['change'],
        'changePct': stock['changePct'],
        'sector': stock['sector'] ?? 'Umum',
        'per': stock['per'] ?? '15.0',
        'pbv': stock['pbv'] ?? '2.0',
        'mcap': stock['mcap'] ?? '-',
        'foreignNet': stock['foreignNet'] ?? '-',
      },
    });

    LiveVoiceService.startVoiceStream(
      payloadJson: payloadJson,
      onTextDelta: (delta, accumulated) {
        if (!mounted) return;
        setState(() {
          _aiTranscript = accumulated;
        });
      },
      onFirstAudio: () {
        if (!mounted) return;
        setState(() {
          _state = VoiceState.speaking;
        });
      },
      onAllDone: () {
        if (!mounted) return;
        if (widget.onConversationEnd != null && _aiTranscript.isNotEmpty) {
          widget.onConversationEnd!(prompt, _aiTranscript);
        }
        if (_state == VoiceState.speaking) {
          _startListeningCycle();
        }
      },
      onError: (err) {
        if (!mounted) return;
        debugPrint("Live Voice stream error: $err");
        setState(() {
          _errorMessage = "Koneksi terputus. Silakan coba lagi.";
          _state = VoiceState.idle;
        });
      },
    );
  }

  void _interruptAndListen() {
    AudioService.playClick();
    LiveVoiceService.stopAudio();
    _startListeningCycle();
  }

  void _toggleMic() {
    AudioService.playClick();
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
    if (_isMicMuted) {
      LiveVoiceService.stopListening();
      setState(() {
        _state = VoiceState.idle;
      });
    } else {
      _startListeningCycle();
    }
  }

  Color _getPrimaryColor() {
    switch (_state) {
      case VoiceState.listening:
        return const Color(0xff38bdf8); // Sky Cyan
      case VoiceState.thinking:
        return const Color(0xfff59e0b); // Amber Gold
      case VoiceState.speaking:
        return const Color(0xff10b981); // Emerald Green
      case VoiceState.idle:
        return const Color(0xff64748b); // Slate
    }
  }

  String _getStatusText() {
    switch (_state) {
      case VoiceState.listening:
        return "Mendengarkan pertanyaan Anda...";
      case VoiceState.thinking:
        return "Menganalisa Data Pasar BEI...";
      case VoiceState.speaking:
        return "SAI Analyst sedang berbicara...";
      case VoiceState.idle:
        return _errorMessage.isNotEmpty ? _errorMessage : "Mikrofon Jeda (Ketuk untuk mulai)";
    }
  }

  @override
  Widget build(BuildContext context) {
    final curColor = _getPrimaryColor();
    final ticker = widget.stock['ticker']?.toString() ?? 'BBCA';

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xff090d16),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Color(0xff1e293b), width: 1.5)),
      ),
      child: Stack(
        children: [
          // Background Radial Ambient Glow
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.15),
                  radius: 0.9,
                  colors: [
                    curColor.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Column Content
          SafeArea(
            child: Column(
              children: [
                // Top Header Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: curColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.graphic_eq_rounded, color: curColor, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "SAI Tech AI Solutions",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: curColor,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "Saham $ticker • BEI Live",
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      color: Color(0xff94a3b8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Close button
                      GestureDetector(
                        onTap: () {
                          AudioService.playClick();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Center Animated Glowing Orb
                GestureDetector(
                  onTap: () {
                    if (_state == VoiceState.idle || _state == VoiceState.speaking) {
                      _interruptAndListen();
                    }
                  },
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ripple Ring 1
                        AnimatedBuilder(
                          animation: _rippleController,
                          builder: (context, child) {
                            final scale = 1.0 + (_rippleController.value * 0.45);
                            final opacity = (1.0 - _rippleController.value).clamp(0.0, 1.0) * 0.35;
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: curColor.withOpacity(opacity), width: 1.5),
                                ),
                              ),
                            );
                          },
                        ),
                        // Ripple Ring 2
                        AnimatedBuilder(
                          animation: _rippleController,
                          builder: (context, child) {
                            final shiftVal = (_rippleController.value + 0.5) % 1.0;
                            final scale = 1.0 + (shiftVal * 0.45);
                            final opacity = (1.0 - shiftVal).clamp(0.0, 1.0) * 0.25;
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: curColor.withOpacity(opacity), width: 1.2),
                                ),
                              ),
                            );
                          },
                        ),

                        // Center Pulsing Orb Sphere
                        ScaleTransition(
                          scale: _orbPulse,
                          child: Container(
                            width: 135,
                            height: 135,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white,
                                  curColor,
                                  curColor.withOpacity(0.4),
                                  const Color(0xff090d16),
                                ],
                                stops: const [0.0, 0.4, 0.75, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: curColor.withOpacity(0.55),
                                  blurRadius: 36,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              _state == VoiceState.speaking
                                  ? Icons.volume_up_rounded
                                  : (_state == VoiceState.thinking
                                      ? Icons.hourglass_empty_rounded
                                      : Icons.mic_rounded),
                              color: Colors.black.withOpacity(0.75),
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Status text label
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _getStatusText(),
                    key: ValueKey(_getStatusText()),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: curColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Live Spoken Subtitle Glass Box
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: const BoxConstraints(minHeight: 65, maxHeight: 110),
                  decoration: BoxDecoration(
                    color: const Color(0xff161f30).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_userTranscript.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Anda: ", style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xff38bdf8))),
                              Expanded(
                                child: Text(
                                  _userTranscript,
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (_aiTranscript.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("SAI: ", style: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xff34d399))),
                              Expanded(
                                child: Text(
                                  _aiTranscript,
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xffcbd5e1), height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ] else if (_userTranscript.isEmpty) ...[
                          const Center(
                            child: Text(
                              "Bicaralah, misalnya: 'Bagaimana prospek dan level resisten BBCA?'",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xff64748b)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Bottom Control Action Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mic Mute Button
                      GestureDetector(
                        onTap: _toggleMic,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isMicMuted ? const Color(0xffef4444).withOpacity(0.2) : const Color(0xff1e293b),
                            border: Border.all(
                              color: _isMicMuted ? const Color(0xffef4444) : Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: Icon(
                            _isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                            color: _isMicMuted ? const Color(0xfff87171) : Colors.white,
                            size: 22,
                          ),
                        ),
                      ),

                      // Central Interrupt / Action Pill
                      if (_state == VoiceState.speaking)
                        GestureDetector(
                          onTap: _interruptAndListen,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                            decoration: BoxDecoration(
                              color: const Color(0xffef4444).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xffef4444).withOpacity(0.5)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.stop_circle_rounded, color: Color(0xfff87171), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  "Hentikan Suara",
                                  style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xfff87171)),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () {
                            if (_state == VoiceState.listening) {
                              LiveVoiceService.stopListening();
                              setState(() => _state = VoiceState.idle);
                            } else {
                              _startListeningCycle();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                            decoration: BoxDecoration(
                              color: curColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: curColor.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _state == VoiceState.listening ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: curColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _state == VoiceState.listening ? "Jeda Bicara" : "Mulai Bicara",
                                  style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: curColor),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Switch to Text Chat Button
                      GestureDetector(
                        onTap: () {
                          AudioService.playClick();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xff1e293b),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: const Icon(Icons.keyboard_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
