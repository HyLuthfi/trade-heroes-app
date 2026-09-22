# BAB 5: PENUTUP & LAMPIRAN

---

## 5.1 Kesimpulan

Berdasarkan seluruh analisis dan perancangan yang telah diuraikan pada Bab 1 hingga Bab 4, berikut adalah ringkasan utama dari proposal pengembangan aplikasi mobile native **"Kursus Saham"**:

| Aspek | Ringkasan |
|---|---|
| **Permasalahan** | Rendahnya literasi keuangan investor ritel pemula Indonesia yang menyebabkan tingginya kerugian akibat keputusan investasi yang tidak rasional, serta tidak tersedianya platform edukasi saham mobile yang interaktif, terukur, dan menyenangkan. |
| **Solusi** | Aplikasi mobile native lintas platform (Android & iOS) berbasis gamifikasi yang menggabungkan kuis interaktif bertingkat, perpustakaan materi terstruktur, kamus istilah pasar modal, dan sistem penghargaan motivasional. |
| **Teknologi** | Flutter (Dart) dengan arsitektur Provider + ChangeNotifier, penyimpanan JSON lokal, dan custom canvas rendering untuk animasi premium. |
| **Fitur Utama** | 10 level kuis (30 soal), 6 modul belajar, 4 tips trading, 8 istilah kamus, 6 medali pencapaian, sistem nyawa petir, iklan interstitial, dan Premium Plan. |
| **Investasi** | Rp 26.500.000 dengan skema pembayaran 3 termin (40%–30%–30%). |
| **Durasi** | 6–8 minggu kalender (30–40 hari kerja efektif). |
| **Deliverables** | Source code lengkap, file APK/AAB Android, proyek Xcode iOS, aset toko aplikasi, dan dokumentasi administrator. |

### Nilai Keunggulan Kompetitif Aplikasi

Aplikasi Kursus Saham memiliki beberapa keunggulan dibandingkan platform edukasi saham yang sudah ada di pasaran:

| No | Keunggulan | Penjelasan |
|---|---|---|
| 1 | **Gamifikasi Menyeluruh** | Bukan sekadar kuis biasa — terdapat sistem nyawa, XP, streak, medali, dan peta level visual yang membuat belajar terasa seperti bermain game. |
| 2 | **Offline-First** | Tidak memerlukan koneksi internet setelah terinstal. Seluruh konten dan data tersimpan lokal di perangkat. |
| 3 | **Native Murni** | Bukan web app yang di-wrap ke dalam container (WebView). Performa dan responsivitas setara aplikasi bawaan ponsel. |
| 4 | **Dual Monetisasi** | Pendapatan dari dua sumber sekaligus (iklan + premium), sehingga lebih stabil dan scalable. |
| 5 | **Konten Lokal Indonesia** | Seluruh materi, soal kuis, dan istilah kamus ditulis dalam Bahasa Indonesia dan menggunakan contoh konteks pasar modal Indonesia (BEI, IHSG, saham BUMN). |
| 6 | **Ukuran Ringan** | Estimasi ukuran APK hanya ~15–25 MB, sehingga ramah bagi pengguna dengan kapasitas penyimpanan terbatas. |

---

## 5.2 Saran Pengembangan Lanjutan

Berikut adalah rekomendasi fitur dan peningkatan yang dapat dipertimbangkan untuk fase pengembangan berikutnya setelah proyek ini selesai:

### 5.2.1 Prioritas Tinggi (Disarankan Fase 2)

| No | Fitur | Manfaat | Estimasi Biaya Tambahan |
|---|---|---|---|
| 1 | **Backend Cloud & Sinkronisasi** | Data pengguna tersimpan di server, sehingga dapat dipulihkan jika berganti perangkat atau menghapus aplikasi. | Rp 8.000.000 – 12.000.000 |
| 2 | **Autentikasi Pengguna** | Login via Google/Apple ID untuk identifikasi pengguna yang aman dan sinkronisasi lintas perangkat. | Rp 3.000.000 – 5.000.000 |
| 3 | **Payment Gateway Riil** | Integrasi Midtrans/Xendit untuk pembayaran Premium Plan secara riil menggunakan transfer bank, e-wallet, atau kartu kredit. | Rp 5.000.000 – 8.000.000 |

### 5.2.2 Prioritas Sedang (Disarankan Fase 3)

