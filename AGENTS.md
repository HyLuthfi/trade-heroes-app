# AGENTS.md — OpenCode Instructions for Trade Heroes

Operational guidance, toolchain quirks, and hard invariants for OpenCode sessions in this repository.

## 1. Workspace & Operational Boundary
- **Root Directory**: `G:\Semester 7\Project\Trades Hero` (Windows host, PowerShell 5.1).
- **Strict Boundary**: All edits, tests, and file creations MUST remain inside this directory. Never access, inspect, or modify paths outside (e.g. `C:\`, `G:\Game`, `G:\laragonNew`, `Steam`, or parent folders).
- **Git Safety**: Do not run destructive git commands (`git reset --hard`, `git push --force`, or untracked checkouts). Never auto-commit or push without explicit user instruction. Stage only relevant files.

## 2. Environment & Toolchain Binaries
- **Flutter Binary**: `& "G:\flutter\bin\flutter.bat"` (Flutter 3.47.5, Dart 3.13.4).
- **Python Binary**: `& "G:\laragonNew\bin\python\python-3.10\python.exe"` or `python` (Python 3.10).
- **Local Web Server**: `python server.py` runs on port `20170` (serves `build/web` and proxies `/api/yahoo` to avoid CORS).
- **Web Rebuild Requirement**: When modifying UI or Dart code for web preview, rebuild the bundle so `server.py` serves fresh assets:
  ```powershell
  & "G:\flutter\bin\flutter.bat" build web --no-tree-shake-icons
  ```
- **Web Preview URL**: `http://localhost:20170`

## 3. Architecture & Code Invariants
- **State Management**: Centralized Provider via `AppState` (`lib/state/app_state.dart`). Do NOT migrate or introduce Bloc, Riverpod, or GetX unless explicitly commanded by the user.
- **Backend & Auth**: Supabase via `SupabaseService` (`lib/services/supabase_service.dart`) for Auth, DB (`profiles`), and Storage (`avatars`).
- **Persistence**: Dual-layer with `SharedPreferences` for local offline cache + background cloud sync.
- **Localization (i18n)**: Zero-dependency engine in `lib/l10n/` (`app_translations.dart`, `id.dart`, `en.dart`). Keep dictionary key parity between ID and EN. Uses safe fallback (`Locale -> Dynamic Dict -> Static EN -> Static ID -> Raw Text`).
- **Kuis Background Invariant**: The roadmap background in `lib/views/kuis_view.dart` (`assets/images/background.png`) MUST stay 100% transparent (`Colors.transparent`). Never place solid/opaque white or dark layers over it.
- **Market & Financial Invariants**: 1 lot = 100 shares. BEI fees: buy = 0.15%, sell = 0.25%. Initial cash = Rp 100,000,000. Do not alter trading formulas or scoring algorithms (`xp = correct * 10`).
- **Audio Engine Quirk**: `lib/services/audio_service.dart` uses `dart:js_interop` on Web and `audioplayers` on native. Top-level `dart:js_interop` will fail in native VM `flutter test` runs if imported directly without conditional imports.

## 4. Verification & Testing Commands
Always verify with real toolchain commands in Windows PowerShell:
- **Static Analysis**:
  ```powershell
  & "G:\flutter\bin\flutter.bat" analyze
  ```
- **Safe Unit & Widget Tests** (avoids Web-only JS interop VM blocker):
  ```powershell
  & "G:\flutter\bin\flutter.bat" test test/l10n/ test/views/ test/state/
  ```
- **Code Formatter**:
  ```powershell
  & "G:\flutter\bin\flutter.bat" format lib/ test/
  ```
- **Web Compilation**:
  ```powershell
  & "G:\flutter\bin\flutter.bat" build web --no-tree-shake-icons
  ```

## 5. Engineering Discipline & Safety
- **Inspect Before Editing**: Read target files and trace state flow (`UI -> AppState -> Service -> Supabase/Local -> Rebuild`) before writing code.
- **Async Safety**: Always guard `BuildContext` and `setState()` with `if (mounted)` after any `await`.
- **Resource Disposal**: Always call `dispose()` on `TextEditingController`, `AnimationController`, `ScrollController`, `Timer`, and stream subscriptions.
- **Security**: Never expose Supabase service-role keys or sensitive tokens. UI `isAdmin` flag is display-only and not authorization.
- **Review Diff**: Before concluding, run `git diff` to ensure zero unintended changes or regressions.
