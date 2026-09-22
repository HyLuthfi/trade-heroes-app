# 📈 Trade Heroes — Gamified Stock Market Learning & Live Simulator

<p align="center">
  <img src="assets/images/logo.png" alt="Trade Heroes Logo" width="120" />
</p>

<p align="center">
  <b>Belajar Investasi & Trading Saham Jadi Menyenangkan, Terukur, dan Bebas Boncos.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/State_Management-Provider-blue?style=for-the-badge" alt="Provider" />
  <img src="https://img.shields.io/badge/Platform-Android_%7C_iOS_%7C_Web-green?style=for-the-badge" alt="Platform" />
  <img src="https://img.shields.io/badge/Theme-Dark_Slate_Aesthetic-1e293b?style=for-the-badge" alt="Theme" />
</p>

---

## 🌟 Tentang Proyek

**Trade Heroes** adalah platform edukasi pasar modal interaktif berbasis **Flutter native** yang dirancang untuk mengatasi rendahnya literasi keuangan dan tingginya angka *FOMO* serta kerugian (*boncos*) di kalangan investor ritel pemula di Indonesia.

Menggabungkan kurikulum pasar modal terstruktur dengan mekanisme **gamifikasi ala Duolingo**, Trade Heroes mengubah materi analisis saham yang rumit menjadi petualangan belajar bertingkat yang interaktif, menantang, dan adiktif secara positif.

---

## ✨ Fitur-Fitur Utama

### 1. 🗺️ Peta Jalur Belajar Bertingkat (Learning Roadmap)
- **10 Level Progresif** dalam tampilan peta zigzag vertikal interaktif yang terbagi ke dalam 3 zona edukasi:
  - **Zona 1 — Fondasi Utama (Level 1–3):** Pengenalan Saham, Bursa Efek Indonesia (BEI), Dividen & Capital Gain.
  - **Zona 2 — Analisis Teknikal (Level 4–7):** Candlestick Dasar, Support & Resistance, Trendlines, Indikator Teknikal.
  - **Zona 3 — Manajemen Risiko (Level 8–10):** Money Management, Psikologi Pasar, Cut Loss vs Take Profit.
- **Variasi Soal Interaktif:** Pilihan ganda dan isian esai dengan sistem validasi instan serta penjelasan edukatif lengkap di setiap nomor.
- **Milestone Reward Chests:** Peti harta karun di setiap milestone level untuk mengklaim bonus XP.

### 2. ⚡ Sistem Nyawa Petir (Life & Recovery System)
- Pengguna dibekali **5 nyawa petir**; setiap kesalahan menjawab kuis mengurangi 1 petir.
- **Regenerasi Otomatis:** Hitung mundur pemulihan nyawa setiap 60 detik secara otomatis.
- Opsi isi ulang instan melalui tontonan iklan simulasi (*rewarded/interstitial ad*).

### 3. 📊 Simulator Pasar Saham Real-Time (Live Market)
- **Simulasi Emiten Saham BEI:** Data dinamik saham *blue-chip* unggulan (BBCA, BBRI, TLKM, ASII, GOTO, AMMN, ICBP, UNVR).
- **Grafik Candlestick Interaktif:** Dilengkapi garis Moving Average (MA), pemilihan timeframe, dan *crosshair touch tooltip*.
- **Live Running Trade:** Aliran transaksi *BUY* dan *SELL* real-time yang bergerak dinamis.
- **Pro Order Book:** Antrean *Bid* vs *Offer* multi-tingkat lengkap dengan visualisasi persentase kedalaman volume.
- **Fundamental Ratios & Financials:** Metrik valuasi penting (PER, PBV, Market Cap, Foreign Flow) serta tab berita emiten.

### 4. 📖 Perpustakaan Modul & Kamus Pasar Modal
- **Modul Edukasi Terstruktur:** Artikel ringkas dengan estimasi waktu baca (*read-time*) dan poin kesimpulan (*key takeaways*).
- **Kamus Istilah Saham Interaktif:** Glosarium istilah finansial/saham A-Z dengan fitur pencarian instan (*instant search*).
- **Tips Trading Praktis:** Panduan aksi cepat yang dapat disimpan dan dipelajari secara offline.