| No | Fitur | Manfaat | Estimasi Biaya Tambahan |
|---|---|---|---|
| 4 | **Integrasi Google AdMob** | Mengganti iklan simulasi dengan iklan riil yang menghasilkan pendapatan nyata per-impresi. | Rp 3.000.000 – 5.000.000 |
| 5 | **Push Notification** | Pengingat belajar harian otomatis untuk menjaga streak dan retensi pengguna. | Rp 2.000.000 – 3.000.000 |
| 6 | **Leaderboard Global** | Papan peringkat antar-pengguna berdasarkan total XP untuk memicu kompetisi sehat. | Rp 4.000.000 – 6.000.000 |

### 5.2.3 Prioritas Rendah (Disarankan Fase 4)

| No | Fitur | Manfaat | Estimasi Biaya Tambahan |
|---|---|---|---|
| 7 | **Admin Panel Web (CMS)** | Dashboard web untuk mengelola bank soal, modul materi, dan istilah kamus tanpa perlu mengubah kode. | Rp 10.000.000 – 15.000.000 |
| 8 | **Forum Diskusi Komunitas** | Ruang diskusi antar-pengguna untuk bertukar ilmu dan pengalaman trading. | Rp 6.000.000 – 10.000.000 |
| 9 | **Simulator Trading Virtual** | Fitur latihan jual-beli saham menggunakan uang virtual dengan data harga riil. | Rp 15.000.000 – 25.000.000 |
| 10 | **Multi-Bahasa** | Dukungan Bahasa Inggris untuk menjangkau pasar internasional. | Rp 3.000.000 – 5.000.000 |

> [!TIP]
> Seluruh fitur lanjutan di atas bersifat **opsional** dan independen satu sama lain. Client dapat memilih fitur mana yang ingin dikembangkan terlebih dahulu berdasarkan prioritas bisnis dan ketersediaan anggaran.

---

## 5.3 Analisis Risiko & Mitigasi

| No | Risiko | Probabilitas | Dampak | Strategi Mitigasi |
|---|---|---|---|---|
| 1 | Client terlambat memberikan feedback/review desain | Sedang | Mundurnya jadwal Fase 2 & 3 | Menetapkan batas waktu review maksimal 3 hari kerja per putaran. Jika terlewat, dianggap disetujui. |
| 2 | Perubahan kebutuhan fitur di tengah pengembangan | Sedang | Penambahan biaya dan waktu | Semua perubahan besar didokumentasikan dalam *Change Request* tertulis dan dinegosiasikan sebelum dieksekusi. |
| 3 | Bug kritis ditemukan saat pengujian iOS | Rendah | Penundaan rilis 3–5 hari | Pengujian iOS dilakukan secara paralel dengan Android di Fase 5, bukan di akhir. |
| 4 | Pembaruan Flutter SDK menyebabkan inkompatibilitas | Rendah | Perlu penyesuaian kode | Menggunakan versi Flutter SDK yang di-lock (stable channel) dan tidak melakukan upgrade SDK selama periode pengembangan. |
| 5 | Penolakan aplikasi oleh Google Play / App Store | Rendah | Penundaan distribusi | Memastikan aplikasi mematuhi seluruh pedoman konten dan kebijakan privasi toko aplikasi sejak awal. |
| 6 | Developer berhalangan (sakit/force majeure) | Rendah | Penundaan 1–5 hari | Komunikasi transparan dengan client. Jadwal digeser tanpa penalti. Code repository dapat diakses oleh developer pengganti jika diperlukan. |

---

## 5.4 Pertanyaan yang Sering Diajukan (FAQ)

### Umum

**Q: Apakah aplikasi ini benar-benar native, bukan web yang di-wrap?**
> Ya. Aplikasi dibangun menggunakan Flutter yang mengompilasi kode Dart menjadi kode mesin native (ARM binary) untuk Android dan iOS. Tidak ada komponen WebView atau browser yang berjalan di balik layar. Performa dan responsivitas setara dengan aplikasi yang dibangun menggunakan Kotlin (Android) atau Swift (iOS).

**Q: Apakah saya bisa mengubah konten soal kuis dan materi sendiri setelah proyek selesai?**
> Ya. Seluruh bank soal dan konten materi tersimpan dalam file kode Dart yang terstruktur dan terdokumentasi. Kami akan menyertakan panduan administrator yang menjelaskan cara mengubah, menambah, atau menghapus soal/materi. Namun, diperlukan pengetahuan dasar pemrograman Dart. Jika menginginkan pengelolaan konten tanpa koding, kami merekomendasikan pengembangan Admin Panel Web (CMS) di fase lanjutan.

**Q: Berapa lama aplikasi bisa bertahan tanpa pembaruan?**
> Aplikasi dapat berjalan stabil selama bertahun-tahun tanpa pembaruan, selama tidak ada perubahan besar pada sistem operasi Android/iOS yang menyebabkan inkompatibilitas. Kami merekomendasikan pembaruan minimal 1x per tahun untuk menjaga kompatibilitas dengan versi OS terbaru.

