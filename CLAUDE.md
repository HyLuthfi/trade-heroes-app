# CLAUDE.md — Trade Heroes Engineering Instructions

## 1. Workspace Boundary
- **PROJECT_ROOT**: `G:\Semester 7\Project\Trades Hero`
- **STRICT RULE**: All implementation, edits, file creation, testing, and automation MUST remain inside this repository. Never inspect, modify, or delete files outside this directory. Never touch C:\, G:\Game, Steam, or other Semester folders.

## 2. Technical Stack & Environment
- **Framework**: Flutter 3.47.5 (channel stable)
- **Language**: Dart 3.13.4
- **Flutter Binary**: `G:\flutter\bin\flutter.bat`
- **Python Binary**: `G:\laragonNew\bin\python\python-3.10\python.exe`
- **Target Platforms**: Android, iOS, Web
- **Web Local Server**: `python server.py` on port 20170 (serves `build/web`, proxies `/api/yahoo` to bypass CORS)

## 3. Architecture & State Management
- **Pattern**: Centralized Provider (`ChangeNotifier`) via `AppState` in `lib/state/app_state.dart`.
- **DO NOT** rewrite or migrate state management to Bloc, Riverpod, or GetX unless explicitly commanded by user.
- **Backend**: Supabase (`lib/services/supabase_service.dart`) for Auth (Email & Google), DB (`profiles`), and Storage (`avatars`).
- **Local Persistence**: Dual-layer with `SharedPreferences` for offline cache + background cloud sync.
- **Market Data**: `MarketDataService` fetches BEI stock candles via `/api/yahoo` local proxy.
- **Audio Engine**: `AudioService` uses JS interop on Web (`window.playTradeSound`) and `audioplayers` on mobile.

## 4. Key Directories
```text
lib/
├── main.dart          # Entry point, Theme, DeviceFrame (iPhone mockup on desktop web)
├── services/          # SupabaseService, MarketDataService, AudioService
├── state/             # AppState (XP, streak, lives, levels, portfolio, trade logic)
├── views/             # HomeView, KuisView, MarketView, MateriView, ProfileView, AdminConsoleView, LoginView, SplashView
└── widgets/           # QuizOverlay, AdOverlay, DailyRewardModal, VipPassModal, AvatarPickerModal
```

## 5. Quality & Verification Commands
Always run these before completing any task:
- Static Analysis: `G:\flutter\bin\flutter.bat analyze`
- Automated Tests: `G:\flutter\bin\flutter.bat test`
- Format Code: `G:\flutter\bin\flutter.bat format lib/ test/`
- Rebuild Web (if UI modified): `G:\flutter\bin\flutter.bat build web --release`

## 6. Engineering Discipline & Safety
- **Inspect First**: Read target files and trace state flow before writing any code.
- **Async Safety**: Always check `if (mounted)` after `await` before accessing `BuildContext` or calling `setState()`.
- **Resource Disposal**: Always call `dispose()` on `TextEditingController`, `AnimationController`, `ScrollController`, `Timer`, and stream subscriptions.
- **Security**: Never commit service role keys or sensitive tokens. UI visibility (like `isAdmin`) is not authorization; respect backend security rules.
- **Review Diff**: Before finishing, inspect `git diff` for unintended edits, formatting issues, or regressions.
- **Bug Hunt**: Actively test edge cases (empty states, zero lots, insufficient balance, network failure, rapid taps).
