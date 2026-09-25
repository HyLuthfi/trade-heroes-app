import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_translations.dart';
import '../services/audio_service.dart';
import '../state/app_state.dart';
import 'ad_overlay.dart';
import 'vip_pass_modal.dart';

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
    }
  }

  void _confirmExit(AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff0f172a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xffef4444), width: 1.5),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xffef4444), size: 24),
            SizedBox(width: 8),
            Text("Keluar dari Kuis?", style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          "Jika Anda menyerah sekarang sebelum menyelesaikan kuis, Anda akan dianggap GAGAL dan kehilangan 1 Nyawa Petir.",
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xffcbd5e1), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("LANJUTKAN KUIS", style: TextStyle(color: Color(0xff10b981), fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffef4444)),
            onPressed: () {
              Navigator.of(ctx).pop();
              appState.deductPetir(); // Candy crush style: forfeit loses 1 life
              Navigator.of(context).pop();
            },
            child: const Text("MENYERAH (-1 PETIR)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
          ),
        ],
      ),
    );
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
    final int totalQuestions = widget.questions.length;
    final double accuracy = totalQuestions > 0 ? _scoreCorrect / totalQuestions : 0.0;

    // Candy Crush Style Star Thresholds:
    // 3 Stars: 100% correct (Anti-Boncos)
    // 2 Stars: >= 66% correct (misal 2/3 atau 4/5)
    // 1 Star: >= 33% correct (minimal 1 soal benar)
    // 0 Star: 0% correct (GAGAL)
    int stars = 0;
    if (_wrongCount == 0 && _scoreCorrect == totalQuestions) {
      stars = 3;
    } else if (accuracy >= 0.66) {
      stars = 2;
    } else if (_scoreCorrect >= 1) {
      stars = 1;
    }

    final bool isPassed = stars >= 1;
    final bool isFirstClear = !appState.completedLevels.contains(widget.levelId);

    if (isPassed) {
      // Candy Crush: Lulus -> Nyawa petir TIDAK BERKURANG! Next level terbuka!
      final int xpPerCorrect = isFirstClear ? 10 : 3;
      final xpReward = _scoreCorrect * xpPerCorrect;

      appState.completeLevel(widget.levelId, stars: stars, correctAnswers: _scoreCorrect);
      if (stars == 3) {
        appState.unlockAntiBoncos(context);
      }
      appState.addXp(xpReward, context);
      AudioService.playReward();

      Navigator.of(context).pop();
      AdOverlay.show(context, () {
        _showResultDialog(appState, xpReward, stars, isFirstClear, isPassed: true);
      });
    } else {
      // Candy Crush: GAGAL -> Hilang 1 Nyawa Petir ⚡, level berikutnya TETAP TERKUNCI!
      appState.deductPetir();
      appState.recordLevelAttempt(widget.levelId, _scoreCorrect);
      AudioService.playWrong();

      Navigator.of(context).pop();
      _showResultDialog(appState, 0, 0, isFirstClear, isPassed: false);
    }
  }

  void _showResultDialog(AppState appState, int xpReward, int stars, bool isFirstClear, {required bool isPassed}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String tr(String key, {Map<String, String> params = const {}}) =>
        AppTranslations.text(appState.language, key, params: params);
    final isEn = appState.language.startsWith('en');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xff0f172a) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isPassed ? const Color(0xfff59e0b) : const Color(0xffef4444),
            width: 1.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Emas (Lulus) atau Patah Hati (Gagal)
            Icon(
              isPassed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
              color: isPassed ? const Color(0xfff59e0b) : const Color(0xffef4444),
              size: 60,
            ),
            const SizedBox(height: 10),

            // Candy Crush 3-Star Header Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  stars >= 1 ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: stars >= 1 ? const Color(0xfffbbf24) : const Color(0xff475569),
                  size: 28,
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Icon(
                    stars >= 2 ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: stars >= 2 ? const Color(0xfffbbf24) : const Color(0xff475569),
                    size: 38,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  stars >= 3 ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: stars >= 3 ? const Color(0xfffbbf24) : const Color(0xff475569),
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 6),

            Text(
              isPassed
                  ? (stars == 3 ? (isEn ? "PERFECT PASS!" : "LULUS SEMPURNA!") : (isEn ? "LEVEL PASSED!" : "LEVEL LULUS!"))
                  : (isEn ? "NOT PASSED YET!" : "BELUM LULUS!"),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isPassed ? const Color(0xfff59e0b) : const Color(0xffef4444),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPassed
                  ? tr(
                      'quiz.completed_desc',
                      params: {
                        'title': widget.title,
                        'correct': '$_scoreCorrect',
                        'total': '${widget.questions.length}',
                      },
                    )
                  : (isEn
                      ? "Unfortunately, you did not meet the 1-star requirement. 1 lightning heart deducted. Study again and retry!"
                      : "Sayang sekali, Anda belum memenuhi syarat minimal 1 bintang. Nyawa petir berkurang 1. Pelajari materi lagi dan coba ulangi!"),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xffcbd5e1) : const Color(0xff475569),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Stats Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isPassed
                    ? (isDark ? const Color(0xff022c22) : const Color(0xfff0fdf4))
                    : (isDark ? const Color(0xff450a0a) : const Color(0xfffef2f2)),
                border: Border.all(
                  color: isPassed
                      ? const Color(0xff059669).withOpacity(0.5)
                      : const Color(0xffdc2626).withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        isPassed
                            ? (isFirstClear ? tr('quiz.xp_earned') : (isEn ? "Practice XP" : "XP Latihan"))
                            : (isEn ? "Penalty" : "Penalti"),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPassed ? "+$xpReward XP" : (isEn ? "-1 Life" : "-1 Petir"),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isPassed ? const Color(0xfff59e0b) : const Color(0xffef4444),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xff34d399),
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
                backgroundColor: isPassed ? const Color(0xff059669) : const Color(0xffef4444),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                if (!isPassed && appState.petir <= 0 && !appState.isPremium) {
                  _showRefillLivesModal(appState);
                }
              },
              child: Text(
                isPassed ? tr('quiz.continue_great') : (isEn ? "TRY AGAIN" : "COBA LAGI"),
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
                          onTap: () => _confirmExit(appState),
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
                                  final isSelected = (_selectedOptionIdx == idx);
                                  final isCorrectAnswer = (qData['a'] == idx);
                                  final bool showCorrectOption = _checked && (isCorrectAnswer && (_isAnswerCorrect || appState.isPremium));

                                  Color cardBg;
                                  Color cardShadow;
                                  Color cardBorder;
                                  Color letterBg;
                                  Color letterText;
                                  Color optionTextColor;

                                  if (_checked) {
                                    if (showCorrectOption) {
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
                                                if (showCorrectOption)
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
                                _isAnswerCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: _isAnswerCorrect
                                    ? (isDark ? const Color(0xff34d399) : const Color(0xff059669))
                                    : (isDark ? const Color(0xfffca5a5) : const Color(0xffdc2626)),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isAnswerCorrect
                                    ? "${tr('quiz.correct_feedback')} (+10 XP)"
                                    : tr('quiz.wrong_feedback'),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: _isAnswerCorrect
                                      ? (isDark ? const Color(0xff34d399) : const Color(0xff065f46))
                                      : (isDark ? const Color(0xfffca5a5) : const Color(0xff991b1b)),
                                ),
                              ),
                              if (!_isAnswerCorrect && appState.isPremium) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xfff59e0b).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xfff59e0b).withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.workspace_premium_rounded, color: Color(0xfffbbf24), size: 13),
                                      SizedBox(width: 4),
                                      Text(
                                        "VIP INSIGHT",
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xfffbbf24),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_isAnswerCorrect) ...[
                            Text(
                              qData['explanation'],
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: Colors.white,
                                height: 1.4,
                              ),
                            ),
                          ] else if (appState.isPremium) ...[
                            // User Subs: Muncul Jawaban Benar & Pembahasan
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: "Jawaban Benar: ",
                                          style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff6ee7b7)),
                                        ),
                                        TextSpan(
                                          text: "${qData['type'] == 'pilgan' ? qData['options'][qData['a']] : qData['a']}",
                                          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    qData['explanation'],
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xffcbd5e1), height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // User Non-Subs: TIDAK muncul jawaban benar & pembahasan, melainkan info netral + teaser VIP
                            const Text(
                              "Pilihan Anda belum tepat. Pelajari kembali materi modul untuk menemukan jawaban yang benar saat mengulang kuis.",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.5,
                                color: Color(0xffe2e8f0),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => VipPassModal.show(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xff0f172a).withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xfff59e0b).withOpacity(0.4), width: 1.0),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock_rounded, color: Color(0xfffbbf24), size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            "Kunci Jawaban & Pembahasan Terkunci",
                                            style: TextStyle(fontFamily: 'Outfit', fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          Text(
                                            "Buka pembahasan & kunci jawaban instan dengan VIP Pass",
                                            style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xff94a3b8)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xfffbbf24), size: 12),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
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