### Teknis

**Q: Apakah aplikasi memerlukan koneksi internet?**
> Tidak. Seluruh konten (soal, materi, kamus) dan data pengguna tersimpan secara lokal di perangkat. Aplikasi dapat digunakan sepenuhnya secara offline. Koneksi internet hanya diperlukan jika di masa depan ditambahkan fitur backend cloud atau iklan riil.

**Q: Bagaimana jika pengguna menghapus dan menginstal ulang aplikasi?**
> Pada versi saat ini (Fase 1), data pengguna tersimpan secara lokal dan akan hilang jika aplikasi dihapus. Untuk mengatasi hal ini, pengembangan backend cloud (Fase 2) memungkinkan sinkronisasi data ke server sehingga data dapat dipulihkan setelah instalasi ulang.

**Q: Apakah pengguna bisa memanipulasi data XP atau petir?**
> Pada perangkat normal (tanpa root/jailbreak), file data tersimpan di dalam direktori sandbox aplikasi yang tidak dapat diakses oleh pengguna atau aplikasi lain. Pada perangkat yang di-root, secara teoritis file JSON dapat dimodifikasi. Jika keamanan ini menjadi perhatian, validasi server-side dapat ditambahkan di fase lanjutan.

### Bisnis & Komersial

**Q: Apakah saya memiliki hak penuh atas aplikasi setelah proyek selesai?**
> Ya. Setelah pelunasan seluruh termin pembayaran, seluruh hak kekayaan intelektual atas source code dan aset visual menjadi milik penuh client. Client bebas memodifikasi, menjual, atau mendistribusikan aplikasi tanpa batasan.

**Q: Berapa potensi pendapatan dari iklan?**
> Pendapatan iklan bergantung pada jumlah pengguna aktif dan jaringan iklan yang digunakan. Sebagai gambaran umum, rata-rata pendapatan iklan interstitial mobile di Indonesia adalah Rp 5.000 – Rp 25.000 per 1.000 tayangan (CPM). Dengan 10.000 pengguna aktif harian yang masing-masing melihat rata-rata 3 iklan, estimasi pendapatan adalah Rp 150.000 – Rp 750.000 per hari.

**Q: Apakah saya bisa menaikkan harga Premium Plan di kemudian hari?**
> Ya. Harga Premium Plan sepenuhnya dikendalikan oleh client dan dapat diubah kapan saja melalui pembaruan kode atau melalui konfigurasi di Google Play / App Store (jika menggunakan in-app purchase di fase lanjutan).

**Q: Apakah ada biaya bulanan setelah proyek selesai?**
> Tidak ada biaya bulanan wajib kepada developer setelah proyek selesai. Biaya yang berjalan hanyalah biaya tahunan Apple Developer ($99/tahun) jika ingin tetap mendistribusikan di App Store. Layanan maintenance opsional dapat dinegosiasikan secara terpisah jika dibutuhkan.

---

## 5.5 Opsi Paket Pemeliharaan Pasca Proyek (Opsional)

Setelah masa garansi 30 hari berakhir, client dapat memilih untuk berlangganan paket pemeliharaan bulanan berikut:

| Paket | Harga / Bulan | Cakupan |
|---|---|---|
| **Basic** | Rp 500.000 | Perbaikan bug kritis (max 2 tiket/bulan), pembaruan kompatibilitas OS |
| **Standard** | Rp 1.500.000 | Semua cakupan Basic + penambahan/perubahan 5 soal kuis & 1 modul materi per bulan |
| **Premium** | Rp 3.000.000 | Semua cakupan Standard + penambahan fitur minor (1 fitur kecil/bulan), prioritas respons 24 jam, konsultasi bulanan via video call |

> [!NOTE]
> Paket pemeliharaan bersifat **sepenuhnya opsional**. Client tidak diwajibkan berlangganan paket apapun setelah proyek selesai. Source code telah diserahkan sepenuhnya dan client bebas mengelolanya secara mandiri atau melalui developer lain.

---

## Lampiran A: Glosarium Istilah Teknis

Berikut adalah penjelasan istilah-istilah teknis yang digunakan dalam dokumen proposal ini, untuk memudahkan pemahaman client non-teknis:

