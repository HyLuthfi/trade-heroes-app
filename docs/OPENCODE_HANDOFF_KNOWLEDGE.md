# 📋 KNOWLEDGE TRANSFER & HANDOFF UNTUK OPENCODE

> **Project**: Trade Heroes (Mobile & Web Flutter App)  
> **Repository Path (Windows Host)**: `G:\Semester 7\Project\Trades Hero`  
> **Active Git Branch**: `Fix-Fitur-Setting`  
> **Environment**: Flutter 3.47.5 • Dart 3.13.4 • Python 3.10 Web Server (`server.py` port 20170)  
> **Date**: 24 September 2026  

---

## 1. 🎯 FOKUS UTAMA KITA SAAT INI

Fokus utama proyek di branch `Fix-Fitur-Setting` adalah:
1. **Penyelesaian Sistem Internasionalisasi (i18n) Bilingual (ID ⇄ EN)**:
   - Memastikan seluruh antarmuka aplikasi (*Home, Login, Profile, Market, Kuis, Materi, Admin Console*) adaptif secara dinamis saat user berganti bahasa.
   - Memastikan engine translasi sangat tangguh (*resilient*): jika ada fitur baru dari teman/kontributor lain yang belum terdaftar di kamus, aplikasi **tidak boleh crash** dan otomatis menampilkan teks aslinya (*safe fallback*).
2. **Penyempurnaan Tampilan Light Mode & Dark Mode**:
   - Menghilangkan kontras buruk atau elemen yang masih gelap di Light Mode (*Level Modal, Quiz Screen, Daily Reward, Modal Materi*).
   - **GOLDEN RULE KUIS**: Latar belakang ilustrasi alam pada peta kuis (`assets/images/background.png`) **HARUS 100% MURNI DAN TRANSPARAN** (`Colors.transparent`), dilarang menambahkan layer putih/opak di atasnya.
3. **Penyelesaian Fitur Pengaturan & Preferensi**:
   - Mode Gelap (ThemeMode), Notifikasi Harian (Daily Reminder), Suara & Haptik, Musik Latar (BGM picker), dan Bahasa Aplikasi tersimpan presisten di `SharedPreferences` dan Supabase Cloud.

---

## 2. 🏗️ ARSITEKTUR & STRUKTUR TEKNIS

- **State Management**: Centralized Provider menggunakan `AppState` (`lib/state/app_state.dart`). Root `MaterialApp` dibungkus `Selector<AppState, ({bool darkMode, String language})>`.
- **Localization Engine (Zero Package)**:
  - `lib/l10n/app_translations.dart`: Resolver teks dengan dukungan fallback bertingkat (`Locale -> Dynamic Dict -> Static EN -> Static ID -> Raw Text`). Mendukung interpolasi `{param}`.
  - `lib/l10n/locale_resolver.dart`: Normalisasi kode bahasa (`id`, `en`, `en-US`, `ID` -> valid code).
  - `lib/l10n/id.dart`: Kamus Bahasa Indonesia (249 keys).
  - `lib/l10n/en.dart`: Kamus English (US) (248 keys).
- **Backend & Auth**: Supabase via `SupabaseService` (`https://hmltwrravmipwrlmjtcf.supabase.co`).
- **Web Proxy Server**: `server.py` di port `20170` melayani static web Flutter dan mem-proxy Yahoo Finance API (`/api/yahoo/`) untuk menghindari CORS.

---

## 3. ✅ YANG SUDAH SELESAI DIKERJAKAN PADA SESI INI

1. **Sistem i18n & Kamus Lengkap (Fase 1 s/d Fase 4)**:
   - Kamus ID & EN sinkron dengan 249 key parity (mencakup navigasi, auth, profil, market trading terminal, order book, kuis, daily reward, materi, dan admin console).
   - Dialog pemilihan bahasa di Profile: menampilkan pilihan bendera 🇮🇩 Bahasa Indonesia dan 🇺🇸 English (US) dengan centang aktif dan tombol tutup.
   - Engine translasi diperkuat dengan metode `addDynamicTranslations` dan deteksi format key standar vs raw text.
