import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kursus_saham/data/avatar_data.dart';
import 'package:kursus_saham/state/app_state.dart';
import 'package:kursus_saham/widgets/leaderboard_modal.dart';
import 'package:kursus_saham/widgets/rank_progression_modal.dart';
import 'package:kursus_saham/widgets/xp_reward_modal.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'app_language': 'id'});
  });

  group('Phase 3: Progression & Leaderboard Unit Tests', () {
    test('AppState.resetProgress() resets claimed XP milestones and streak shields', () {
      final appState = AppState();
      try {
        // Add XP so that milestone 50 can be claimed
        appState.claimDailyReward(1, xpReward: 100, petirReward: 1);
        expect(appState.canClaimMilestone(50), isTrue);

        final claimed = appState.claimXpMilestone(50);
        expect(claimed, isTrue);
        expect(appState.isMilestoneClaimed(50), isTrue);

        // Call resetProgress()
        appState.resetProgress();

        expect(appState.claimedXpMilestones, isEmpty);
        expect(appState.isMilestoneClaimed(50), isFalse);
        expect(appState.streakShields, equals(0));
        expect(appState.xp, equals(0));
        expect(appState.unlockedAvatars, equals(['bull', 'chart', 'wallet']));
      } finally {
        appState.dispose();
      }
    });

    test('AvatarData contains all 12 preset avatar IDs with icons and colors', () {
      final expectedAvatars = [
        'bull', 'bear', 'chart', 'vip', 'bandar', 'champion',
        'rocket', 'fire', 'shield', 'academy', 'wallet', 'star'
      ];

      for (final id in expectedAvatars) {
        final icon = AvatarData.getIcon(id);
        final color = AvatarData.getColor(id);
        expect(icon, isNotNull);
        expect(color, isNotNull);
      }
    });
  });

  group('Phase 3: Widgets Light & Dark Theme Rendering Tests', () {
    testWidgets('RankProgressionModal renders in Light and Dark mode with bilingual title', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appState = AppState();
      try {
        // Test Indonesian
        appState.setLanguage('id');
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: appState,
            child: const MaterialApp(
              themeMode: ThemeMode.light,
              home: Scaffold(
                body: SizedBox(
                  height: 800,
                  width: 450,
                  child: RankProgressionModal(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Jenjang Karier'), findsOneWidget);
        expect(find.text('Semua Tingkatan Trader'), findsOneWidget);

        // Switch to English and Dark mode
        appState.setLanguage('en');
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: appState,
            child: MaterialApp(
              themeMode: ThemeMode.dark,
              darkTheme: ThemeData.dark(),
              home: const Scaffold(
                body: SizedBox(
                  height: 800,
                  width: 450,
                  child: RankProgressionModal(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Career Progression'), findsOneWidget);
        expect(find.text('All Trader Tiers'), findsOneWidget);
      } finally {
        appState.dispose();
      }
    });

    testWidgets('XpRewardModal renders milestones and adapts to English locale', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appState = AppState();
      try {
        // Test Indonesian
        appState.setLanguage('id');
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: appState,
            child: const MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  height: 800,
                  width: 450,
                  child: XpRewardModal(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Jalur Hadiah XP'), findsOneWidget);
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);

        // Test English
        appState.setLanguage('en');
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: appState,
            child: const MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  height: 800,
                  width: 450,
                  child: XpRewardModal(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('XP Reward Path'), findsOneWidget);
      } finally {
        appState.dispose();
      }
    });

    testWidgets('LeaderboardModal renders header, reload button, and bottom bar', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appState = AppState();
      try {
        appState.setLanguage('id');

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: appState,
            child: const MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  height: 800,
                  width: 450,
                  child: LeaderboardModal(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Liga Trader BEI'), findsOneWidget);
        expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);

        // Test English
        appState.setLanguage('en');
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: appState,
            child: const MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  height: 800,
                  width: 450,
                  child: LeaderboardModal(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('IDX Trader League'), findsOneWidget);
      } finally {
        appState.dispose();
      }
    });
  });
}