| Istilah | Penjelasan |
|---|---|
| **APK** | Android Package Kit — file instalasi aplikasi Android yang dapat langsung dipasang di ponsel. |
| **AAB** | Android App Bundle — format distribusi yang lebih efisien untuk upload ke Google Play Store. Google akan mengoptimalkan ukuran unduhan secara otomatis per perangkat. |
| **Framework** | Kerangka kerja perangkat lunak yang menyediakan fondasi siap pakai untuk mempercepat pengembangan aplikasi. |
| **Flutter** | Framework open-source buatan Google untuk membangun aplikasi native lintas platform (Android, iOS, Web, Desktop) dari satu basis kode. |
| **Dart** | Bahasa pemrograman yang digunakan oleh Flutter, dikembangkan oleh Google. |
| **Native** | Aplikasi yang berjalan langsung di atas sistem operasi perangkat (bukan di dalam browser atau container web). |
| **State Management** | Teknik pengelolaan data dan kondisi aplikasi secara terpusat agar seluruh bagian UI selalu menampilkan informasi yang terbaru dan konsisten. |
| **Provider** | Library state management resmi yang direkomendasikan oleh tim Flutter. |
| **JSON** | JavaScript Object Notation — format penyimpanan data berbentuk teks terstruktur yang ringan dan mudah dibaca. |
| **Sandbox** | Mekanisme keamanan sistem operasi yang mengisolasi data setiap aplikasi agar tidak dapat diakses oleh aplikasi lain. |
| **CustomPainter** | API Flutter untuk menggambar grafis kustom (garis, kurva, bentuk) langsung ke layar menggunakan perintah canvas tingkat rendah. |
| **Interstitial Ad** | Format iklan layar penuh yang muncul di antara transisi konten (misalnya setelah menyelesaikan kuis). |
| **API** | Application Programming Interface — antarmuka yang memungkinkan dua sistem perangkat lunak berkomunikasi satu sama lain. |
| **CMS** | Content Management System — sistem panel admin berbasis web untuk mengelola konten tanpa perlu mengubah kode program. |
| **Sprint** | Periode kerja pendek (biasanya 1–2 minggu) dalam metodologi Agile, di mana serangkaian fitur dikerjakan dan didemonstrasikan hasilnya. |
| **Hot Reload** | Fitur Flutter yang memungkinkan developer melihat perubahan kode secara instan di layar tanpa perlu restart seluruh aplikasi. |
| **Obfuskasi** | Proses mengacak nama variabel dan fungsi dalam kode yang telah dikompilasi, sehingga sulit dibaca oleh pihak yang mencoba melakukan reverse engineering. |

---

## Lampiran B: Referensi Mockup Visual Aplikasi

Berikut adalah referensi tampilan visual dari berbagai halaman aplikasi Kursus Saham yang telah dirancang selama fase prototipe awal:

| No | Halaman | Deskripsi |
|---|---|---|
| 1 | Landing / Peta Level | Tampilan zigzag node-node level kuis dengan 3 zona warna, garis penghubung putus-putus, dan peti medali bonus di bawah |
| 2 | Layar Kuis (Pilihan Ganda) | Soal dengan 4 tombol opsi, progress bar hijau, dan indikator nyawa petir |
| 3 | Feedback Jawaban Benar | Panel hijau muncul dari bawah dengan penjelasan edukatif |
| 4 | Layar Kuis (Esai) | Kotak input teks dengan soal isian singkat |
| 5 | Dialog Hasil Kuis | Rangkuman XP diperoleh dan nyawa tersisa |
| 6 | Peta Level Setelah Selesai | Node level 1 berubah hijau, level 2 terbuka |
| 7 | Kamus Istilah | Accordion list dengan kotak pencarian dan tombol suara |
| 8 | Profil & Medali | Avatar emoji, statistik 2×2, grid medali dengan border emas |
| 9 | Dialog Premium Plan | Penawaran fitur premium dengan harga promo |

> [!NOTE]
> Mockup di atas merupakan hasil prototipe awal. Desain final akan disempurnakan pada Fase 2 (Desain UI/UX) berdasarkan feedback dan preferensi visual client.

---

## Lampiran C: Daftar Isi Lengkap Dokumen Proposal

Untuk kemudahan navigasi, berikut adalah daftar isi lengkap dari seluruh dokumen proposal ini:

