import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_translations.dart';
import '../services/audio_service.dart';
import '../state/app_state.dart';
import 'ad_overlay.dart';

class QuizOverlay extends StatefulWidget {
  final int levelId;
  final String title;
  final List<Map<String, dynamic>> questions;

  const QuizOverlay({
    Key? key,
    required this.levelId,
    required this.title,
    required this.questions,
  }) : super(key: key);

  static void start(BuildContext context, int levelId, String title, List<Map<String, dynamic>> questions) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => QuizOverlay(
          levelId: levelId,
          title: title,
          questions: questions,
        ),
      ),
    );
  }

  @override
  State<QuizOverlay> createState() => _QuizOverlayState();
}

class _QuizOverlayState extends State<QuizOverlay> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _scoreCorrect = 0;
  int _wrongCount = 0;
  int? _selectedOptionIdx;
  final TextEditingController _essayController = TextEditingController();
  bool _checked = false;
  bool _isAnswerCorrect = false;

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _essayController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward(from: 0.0);
  }

  void _checkAnswer(AppState appState) {
    final qData = widget.questions[_currentIndex];
    bool correct = false;

    if (qData['type'] == 'pilgan') {
      correct = (_selectedOptionIdx == qData['a']);
    } else {
      final userAns = _essayController.text.trim().toLowerCase();
      final target = (qData['a'] as String).toLowerCase();
      final acceptedList = (qData['accepted'] as List?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          [];
      correct = (userAns == target || acceptedList.contains(userAns));
    }

    setState(() {
      _checked = true;
      _isAnswerCorrect = correct;
    });

    if (correct) {
      _scoreCorrect++;
      AudioService.playCorrect();
    } else {
      _wrongCount++;
      _triggerShake();
      AudioService.playWrong();
      final hasLives = appState.deductPetir();
      if (!hasLives && !appState.isPremium) {
        // Lives ran out mid quiz
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop();
          _showRefillLivesModal(appState);
        });
      }
    }
  }

  void _nextQuestion(AppState appState) {
    AudioService.playConfirm();
    if (_currentIndex + 1 < widget.questions.length) {
      setState(() {
        _currentIndex++;
        _selectedOptionIdx = null;
        _essayController.clear();
        _checked = false;
      });
    } else {
      // Completed Quiz
      _finishQuiz(appState);
    }
  }

  void _finishQuiz(AppState appState) {
    final xpReward = _scoreCorrect * 10;
    appState.completeLevel(widget.levelId);
    
    // Award Anti Boncos if no mistakes
    if (_wrongCount == 0) {
      appState.unlockAntiBoncos(context);
    }
    
    appState.addXp(xpReward, context);
    AudioService.playReward();
    
    Navigator.of(context).pop();

    // Trigger Ad popup simulation
    AdOverlay.show(context, () {
      _showResultDialog(appState, xpReward);
    });
  }

  void _showResultDialog(AppState appState, int xpReward) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String tr(String key, {Map<String, String> params = const {}}) =>
        AppTranslations.text(appState.language, key, params: params);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xff0f172a) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xfff59e0b), width: 1.5),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded, color: Color(0xfff59e0b), size: 64),
            const SizedBox(height: 12),
            Text(
              tr('quiz.completed_title'),
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xfff59e0b),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                'quiz.completed_desc',
                params: {
                  'title': widget.title,
                  'correct': '$_scoreCorrect',
                  'total': '${widget.questions.length}',
                },
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xffcbd5e1) : const Color(0xff475569),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff022c22) : const Color(0xfff0fdf4),
                border: Border.all(color: const Color(0xff059669).withOpacity(0.5)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        tr('quiz.xp_earned'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "+$xpReward XP",
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xfff59e0b),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        tr('quiz.lives_remaining'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appState.isPremium
                            ? tr('quiz.lives_unlimited')
                            : tr('quiz.lives_count', params: {'count': '${appState.petir}'}),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xffef4444),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff059669),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                tr('quiz.continue_great'),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRefillLivesModal(AppState appState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String tr(String key, {Map<String, String> params = const {}}) =>
        AppTranslations.text(appState.language, key, params: params);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xff0f172a) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xffef4444), width: 1.5),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: Color(0xffef4444), size: 64),
            const SizedBox(height: 12),
            Text(
              tr('quiz.lives_empty_title'),
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xffef4444),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('quiz.lives_empty_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xffcbd5e1) : const Color(0xff475569),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xff10b981), width: 1.5),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                AdOverlay.show(context, () {
                  appState.refillOnePetir();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('quiz.refill_success'))),
                  );
                });
              },
              child: Text(
                tr('quiz.watch_ad_refill'),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Color(0xff10b981),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffea580c),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                appState.upgradeToPremium(context);
              },
              child: Text(
                tr('quiz.upgrade_premium_unlimited'),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final language = appState.language;
    String tr(String key, {Map<String, String> params = const {}}) =>
        AppTranslations.text(language, key, params: params);

    final qData = widget.questions[_currentIndex];
    final double progress = (_currentIndex + 1) / widget.questions.length;

    // Shake offset animation calculation
    final Offset shakeOffset = Offset(
      _shakeController.value < 0.05
          ? 0
          : _shakeController.value < 0.25
              ? -8
              : _shakeController.value < 0.45
                  ? 8
                  : _shakeController.value < 0.65
                      ? -8
                      : _shakeController.value < 0.85
                          ? 8
                          : 0,
      0,
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xff022c22) : const Color(0xfff8fafc),
      body: Stack(
        children: [
          // 1. Background Image Matching Main Page
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              opacity: AlwaysStoppedAnimation(isDark ? 0.35 : 0.12),
            ),
          ),
          // Dark / Light Nature Glass Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xff064e3b).withOpacity(0.88),
                          const Color(0xff022c22).withOpacity(0.92),
                          const Color(0xff0f172a).withOpacity(0.95),
                        ]
                      : [
                          const Color(0xffecfdf5).withOpacity(0.90),
                          const Color(0xfff1f5f9).withOpacity(0.94),
                          const Color(0xfff8fafc).withOpacity(0.98),
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 2. Main Scaffold Body Content
          SafeArea(
            child: AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                return Transform.translate(
                  offset: shakeOffset,
                  child: child,
                );
              },
              child: Column(
                children: [
                  // 3D Header Card (Adapts to Light / Dark Mode)
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? null : Colors.white,
                      gradient: isDark
                          ? const LinearGradient(
                              colors: [Color(0xff059669), Color(0xff0f766e)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.25) : const Color(0xffe2e8f0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? const Color(0xff047857).withOpacity(0.4)
                              : Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Close Button (Golden Rim 3D)
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) {
                                final dialogIsDark = Theme.of(ctx).brightness == Brightness.dark;
                                return AlertDialog(
                                  backgroundColor: dialogIsDark ? const Color(0xff0f172a) : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: const BorderSide(color: Color(0xff059669), width: 1.2),
                                  ),
                                  title: Text(
                                    tr('quiz.exit_title'),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: dialogIsDark ? Colors.white : const Color(0xff0f172a),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    tr('quiz.exit_desc'),
                                    style: TextStyle(
                                      color: dialogIsDark ? const Color(0xffcbd5e1) : const Color(0xff475569),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: Text(
                                        tr('quiz.cancel'),
                                        style: const TextStyle(
                                          color: Color(0xff94a3b8),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(
                                        tr('quiz.exit_confirm'),
                                        style: const TextStyle(
                                          color: Color(0xffef4444),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xff022c22) : const Color(0xfff1f5f9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xfff59e0b).withOpacity(0.6)
                                    : const Color(0xffcbd5e1),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: isDark ? Colors.white : const Color(0xff334155),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Segmented Progress Bar
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    widget.title.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? const Color(0xfff59e0b) : const Color(0xff059669),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Text(
                                    "${_currentIndex + 1} / ${widget.questions.length}",
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : const Color(0xff0f172a),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Stack(
                                children: [
                                  Container(
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.black.withOpacity(0.35) : const Color(0xffe2e8f0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  AnimatedFractionallySizedBox(
                                    duration: const Duration(milliseconds: 300),
                                    widthFactor: progress,
                                    child: Container(
                                      height: 14,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xfff59e0b), Color(0xfffbbf24)],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xfff59e0b).withOpacity(0.5),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Petir Life Badge (⚡)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xff022c22) : const Color(0xfffef2f2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xffef4444).withOpacity(isDark ? 0.7 : 0.4),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded, color: Color(0xffef4444), size: 16),
                              const SizedBox(width: 2),
                              Text(
                                appState.isPremium ? "∞" : "${appState.petir}",
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xffef4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Question & Options Main Area
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question Glass Card Container
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xff0f172a).withOpacity(0.88) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xff059669).withOpacity(0.5)
                                    : const Color(0xff10b981).withOpacity(0.35),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category Golden Pill Tag
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xfff59e0b).withOpacity(0.2)
                                        : const Color(0xfffef3c7),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? const Color(0xfff59e0b) : const Color(0xffd97706),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.psychology_rounded,
                                        color: isDark ? const Color(0xfff59e0b) : const Color(0xffb45309),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        qData['type'] == 'pilgan'
                                            ? tr('quiz.multiple_choice')
                                            : tr('quiz.essay'),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? const Color(0xfff59e0b) : const Color(0xffb45309),
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Question Text
                                Text(
                                  qData['q'],
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : const Color(0xff0f172a),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // 3D Options List (Matching Light / Dark Theme)
                          if (qData['type'] == 'pilgan')
                            Column(
                              children: List.generate(
                                (qData['options'] as List).length,
                                (idx) {
                                  final optionLetter = String.fromCharCode(65 + idx);
                                  final isSelected = _selectedOptionIdx == idx;
                                  final isCorrectAnswer = (qData['a'] == idx);

                                  Color cardBg;
                                  Color cardShadow;
                                  Color cardBorder;
                                  Color letterBg;
                                  Color letterText;
                                  Color optionTextColor;

                                  if (_checked) {
                                    if (isCorrectAnswer) {
                                      cardBg = const Color(0xff059669);
                                      cardShadow = const Color(0xff047857);
                                      cardBorder = const Color(0xff34d399);
                                      letterBg = const Color(0xff047857);
                                      letterText = Colors.white;
                                      optionTextColor = Colors.white;
                                    } else if (isSelected && !isCorrectAnswer) {
                                      cardBg = const Color(0xffdc2626);
                                      cardShadow = const Color(0xff991b1b);
                                      cardBorder = const Color(0xfff87171);
                                      letterBg = const Color(0xff991b1b);
                                      letterText = Colors.white;
                                      optionTextColor = Colors.white;
                                    } else {
                                      cardBg = isDark ? const Color(0xff0f172a).withOpacity(0.9) : Colors.white;
                                      cardShadow = isDark ? const Color(0xff022c22) : const Color(0xffe2e8f0);
                                      cardBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0);
                                      letterBg = isDark ? const Color(0xff1e293b) : const Color(0xfff1f5f9);
                                      letterText = const Color(0xff94a3b8);
                                      optionTextColor = isDark ? Colors.white.withOpacity(0.4) : const Color(0xff94a3b8);
                                    }
                                  } else if (isSelected) {
                                    cardBg = const Color(0xff059669);
                                    cardShadow = const Color(0xff047857);
                                    cardBorder = const Color(0xfff59e0b);
                                    letterBg = const Color(0xff047857);
                                    letterText = const Color(0xfffbbf24);
                                    optionTextColor = Colors.white;
                                  } else {
                                    cardBg = isDark ? const Color(0xff0f172a).withOpacity(0.9) : Colors.white;
                                    cardShadow = isDark ? const Color(0xff022c22) : const Color(0xffe2e8f0);
                                    cardBorder = isDark ? Colors.white.withOpacity(0.15) : const Color(0xffe2e8f0);
                                    letterBg = isDark ? const Color(0xff1e293b) : const Color(0xfff1f5f9);
                                    letterText = isDark ? const Color(0xfff59e0b) : const Color(0xffd97706);
                                    optionTextColor = isDark ? Colors.white : const Color(0xff0f172a);
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: GestureDetector(
                                      onTap: _checked
                                          ? null
                                          : () {
                                              AudioService.playClick();
                                              setState(() {
                                                _selectedOptionIdx = idx;
                                              });
                                            },
                                      child: Stack(
                                        children: [
                                          // 3D Shadow Base
                                          Positioned.fill(
                                            top: 3.5,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: cardShadow,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                            ),
                                          ),
                                          // Card Face
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 150),
                                            margin: EdgeInsets.only(bottom: isSelected && !_checked ? 0 : 3.5),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                            decoration: BoxDecoration(
                                              color: cardBg,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: cardBorder, width: isSelected ? 1.8 : 1.2),
                                              boxShadow: [
                                                if (isSelected && !_checked)
                                                  BoxShadow(
                                                    color: const Color(0xff059669).withOpacity(0.5),
                                                    blurRadius: 8,
                                                  ),
                                                if (!isSelected && !_checked && !isDark)
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.04),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                // Letter Badge Bubble
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: letterBg,
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(
                                                      color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xffcbd5e1),
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    optionLetter,
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w900,
                                                      color: letterText,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                // Option Text
                                                Expanded(
                                                  child: Text(
                                                    qData['options'][idx],
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      color: optionTextColor,
                                                    ),
                                                  ),
                                                ),
                                                if (_checked && isCorrectAnswer)
                                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                                                if (_checked && isSelected && !isCorrectAnswer)
                                                  const Icon(Icons.cancel_rounded, color: Colors.white, size: 22),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            TextField(
                              controller: _essayController,
                              enabled: !_checked,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xff0f172a),
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: tr('quiz.essay_hint'),
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white.withOpacity(0.35) : const Color(0xff94a3b8),
                                ),
                                filled: true,
                                fillColor: isDark ? const Color(0xff0f172a) : Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? const Color(0xff059669).withOpacity(0.5)
                                        : const Color(0xff10b981).withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xfff59e0b), width: 2),
                                ),
                              ),
                              onChanged: (text) {
                                setState(() {});
                              },
                            ),

                          const SizedBox(height: 8),

                          // Star Favorite Button
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                appState.toggleFavorite(widget.levelId, _currentIndex, qData['q']);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xff0f172a) : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xffcbd5e1),
                                  ),
                                  boxShadow: [
                                    if (!isDark)
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      appState.isFavorited(widget.levelId, _currentIndex) ? Icons.star_rounded : Icons.star_border_rounded,
                                      color: const Color(0xfff59e0b),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      appState.isFavorited(widget.levelId, _currentIndex)
                                          ? tr('quiz.favorited')
                                          : tr('quiz.save_favorite'),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: isDark ? const Color(0xffcbd5e1) : const Color(0xff475569),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Feedback Drawer & Action Bar
                  if (_checked)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      decoration: BoxDecoration(
                        color: _isAnswerCorrect
                            ? (isDark ? const Color(0xff064e3b) : const Color(0xffecfdf5))
                            : (isDark ? const Color(0xff7f1d1d) : const Color(0xfffef2f2)),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                        border: Border(
                          top: BorderSide(
                            color: _isAnswerCorrect
                                ? (isDark ? const Color(0xfff59e0b) : const Color(0xff10b981))
                                : (isDark ? const Color(0xffef4444) : const Color(0xffdc2626)),
                            width: 2,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isAnswerCorrect ? Icons.stars_rounded : Icons.cancel_rounded,
                                color: _isAnswerCorrect
                                    ? (isDark ? const Color(0xfff59e0b) : const Color(0xff059669))
                                    : (isDark ? const Color(0xfffca5a5) : const Color(0xffdc2626)),
                                size: 26,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _isAnswerCorrect
                                    ? tr('quiz.correct_feedback')
                                    : tr('quiz.wrong_feedback'),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: _isAnswerCorrect
                                      ? (isDark ? const Color(0xfff59e0b) : const Color(0xff065f46))
                                      : (isDark ? const Color(0xfffca5a5) : const Color(0xff991b1b)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isAnswerCorrect
                                ? qData['explanation']
                                : "${tr('quiz.correct_answer')}: ${qData['type'] == 'pilgan' ? qData['options'][qData['a']] : qData['a']}\n${qData['explanation']}",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xff1e293b),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // 3D Continue Button
                          GestureDetector(
                            onTap: () => _nextQuestion(appState),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  top: 4,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _isAnswerCorrect ? const Color(0xff047857) : const Color(0xff991b1b),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _isAnswerCorrect ? const Color(0xff059669) : const Color(0xffef4444),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    tr('quiz.continue_button'),
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // Bottom 3D Check Button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xff0f172a).withOpacity(0.95) : Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xffe2e8f0),
                            width: 1,
                          ),
                        ),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: (_selectedOptionIdx == null && qData['type'] == 'pilgan') ||
                                (qData['type'] == 'esai' && _essayController.text.trim().isEmpty)
                            ? null
                            : () => _checkAnswer(appState),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              top: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: (_selectedOptionIdx == null && qData['type'] == 'pilgan') ||
                                          (qData['type'] == 'esai' && _essayController.text.trim().isEmpty)
                                      ? (isDark ? const Color(0xff1e293b) : const Color(0xffcbd5e1))
                                      : const Color(0xff047857),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              height: 52,
                              decoration: BoxDecoration(
                                color: (_selectedOptionIdx == null && qData['type'] == 'pilgan') ||
                                        (qData['type'] == 'esai' && _essayController.text.trim().isEmpty)
                                    ? (isDark ? const Color(0xff334155).withOpacity(0.5) : const Color(0xffe2e8f0))
                                    : const Color(0xff059669),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: (_selectedOptionIdx == null && qData['type'] == 'pilgan') ||
                                          (qData['type'] == 'esai' && _essayController.text.trim().isEmpty)
                                      ? Colors.transparent
                                      : const Color(0xfff59e0b),
                                  width: 1.2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bolt_rounded,
                                    color: (_selectedOptionIdx == null && qData['type'] == 'pilgan') ||
                                            (qData['type'] == 'esai' && _essayController.text.trim().isEmpty)
                                        ? (isDark ? const Color(0xff64748b) : const Color(0xff94a3b8))
                                        : Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tr('quiz.check_answer'),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: (_selectedOptionIdx == null && qData['type'] == 'pilgan') ||
                                              (qData['type'] == 'esai' && _essayController.text.trim().isEmpty)
                                          ? (isDark ? const Color(0xff64748b) : const Color(0xff94a3b8))
                                          : Colors.white,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