2. **Perbaikan Masalah Halaman Materi (`materi_view.dart`)**:
   - Diberikan *clearance* `const SizedBox(height: kToolbarHeight)` di atas TabBar agar tidak tertutup atau terblokir oleh floating `AppBar` dari `HomeView`.
   - Padding bawah seluruh tab materi dinaikkan menjadi `110` agar kartu terbawah tidak terjebak di belakang *bottom navigation bar*.
   - Seluruh kartu modul dibungkus `Material` + `InkWell` untuk respon klik instan di browser web.
   - Modal bacaan materi (`_openModuleContent`) dibuat adaptif Light/Dark mode dengan batas ukuran eksplisit (`screenH * 0.82` dan `screenW.clamp(280, 540)`), mencegah layout crash.
3. **Invarian Background Kuis (`kuis_view.dart`)**:
   - Background kuis 100% murni (`Colors.transparent`), menampilkan gambar ilustrasi asli tanpa lapisan putih.
   - Pop-up start level kuis (`_buildInFrameModalSheet`) dibuat adaptif: putih di Light Mode, navy gelap di Dark Mode.
4. **Verifikasi Toolchain Nyata di Windows Host**:
   - 74 dari 74 tes unit & widget lulus (`G:\flutter\bin\flutter.bat test`).
   - `flutter analyze`: 0 compile error.
   - `flutter build web --no-tree-shake-icons`: Berhasil terkompilasi (`√ Built build\web`).
   - `server.py`: Berjalan normal di background (port 20170).

---

## 4. 📌 DAFTAR TUGAS UNTUK OPENCODE (NEXT STEPS)

Periksa file `.hermes/todo.md` untuk backlog detail:

### Prioritas 1: Perbaikan Visual Modal yang Belum Sempurna di Light Mode
1. **Quiz Game Overlay (`lib/widgets/quiz_overlay.dart`)**:
   - Pastikan kartu soal, opsi jawaban A/B/C/D, dan tombol PERIKSA JAWABAN tampil dengan latar terang dan teks gelap kontras saat Light Mode aktif.
2. **Modal Absen Harian (`lib/widgets/daily_reward_modal.dart`)**:
   - Pastikan grid kotak hari 1 s/d 7 tampil bersih dengan latar abu-abu terang / mint muda di Light Mode (bukan navy pekat).

### Prioritas 2: Solusi Blocker VM Test Audio Service
- Saat ini `flutter test` untuk file yang mengimpor `lib/services/audio_service.dart` gagal di lingkungan VM native karena memakai `dart:js_interop` secara langsung tanpa *conditional import*.
- **Solusi Rekomendasi**: Pisahkan implementasi audio menjadi stub/interface (`audio_service_stub.dart` untuk VM/native dan `audio_service_web.dart` untuk Web) menggunakan `if (dart.library.js_interop)` di file export utama, sehingga test widget VM dapat berjalan 100% di semua platform.

### Prioritas 3: Konten Bilingual Tingkat Data (Fase 5)
- Konten soal kuis dan teks modul materi saat ini masih dalam Bahasa Indonesia di `assets/data/`. Jika ingin 100% bilingual hingga ke butir soal, siapkan folder data terpisah:
  - `assets/data/id/quizzes.json` & `assets/data/en/quizzes.json`
  - `assets/data/id/modules.json` & `assets/data/en/modules.json`

---

## 5. ⚠️ ATURAN & BATASAN KETAT (GOLDEN RULES)

1. **JANGAN MERUSAK BACKGROUND KUIS**: Jangan pernah memberi warna solid atau opasitas putih pada `kuis-roadmap-surface` atau `Scaffold` kuis. Latar belakang harus tetap `Colors.transparent`.
2. **JANGAN MENGUBAH LOGIKA TRADING & SKOR**: Perhitungan lot (`* 100`), fee sekuritas BEI (`0.15%` beli, `0.25%` jual), saldo kas virtual, dan penilaian kuis (`xp = correct * 10`) adalah logika inti yang tidak boleh disentuh.
3. **TIDAK ADA ASUMSI TANPA RUNNING TEST**: Selalu jalankan verifikasi nyata di Windows PowerShell:
   ```powershell
   cd 'G:\Semester 7\Project\Trades Hero'
   G:\flutter\bin\flutter.bat test test/l10n/ test/views/
   G:\flutter\bin\flutter.bat analyze
   G:\flutter\bin\flutter.bat build web --no-tree-shake-icons
   ```
4. **JANGAN COMMIT / PUSH OTOMATIS**: Lakukan perubahan secara terisolasi tanpa commit otomatis kecuali diperintahkan oleh user.