### 5. 🏆 Gamifikasi, Medali & Profil Pengguna
- **6 Medali Prestasi (Badges):**
  - 🌱 *Saham Pemula* — Menyelesaikan kuis level pertama.
  - 🛡️ *Anti Boncos* — Menuntaskan kuis 100% benar tanpa kehilangan nyawa.
  - 🔥 *Investor Setia* — Mempertahankan streak belajar minimal 3 hari berturut-turut.
  - 📚 *Kolektor Ilmu* — Menyimpan minimal 3 soal ke bank favorit.
  - 👑 *Premium Member* — Mengaktifkan VIP Gold Pass.
  - 🎓 *Pakar Saham* — Menuntaskan seluruh 10 level roadmap.
- **Koleksi Soal Favorit:** Bookmark pertanyaan penting untuk ditinjau kembali kapan saja.
- **Avatar Selector:** Kustomisasi ikon profil trader (Bull, Analyst, Whale, Breakout, VIP Gold, dll.).
- **Hadiah Harian (7-Day Daily Rewards):** Hadiah login berantai setiap hari berupa XP dan nyawa petir ekstra.

### 6. 👑 Monetisasi: VIP Gold Pass
- Langganan bulanan / tahunan dengan benefit:
  - Nyawa tak terbatas ($\infty$ Petir) — bebas belajar tanpa takut kehabisan nyawa.
  - Bebas iklan pop-up (*Ad-Free Experience*).
  - Akses tak terbatas ke seluruh modul materi eksklusif.

### 7. 📱 Dynamic Device Frame Preview
- Saat dijalankan di browser desktop atau layar lebar ($\ge 600$px), aplikasi otomatis dibungkus oleh **bingkai iPhone premium** lengkap dengan *Dynamic Island* dan *Home Indicator*.
- Otomatis menyesuaikan menjadi tampilan *native fullscreen* di layar smartphone.

---

## 🛠️ Arsitektur & Teknologi

```text
lib/
├── main.dart             # Inisialisasi aplikasi, routing, & mockup DeviceFrame
├── state/
│   └── app_state.dart    # Centralized State Management (Provider & ChangeNotifier)
├── views/
│   ├── splash_view.dart  # Cinematic video splash screen & fallback
│   ├── login_view.dart   # Auth form (Email & Google login simulation)
│   ├── home_view.dart    # Shell navigasi 4 tab utama & header bar
│   ├── kuis_view.dart    # Roadmap level zigzag & kuis handler
│   ├── market_view.dart  # Simulator pasar saham BEI & candlestick chart
│   ├── materi_view.dart  # Modul artikel edukasi & kamus istilah pasar modal
│   └── profile_view.dart # Dashboard statistik belajar, medali, & avatar
└── widgets/
    ├── quiz_overlay.dart      # Fullscreen quiz modal dengan animasi shake
    ├── ad_overlay.dart        # Pop-up simulasi iklan interstitial 5 detik
    ├── daily_reward_modal.dart# Modal klaim hadiah login 7 hari
    ├── vip_pass_modal.dart    # Modal upgrade VIP Gold Pass
    └── avatar_picker_modal.dart# Dialog pemilih avatar profil
```

- **Framework:** Flutter 3.x / Dart 3.x
- **Pola Arsitektur:** Provider Pattern (`ChangeNotifier`)
- **Penyimpanan Data:** Penyimpanan lokal file JSON (`state.json`) via `path_provider`
- **Asset Media:** Video splash MP4, logo & sprite grafis kustom

---

## 🚀 Panduan Menjalankan Aplikasi

### Prasyarat
- Pastikan [Flutter SDK](https://docs.flutter.dev/get-started/install) telah terpasang di sistem Anda.
- Dart SDK versi $\ge 3.0.0 < 4.0.0$.

### Langkah Instalasi
1. **Clone repositori:**
   ```bash
   git clone https://github.com/HyLuthfi/trade-heroes-app.git
   cd trade-heroes-app
   ```

2. **Unduh seluruh dependensi:**
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi:**
   - **Di Chrome / Web:**
     ```bash
     flutter run -d chrome
     ```
   - **Di Perangkat Android / Emulator:**
     ```bash
     flutter run -d android
     ```
   - **Di iOS Simulator (macOS):**
     ```bash
     flutter run -d ios
     ```

---

## 📄 Lisensi & Hak Cipta

Dikembangkan oleh **[Luthfi Muthathohirin](https://github.com/HyLuthfi)** sebagai platform edukasi pasar modal modern berbasis gamifikasi.
Didistribusikan di bawah lisensi terbuka untuk tujuan edukasi dan pengembangan teknologi finansial di Indonesia.