```
PROPOSAL PENAWARAN & SPESIFIKASI TEKNIS
Pengembangan Aplikasi Mobile Native "Kursus Saham"
═══════════════════════════════════════════════════

BAB 1: PENDAHULUAN
├── 1.1 Latar Belakang
├── 1.2 Rumusan Masalah
├── 1.3 Tujuan Proyek
│   ├── 1.3.1 Tujuan Umum
│   └── 1.3.2 Tujuan Khusus
├── 1.4 Manfaat Proyek
│   ├── 1.4.1 Manfaat bagi Pengguna
│   └── 1.4.2 Manfaat bagi Pemilik Aplikasi
├── 1.5 Ruang Lingkup Proyek
│   ├── 1.5.1 In-Scope
│   └── 1.5.2 Out-of-Scope
└── 1.6 Metodologi Pengembangan

BAB 2: SPESIFIKASI FITUR UTAMA APLIKASI
├── 2.1 Gambaran Umum Arsitektur Fitur
├── 2.2 Modul 1: Sistem Kuis & Gamifikasi
│   ├── 2.2.1 Peta Jalur Belajar
│   ├── 2.2.2 Sistem Nyawa Petir
│   ├── 2.2.3 Lembar Kuis Interaktif
│   └── 2.2.4 Peti Medali Bonus
├── 2.3 Modul 2: Pusat Edukasi & Referensi
│   ├── 2.3.1 Modul Belajar
│   ├── 2.3.2 Favorit Anda
│   ├── 2.3.3 Tips Trading
│   └── 2.3.4 Kamus Istilah
├── 2.4 Modul 3: Akun Pengguna & Pencapaian
│   ├── 2.4.1 Kartu Identitas Pengguna
│   ├── 2.4.2 Status Langganan
│   ├── 2.4.3 Dashboard Statistik
│   └── 2.4.4 Rak Medali Pencapaian
├── 2.5 Modul 4: Sistem Monetisasi
│   ├── 2.5.1 Iklan Interstitial
│   └── 2.5.2 Premium Plan
├── 2.6 Alur Pengguna Utama
└── 2.7 Ringkasan Jumlah Konten

BAB 3: RANCANGAN TEKNOLOGI & ARSITEKTUR SISTEM
├── 3.1 Pemilihan Teknologi Utama
│   ├── 3.1.1 Framework: Flutter
│   ├── 3.1.2 Justifikasi Pemilihan
│   └── 3.1.3 Dependensi Library
├── 3.2 Arsitektur Sistem Aplikasi
│   ├── 3.2.1 Pola Arsitektur
│   └── 3.2.2 Struktur Direktori
├── 3.3 Model Data & Penyimpanan Lokal
│   ├── 3.3.1 Skema Data AppState
│   ├── 3.3.2 Format JSON Lokal
│   └── 3.3.3 Siklus Hidup Data
├── 3.4 Sistem Pemulihan Nyawa Petir
├── 3.5 Rendering Grafis Kustom
├── 3.6 Konfigurasi Tema & Desain Visual
│   ├── 3.6.1 Palet Warna
│   ├── 3.6.2 Tipografi
│   └── 3.6.3 Prinsip Desain
├── 3.7 Kompatibilitas Platform
├── 3.8 Pertimbangan Keamanan
└── 3.9 Rencana Pengembangan Lanjutan

BAB 4: JADWAL PROYEK & ESTIMASI ANGGARAN
├── 4.1 Ringkasan Jadwal Proyek
├── 4.2 Diagram Gantt Chart
├── 4.3 Rincian 6 Fase Pengembangan
├── 4.4 Daftar Deliverables
├── 4.5 Estimasi Anggaran & Rincian Biaya
├── 4.6 Skema Pembayaran
├── 4.7 Syarat & Ketentuan Proyek
│   ├── 4.7.1 Hak Kekayaan Intelektual
│   ├── 4.7.2 Lingkup Revisi
│   ├── 4.7.3 Garansi Pasca Serah Terima
│   └── 4.7.4 Pembatalan Proyek
└── 4.8 Penutup & Konfirmasi Persetujuan

BAB 5: PENUTUP & LAMPIRAN
├── 5.1 Kesimpulan
├── 5.2 Saran Pengembangan Lanjutan
├── 5.3 Analisis Risiko & Mitigasi
├── 5.4 Pertanyaan yang Sering Diajukan (FAQ)
├── 5.5 Opsi Paket Pemeliharaan Pasca Proyek
├── Lampiran A: Glosarium Istilah Teknis
├── Lampiran B: Referensi Mockup Visual
└── Lampiran C: Daftar Isi Lengkap (dokumen ini)
```

---

> **Dokumen ini disusun oleh tim pengembang sebagai bahan pertimbangan dan referensi bagi pihak client dalam mengambil keputusan terkait proyek pengembangan aplikasi mobile native "Kursus Saham". Seluruh informasi, estimasi, dan spesifikasi dalam dokumen ini bersifat terbuka untuk didiskusikan dan disesuaikan berdasarkan kesepakatan kedua belah pihak.**
