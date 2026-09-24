# GLOSARIUM KOMPREHENSIF PASAR MODAL & SIMULATOR SAHAM (BEI/IDX VS GLOBAL/NYSE/NASDAQ)

Standar terminologi pasar modal dwi-bahasa (Indonesia - Inggris) untuk aplikasi simulator saham dan akademi edukasi **Trade Heroes** (Flutter Web, Android, iOS).

---

## 1. DASAR HUKUM, STANDAR & REFERENSI TEKNIS

1. **Regulator & Bursa Domestik (Indonesia):**
   - **UU No. 4 Tahun 2023** (UU P2SK - Pengembangan dan Penguatan Sektor Keuangan) menggantikan & memperbarui UU No. 8 Tahun 1995 tentang Pasar Modal.
   - **POJK No. 22/POJK.04/2021** & **POJK No. 3/POJK.04/2021**: Penyelenggaraan kegiatan di bidang pasar modal.
   - **Peraturan BEI No. II-A**: Perdagangan Efek Bersifat Ekuitas (Kep-00055/BEI/03-2023 dan addendum terbaru) mengatur JATS Next-G, fraksi harga, auto rejection simetris, dan batasan pesanan.
   - **Surat Edaran BEI No. SE-00003/BEI/05-2023**: Implementasi normalisasi jam perdagangan dan batasan persentase auto rejection simetris.
   - **Glosarium Resmi OJK & IDX**: Standar istilah Sistem Informasi Literasi dan Edukasi Keuangan (SILEK) OJK.

2. **Standar Global & Regulator Internasional (US/Global):**
   - **SEC (Securities and Exchange Commission) Reg NMS (National Market System)**: Rule 611 (Order Protection Rule), Rule 605/606 (Execution Quality Disclosure).
   - **SEC Rule 15c6-1(a)**: Penyesuaian siklus penyelesaian transaksi menjadi **T+1** (berlaku efektif sejak 28 Mei 2024 di NYSE/NASDAQ/AMEX).
   - **FINRA (Financial Industry Regulatory Authority)**: Rule 5310 (Best Execution).
   - **NYSE Rule 7.12 / Rule 80B**: Market-Wide Circuit Breakers (MWCB) dan Limit Up-Limit Down (LULD) mechanism.

3. **Referensi Proyek Open-Source FinTech / Trading Engine:**
   - `QuantConnect/Lean` (C#): Arsitektur engine eksekusi saham, slippage model, transaction fee model, order book queue simulation.
   - `ccxt/ccxt` (JavaScript/Python): Standar normalisasi data market: `OrderBook`, `Ticker`, `Trade`, `OrderType`, `OrderSide`.
   - `openbb-finance/OpenBB` (Python): Standard taxonomies for financial statement analysis, quotes, metrics, ratios.
   - `alpaca-trade-api` (Go/Python): Standard REST/WebSocket interface for paper trading, buying power, equity, and positions.

---

## 2. TABEL GLOSARIUM DWI-BAHASA (ID <-> EN) UNTUK SIMULATOR SAHAM

### Kategori 1: Struktur Pasar, Regulator & Indeks (Market Structure & Regulators)

| No | Istilah ID (Bahasa Indonesia) | Istilah EN (English) | Definisi Teknis & Konteks Simulator | Referensi Standar |
|:---|:---|:---|:---|:---|
| 1 | **Bursa Efek** | **Securities Exchange / Stock Exchange** | Pihak penyelenggara sistem pasar terpusat tempat perdagangan efek (BEI di ID, NYSE/NASDAQ di US). | UU P2SK / SEC |
| 2 | **Otoritas Jasa Keuangan (OJK)** | **Financial Services Authority (SEC equivalent)** | Regulator & pengawas independen pasar modal di Indonesia (ekuivalen SEC + FINRA di US). | UU No. 21/2011 |
| 3 | **KPEI (Kliring Penjaminan Efek Indonesia)** | **Indonesian Clearing & Guarantee Corp (NSCC equivalent)** | Lembaga penjaminan kliring transaksi bursa (ekuivalen NSCC/DTCC di US). | Peraturan KPEI |
| 4 | **KSEI (Kustodian Sentral Efek Indonesia)** | **Indonesian Central Securities Depository (DTC/DTCC equivalent)** | Kustodian sentral penyimpanan surat berharga dan pencatatan mutasi rekening efek. | Peraturan KSEI |
| 5 | **Indeks Harga Saham Gabungan (IHSG)** | **IDX Composite (JKSE / Composite Index)** | Indeks tertimbang kapitalisasi pasar seluruh saham yang tercatat di papan utama dan pengembangan BEI. | IDX Rulebook |
| 6 | **Indeks LQ45 / IDX30** | **LQ45 / IDX30 Index (Large-Cap Liquid Index)** | Indeks 45/30 saham paling likuid dengan fundamental kuat di BEI (mirip S&P 100 / Dow 30). | FactSheet BEI |
| 7 | **Emiten / Perusahaan Tercatat** | **Listed Company / Issuer** | Perusahaan berbadan hukum yang menerbitkan saham atau obligasi untuk publik di bursa. | POJK 3/2021 |
| 8 | **Papan Pencatatan** | **Listing Board / Market Tier** | Klasifikasi kualifikasi emiten (Papan Utama, Pengembangan, Akselerasi, New Economy, Pemantauan Khusus). | Peraturan BEI I-A |
| 9 | **Papan Pemantauan Khusus (FCA)** | **Watchlist Board / Full Call Auction Board** | Papan saham berperingatan kriteria 1-11 yang diperdagangkan lewat lelang periodik berkala. | Kep-00004/BEI/01-2024 |
| 10 | **Anggota Bursa (AB) / Perusahaan Sekuritas** | **Exchange Member / Broker-Dealer** | Pialang resmi perantara perdagangan efek berlisensi OJK & BEI. | POJK 20/2021 |

---

### Kategori 2: Satuan Perdagangan & Mekanisme Transaksi (Trading Units & Microstructure)

| No | Istilah ID (Bahasa Indonesia) | Istilah EN (English) | Definisi Teknis & Konteks Simulator | Perbedaan BEI vs Global |
|:---|:---|:---|:---|:---|
| 11 | **Lot Saham** | **Round Lot / Lot Size** | Satuan minimum pembelian saham di pasar reguler. Di BEI: **1 Lot = 100 Lembar**. | US/Global pakai **Shares / Units** (bisa satuan hingga fractional 0.001). BEI wajib kelipatan 100 lembar. |
| 12 | **Lembar Saham** | **Shares / Units of Stock** | Unit kepemilikan tunggal atas saham suatu perseroan. | Di BEI 1 share tidak bisa ditransaksikan di Pasar Reguler kecuali Odd Lot. |
| 13 | **Pecahan Ganjil (Odd Lot)** | **Odd Lot** | Satuan perdagangan di bawah 1 lot (<100 lembar). Di BEI hanya ada di papan khusus Odd Lot. | Di US, odd lot (<100 shares) diperlakukan sama dengan round lot di order book modern. |
| 14 | **Fraksi Harga** | **Tick Size / Price Tick** | Kenaikan minimum perubahan harga saham. BEI memakai 5 rentang harga baku. | BEI: Rp1, Rp2, Rp5, Rp10, Rp25. US: desimal tetap $0.01 (atau $0.0001 sub-penny). |
| 15 | **Auto Rejection Atas (ARA)** | **Upper Auto-Rejection / Limit Up** | Batas persentase kenaikan harga maksimum dalam 1 hari bursa. Melebihi batasan otomatis ditolak JATS. | BEI: 35% (<Rp200), 25% (Rp200-5000), 20% (>Rp5000). US: Pakai LULD (pause 5 menit), tidak ada cap 1 hari. |
| 16 | **Auto Rejection Bawah (ARB)** | **Lower Auto-Rejection / Limit Down** | Batas persentase penurunan harga maksimum dalam 1 hari bursa. | Simetris dengan ARA di BEI sejak September 2023 (-35%, -25%, -20%). US LULD trigger temporary halt. |
| 17 | **Pembekuan Perdagangan Sementara (Suspensi)** | **Trading Halt / Trading Suspension** | Penghentian sementara perdagangan suatu saham oleh bursa karena pergerakan tidak wajar (UMA). | BEI: Cooling down / UMA suspensi 1 sesi - berhari-hari. US: Volatility Halt (5-10 menit). |
| 18 | **Penghentian Perdagangan Seluruh Bursa** | **Market-Wide Circuit Breaker** | Penghentian seluruh aktivitas perdagangan saat IHSG anjlok >=5% (halt 30 menit). | BEI: Halt 30 mnt jika IHSG -5%. US NYSE Rule 80B: Level 1 (-7%), Level 2 (-13%), Level 3 (-20% tutup total). |
| 19 | **Sesi Pra-Pembukaan** | **Pre-Opening Session** | Sesi lelang pembentukan harga pembukaan (08:45 - 08:59 WIB di BEI). | BEI sistem call auction blind book. US: Pre-Market trading kontinu (04:00 - 09:30 EST). |
| 20 | **Sesi Pra-Penutupan** | **Pre-Closing Session** | Sesi pengumpulan order lelang penutupan (15:50 - 16:00 WIB di BEI). | Menghasilkan Closing Price resmi. US: Closing Auction (NYSE Closing Cross). |
| 21 | **Siklus Penyelesaian (T+2)** | **Settlement Cycle (T+2 vs T+1)** | Waktu perpindahan dana dan efek resmi setelah transaksi dieksekusi. | **BEI saat ini T+2**. **US NYSE/NASDAQ telah bermigrasi ke T+1 sejak 28 Mei 2024**. |

---

### Kategori 3: Order Book, Data Pasar & Eksekusi (Market Depth & Execution)

| No | Istilah ID (Bahasa Indonesia) | Istilah EN (English) | Definisi Teknis & Konteks Simulator | Catatan Teknis Simulator |
|:---|:---|:---|:---|:---|
| 22 | **Buku Pesanan / Kedalaman Pasar** | **Order Book / Level 2 Market Depth** | Tampilan antrean kuotasi beli (Bid) dan jual (Offer) di setiap tingkat harga aktif. | Komponen inti UI simulator: Matriks 10 baris `price`, `vol`, `orders`. |
| 23 | **Penawaran Beli (Antrean Beli)** | **Bid / Buy Queue** | Harga dan volume pesanan beli yang menunggu match di sebelah kiri order book. | Order diurutkan: Harga tertinggi prioritas utama, lalu FIFO waktu masuk. |
| 24 | **Penawaran Jual (Antrean Jual / Pasang Harga)**| **Ask / Offer / Sell Queue** | Harga dan volume pesanan jual yang menunggu match di sebelah kanan order book. | Order diurutkan: Harga terendah prioritas utama, lalu FIFO waktu masuk. |
| 25 | **Selisih Bid-Ask (Rentang Harga)** | **Bid-Ask Spread** | Selisih nilai moneter antara Best Offer terendah dengan Best Bid tertinggi. | `Spread = BestAsk - BestBid`. Makin kecil spread, likuiditas makin rapat. |
| 26 | **Pita Transaksi Berjalan** | **Running Trade / Time & Sales / Tape** | Umpan data transaksi real-time yang baru terjadi (`time`, `ticker`, `price`, `vol`, `buyer_type`, `seller_type`). | Fitur visual krusial arcade simulator: animasi scrolling transaksi. |
| 27 | **Pesanan Batas (Order Limit)** | **Limit Order** | Order beli/jual pada level harga tertentu atau lebih baik. Tidak terisi jika harga tidak tercapai. | Default trading di BEI. Order mengantre di buku pesanan jika tidak langsung match. |
| 28 | **Pesanan Pasar (Order Instan)** | **Market Order / Market-to-Limit** | Order beli/jual yang langsung mencocokkan best price saat itu di pasar hingga terpenuhi. | Di BEI disimulasikan sebagai HAKA (beli di Offer) / HAKI (jual di Bid). |
| 29 | **Potong Rugi** | **Cut Loss / Stop-Loss Order** | Aksi menutup posisi pada harga rugi terukur untuk mencegah drawdown modal fatal. | Simulator wajib mendukung simulasi trigger stop-loss otomatis. |
| 30 | **Ambil Untung** | **Take Profit / Target Order** | Aksi melikuidasi posisi yang sedang floating profit pada harga target yang ditentukan. | Simulasi locking reward gain. |
| 31 | **Volume & Nilai Transaksi** | **Trading Volume & Turnover (Notional Value)**| Total lembar/lot yang berpindah tangan dan total nilai rupiah transaksi (`Price * Volume * 100`). | Menghitung bobot turnover saham. |
| 32 | **Prioritas Harga & Waktu** | **Price-Time Priority (FIFO Matching Engine)**| Prinsip algoritma JATS: penawaran terbaik didahulukan; harga sama diurutkan waktu submit. | Rule engine matching simulator: `sort(price DESC/ASC, timestamp ASC)`. |

---

### Kategori 4: Akun Trading, Modal & Portofolio (Account, Balances & Portfolio Metrics)

| No | Istilah ID (Bahasa Indonesia) | Istilah EN (English) | Definisi Teknis & Konteks Simulator | Rumus / Model Data Dart |
|:---|:---|:---|:---|:---|
| 33 | **Modal Virtual / Saldo Kas Simulasi** | **Virtual Cash / Paper Money Balance** | Saldo uang virtual awal yang diberikan ke trader di simulator (e.g., Rp 100.000.000). | `double virtualBalance;` |
| 34 | **Daya Beli** | **Buying Power** | Total dana kas tunai virtual yang tersedia untuk melakukan order beli baru. | `BuyingPower = Cash - PendingBuyOrdersReserve;` |
| 35 | **Rekening Dana Nasabah (RDN)** | **Customer Fund Account / Cash Account** | Rekening bank khusus atas nama investor untuk penampungan dana transaksi saham di sekuritas. | Konsep edukasi penting: membedakan rekening sekuritas vs rekening efek. |
| 36 | **Nomor Identitas Investor Tunggal (SID)** | **Single Investor Identification (SID)** | Nomor identitas tunggal resmi KSEI untuk seluruh kepemilikan efek seorang WNI/Asing. | KSEI identifier format: e.g. `IDD123456789012`. |
| 37 | **Portofolio Saham** | **Stock Portfolio / Investment Holdings** | Daftar seluruh aset efek saham yang saat ini sedang dimiliki dan belum dijual. | `List<PortfolioItem> holdings;` |
| 38 | **Harga Rata-Rata Pembelian** | **Average Price / Cost Basis (Avg Price)** | Rata-rata tertimbang harga beli dari seluruh lot saham yang diakumulasi. | `AvgPrice = Sum(Price_i * Lots_i) / TotalLots;` |
| 39 | **Nilai Pasar Portofolio** | **Current Market Value / Total Equity** | Total nilai valuasi posisi saham saat ini berdasarkan harga transaksi terakhir (Last Price). | `MarketValue = Sum(CurrentPrice * Lots * 100);` |
| 40 | **Laba / Rugi Belum Terealisasi (Floating P/L)** | **Unrealized Profit & Loss (Floating PnL)** | Keuntungan/kerugian nominal dan persentase yang belum dikunci karena posisi masih terbuka. | `FloatingNominal = MarketValue - TotalCost; FloatingPct = (Nominal / Cost) * 100;` |
| 41 | **Laba / Rugi Terealisasi** | **Realized Profit & Loss (Closed PnL)** | Keuntungan/kerugian bersih yang telah resmi terkunci setelah transaksi jual (Sell) tereksekusi. | `Realized = (SellPrice - AvgPrice) * SoldLots * 100 - Fees;` |
| 42 | **Biaya Transaksi (Broker & Pajak)** | **Trading Commission & Taxes (Fee Structure)** | Biaya beli (idx standar ~0.15%) dan jual (~0.25% termasuk PPh final 0.1% + PPN 11% + levies). | Ditiru di simulator untuk mengajarkan realitas net return. |

---

### Kategori 5: Aksi Korporasi & Analisis Fundamental (Corporate Actions & Fundamentals)

| No | Istilah ID (Bahasa Indonesia) | Istilah EN (English) | Definisi Teknis & Konteks Simulator | Siklus / Waktu Pelaksanaan |
|:---|:---|:---|:---|:---|
| 43 | **Dividen Tunai** | **Cash Dividend** | Pembagian laba bersih perseroan kepada pemegang saham secara proporsional dalam bentuk uang tunai. | Masuk ke saldo kas akun simulator jika holding melewati Cum Date. |
| 44 | **Cum Date (Tanggal Cum)** | **Cum-Dividend Date** | Hari bursa terakhir perdagangan saham yang masih berhak mendapatkan hak dividen. | Investor yang memegang saham saat penutupan Cum Date berhak atas dividen. |
| 45 | **Ex Date (Tanggal Ex)** | **Ex-Dividend Date** | Hari bursa pertama di mana perdagangan saham tidak lagi mengandung hak pembagian dividen. | Harga saham saat pembukaan Ex Date biasanya terdiskon sebesar nilai dividen per share (DPS). |
| 46 | **Tanggal Pencatatan (Recording Date)** | **Record Date** | Tanggal KSEI merekap daftar resmi pemegang saham yang tercatat berhak menerima dividen (T+2 dari Cum Date). | Catatan kliring KSEI. |
| 47 | **Tanggal Pembayaran (Payment Date)** | **Payment Date / Distribution Date** | Tanggal dana dividen tunai didistribusikan ke RDN masing-masing investor. | Saldo virtual simulator ditambahkan secara otomatis pada tanggal ini. |
| 48 | **Pemecahan Nilai Saham (Stock Split)** | **Stock Split (Forward Split)** | Aksi korporasi memecah nilai nominal saham untuk menurunkan harga per lembar dan melipatgandakan jumlah lot. | Contoh rasio 1:5, harga Rp10.000 jadi Rp2.000, lot 10 jadi 50. Total modal tetap sama. |
| 49 | **Penggabungan Nilai Saham (Reverse Split)**| **Reverse Stock Split** | Penggabungan beberapa saham menjadi 1 saham baru untuk menaikkan harga per lembar agar tidak di papan FCA. | Contoh 5:1, harga Rp50 jadi Rp250, lot menyusut 80%. |
| 50 | **Hak Memesan Efek Terlebih Dahulu (HMETD)**| **Rights Issue / Pre-emptive Rights** | Hak prioritas bagi pemegang saham lama untuk menyerap penerbitan saham baru perseroan. | Diperdagangkan di pasar tunai dengan ticker kode tambahan `-R` (e.g., `BBRI-R`). |
| 51 | **Penawaran Umum Perdana (IPO)** | **Initial Public Offering (IPO)** | Proses penjualan saham perdana sebuah perusahaan swasta kepada publik di bursa melalui sistem e-IPO. | Fitur simulator: simulasi e-IPO allotting saham. |
| 52 | **Laba Bersih Per Saham** | **Earnings Per Share (EPS)** | Rasio laba bersih emiten dibagi dengan jumlah lembar saham beredar. | Metrik fundamental dasar untuk kalkulasi P/E ratio. |
| 53 | **Rasio Harga terhadap Laba** | **Price-to-Earnings Ratio (PER / P/E)** | Valuasi perbandingan harga saham saat ini terhadap laba bersih per lembar (EPS) tahunan. | Standar evaluasi saham murah vs mahal. |
| 54 | **Rasio Harga terhadap Nilai Buku** | **Price-to-Book Value (PBV)** | Valuasi perbandingan harga pasar saham terhadap nilai buku ekuitas (BVPS). | Standar valuasi emiten perbankan & industri padat modal di BEI. |

---

### Kategori 6: Kultur Pasar, Slang & Analisis Trading (Market Culture, Slang & Psychology)

| No | Istilah ID / Slang BEI | Istilah Global / Wall St Equivalent | Makna Edukasi & Penggunaan di Simulator | Karakteristik Perilaku |
|:---|:---|:---|:---|:---|
| 55 | **HAKA (Hajar Kanan)** | **Hitting the Ask / Lifting the Offer / Aggressive Buy** | Membeli langsung di harga antrean penawaran jual (Offer) tanpa mengantre agar order langsung tereksekusi. | Taktik momentum / breakout trader. Menghabiskan lot di kolom Offer. |
| 56 | **HAKI (Hajar Kiri)** | **Hitting the Bid / Crossing the Spread / Aggressive Sell** | Menjual langsung di harga antrean penawaran beli (Bid) agar order lekas cair tanpa mengantre. | Taktik panic selling atau likuidasi cepat saat harga hendak ambruk. |
| 57 | **Saham Gorengan** | **Penny Stock / Meme Stock / Pump-and-Dump Equities** | Saham berkapitalisasi kecil dengan volatilitas liar yang harganya mudah dimanipulasi oleh oknum pemodal besar. | Karakteristik: fundamental minim, kenaikan mendadak ratusan persen, berisiko ARB berjilid-jilid. |
| 58 | **Saham Blue Chip (Lapis 1)** | **Blue-Chip Stocks / Large-Cap Stalwarts** | Saham perusahaan konglomerasi besar dengan kapitalisasi pasar raksasa, laba stabil, dan dividen rutin (e.g., BBCA, BBRI, ASII, TLKM). | Likuiditas tinggi, volatilitas terjaga, fondasi portofolio jangka panjang. |
| 59 | **Saham Second Liner (Lapis 2)** | **Mid-Cap Growth Stocks** | Saham emiten lapis kedua dengan likuiditas moderat dan potensi pertumbuhan laba agresif. | Rasio risk/reward berimbang. |
| 60 | **Bandar / Bandarmologi** | **Market Makers / Whales / Smart Money Flow / VPA** | Pihak pemodal besar institusi/individu yang memiliki kekuatan kapital untuk mengarahkan pergerakan likuiditas pasar. | Metrik analisa di BEI: Broker Summary (Net Buy/Sell sekuritas asing vs domestik). |
| 61 | **Guyur / Guyuran** | **Dumping / Heavy Sell Wall / Institutional Liquidation** | Tekanan jual masif secara serentak dari pemegang posisi besar yang menekan harga anjlok drastis. | Sering terjadi di pucuk (distribution phase). |
| 62 | **Pom-pom / Pompomers** | **Stock Shilling / Pumpers / Boiler Room Hypers** | Aksi mempromosikan atau menggoreng narasi suatu saham di media sosial oleh influencer agar publik retail masuk (FOMO). | Edukasi modul Trade Heroes: Literasi anti-pompom & manipulasi pasar. |
| 63 | **Nyangkut / Nyangkuters** | **Bagholding / Bagholders** | Kondisi investor memegang saham yang nilainya turun drastis di bawah modal beli dan enggan melakukan cut loss. | Problem psikologis nomor 1 trader pemula akibat menolak mengakui kerugian. |
| 64 | **Serok Bawah** | **Buying the Dip (BTD)** | Strategi akumulasi membeli saham berkualitas pada saat harga mengalami diskon koreksi tajam. | Taktik value investor / contrarian trader saat pasar oversold. |
| 65 | **Arus Dana Asing (Net Foreign Buy/Sell)**| **Foreign Institutional Flow (Inflow / Outflow)** | Akumulasi bersih transaksi investor asing di bursa saham Indonesia. | Sering dijadikan barometer kepercayaan pasar modal makro terhadap IHSG. |
| 66 | **ARA Hunter** | **Momentum Scalper / Breakout Chaser** | Trader harian yang mencari dan menunggangi saham yang sedang mengarah ke batas Auto Rejection Atas (ARA). | Strategi high risk - high return. |

---

### Kategori 7: Arsitektur Simulator & Gamifikasi (Game Mechanics & Simulation Engine)

| No | Istilah ID (Bahasa Indonesia) | Istilah EN (English) | Definisi Teknis & Konteks Engine Simulator | Implementasi Kode Flutter/Dart |
|:---|:---|:---|:---|:---|
| 67 | **Simulasi Perdagangan Kertas (Paper Trading)**| **Paper Trading / Virtual Sandbox** | Lingkungan simulasi bertransaksi pasar modal tanpa risiko finansial nyata menggunakan dana virtual. | Mode inti aplikasi `Trade Heroes`. |
| 68 | **Selisih Harga Eksekusi (Slippage)** | **Execution Slippage** | Selisih antara harga order yang diajukan dengan harga aktual eksekusi akibat pergerakan antrean likuiditas. | Model slippage berbasis kedalaman lot: `FillPrice = ExecutedVWAP;` |
| 69 | **Simulasi Antrean Match (Queue Simulation)**| **Queue Position Simulation** | Model simulasi antrean FIFO pada order limit agar user tidak instan terisi bila belum terjadi matched trade nyata. | Verifikasi volume transaksi berjalan sebelum status `FILLED`. |
| 70 | **Papan Peringkat Trader (Leaderboard)** | **Trader Leaderboard / Portfolio Ranking** | Papan skor perolehan imbal hasil investasi (ROI %) virtual tertinggi antar pengguna. | Sorting berdasarkan: `(TotalEquity - InitialCapital) / InitialCapital * 100`. |
| 71 | **Poin Pengalaman (XP) & Peringkat Level** | **Experience Points (XP) & Hero Tier Rank** | Gamifikasi berupa reward XP setiap kali menyelesaikan kuis materi atau mengeksekusi order dengan disiplin risk management. | `int userXp; String heroTitle;` (e.g., Novice Trader -> Market Master). |

---

## 3. TABEL KOMPARASI MIKROSTRUKTUR: BEI (INDONESIA) VS NYSE/NASDAQ (AMERIKA SERIKAT)

| Aspek / Parameter | Bursa Efek Indonesia (BEI / IDX) | Bursa Amerika Serikat (NYSE / NASDAQ) | Dampak Desain Simulator Saham |
|:---|:---|:---|:---|
| **Satuan Transaksi Utama** | **1 Lot = 100 Lembar** (Wajib kelipatan 100 di Pasar Reguler). | **1 Share** (Bebas satuan 1 lembar, bahkan **Fractional Shares** e.g., 0.05 share). | Input order simulator wajib mengalikan input user dengan 100 lembar untuk valuasi nominal. |
| **Siklus Penyelesaian Dana** | **T+2** (Hari Bursa ke-2). | **T+1** (Bermigrasi sejak Mei 2024 via SEC Rule 15c6-1a). | Edukasi simulator harus menjelaskan jeda likuidasi penarikan dana ke kas tunai. |
| **Mekanisme Batas Volatilitas Harian** | **Auto Rejection Simetris (ARA & ARB)**:<br>• Rp50 - Rp200: **35%**<br>• >Rp200 - Rp5.000: **25%**<br>• >Rp5.000: **20%**<br>Order di luar batas otomatis ditolak JATS. | **Limit Up-Limit Down (LULD)**:<br>• Pause perdagangan 5 menit jika harga bergerak 5%, 10%, atau 20% dalam 5 menit.<br>• Tidak ada batas kenaikan persentase 1 hari (bisa +1000%). | Simulator BEI wajib menolak submit order jika melebihi batas ARA atau di bawah ARB hari tersebut. |
| **Skema Fraksi Harga (Tick Size)** | **5 Rentang Fraksi Baku**:<br>1. < Rp200: Rp 1 (Maks jump 10)<br>2. Rp200 - < Rp500: Rp 2 (Maks jump 20)<br>3. Rp500 - < Rp2.000: Rp 5 (Maks jump 50)<br>4. Rp2.000 - < Rp5.000: Rp 10 (Maks jump 100)<br>5. >= Rp5.000: Rp 25 (Maks jump 250) | **Desimal Tunggal**:<br>• Sebagian besar saham: **$0.01** (1 sen).<br>• Saham di bawah $1: desimal sub-penny ($0.0001). | Price stepper input di Flutter harus mematuhi fraksi harga aktif saham target. |
| **Short Selling (Jual Kosong)** | **Sangat Dibatasi**: Hanya rekening marjin khusus dengan daftar saham eligible BEI. Retail reguler dilarang short. | **Umum & Terbuka**: Trader dengan margin account dapat meminjam saham untuk short selling kapan pun. | Mode simulator default pemula diset *Long Only* (Beli dulu baru Jual). Fitur short ditutup untuk mencegah kebingungan konsep awal. |
| **Jam Perdagangan (WIB vs EST)** | **Senin - Jumat**:<br>• Pra-Buka: 08:45 - 08:59<br>• Sesi 1: 09:00 - 12:00 (Jumat 11:30)<br>• Sesi 2: 13:30 - 15:49 (Jumat 14:00)<br>• Pra-Tutup: 15:50 - 16:00 | **Senin - Jumat (EST)**:<br>• Pre-Market: 04:00 - 09:30<br>• Regular Hours: 09:30 - 16:00<br>• After-Hours: 16:00 - 20:00 | Simulator dapat menyediakan opsi *Mock Live Clock* untuk mensimulasikan jam buka/tutup pasar BEI secara akurat. |
| **Mekanisme Lelang Khusus** | **Full Call Auction (FCA)** pada Papan Pemantauan Khusus: Order book tertutup, harga match tiap sesi lelang periodik. | **Continuous Central Limit Order Book** untuk semua saham reguler. OTC/Pink sheets untuk emiten tidak memenuhi syarat. | Simulator dapat memberikan tanda/badge khusus jika saham berada dalam radar papan pemantauan. |
| **Struktur Biaya Transaksi** | **Komisi + Pajak Final**:<br>• Beli: ~0.15% (Broker + KPEI/KSEI + PPN 11%)<br>• Jual: ~0.25% (termasuk PPh Final 0.1% penjualan saham). | **Zero-Commission Era**:<br>• Broker gratis komisi (PFOF model).<br>• Hanya fee mikro SEC ($0.0000278 per dolar) + FINRA TAF. | Di simulator, pemotongan fee transaksi ~0.15% (Buy) dan ~0.25% (Sell) melatih perhitungan breakeven yang realistis. |

---

## 4. TEMPLATE DATA MODEL & KAMUS KUNCI FLUTTER / DART (TRADE HEROES)

Untuk integrasi langsung dengan Provider / AppState dan sistem multi-bahasa Flutter (`intl` / `.arb`):

### Kamus JSON / ARB File (`app_id.arb` & `app_en.arb`)

```json
{
  "@@locale": "id",
  "market_title": "Pasar Saham",
  "portfolio_title": "Portofolio Saya",
  "virtual_balance": "Modal Virtual",
  "buying_power": "Daya Beli",
  "order_book": "Buku Pesanan",
  "bid": "Beli (Bid)",
  "offer": "Jual (Offer)",
  "running_trade": "Transaksi Berjalan",
  "lot": "Lot (100 Lbr)",
  "shares": "Lembar",
  "buy_action": "Beli Saham",
  "sell_action": "Jual Saham",
  "haka_desc": "Hajar Kanan (Instan Beli)",
  "haki_desc": "Hajar Kiri (Instan Jual)",
  "cut_loss": "Potong Rugi (Cut Loss)",
  "take_profit": "Ambil Untung (Take Profit)",
  "unrealized_pnl": "Floating Laba/Rugi",
  "realized_pnl": "Laba/Rugi Terealisasi",
  "avg_buy_price": "Harga Rata-rata Beli",
  "auto_rejection_up": "Auto Rejection Atas (ARA)",
  "auto_rejection_down": "Auto Rejection Bawah (ARB)",
  "dividend_yield": "Imbal Hasil Dividen",
  "stock_tier_bluechip": "Lapis 1 (Blue Chip)",
  "stock_tier_gorengan": "Saham Gorengan (Spekulatif)",
  "order_status_open": "Menunggu Antrean",
  "order_status_filled": "Tereksekusi",
  "order_status_rejected": "Ditolak (Auto Rejection)"
}
```

```json
{
  "@@locale": "en",
  "market_title": "Stock Market",
  "portfolio_title": "My Portfolio",
  "virtual_balance": "Virtual Balance",
  "buying_power": "Buying Power",
  "order_book": "Order Book",
  "bid": "Bid",
  "offer": "Offer / Ask",
  "running_trade": "Running Trade (Time & Sales)",
  "lot": "Lot (100 Shs)",
  "shares": "Shares",
  "buy_action": "Buy Stock",
  "sell_action": "Sell Stock",
  "haka_desc": "Hit the Ask (Market Buy)",
  "haki_desc": "Hit the Bid (Market Sell)",
  "cut_loss": "Stop Loss / Cut Loss",
  "take_profit": "Take Profit",
  "unrealized_pnl": "Unrealized P&L",
  "realized_pnl": "Realized P&L",
  "avg_buy_price": "Average Cost Basis",
  "auto_rejection_up": "Limit Up (ARA)",
  "auto_rejection_down": "Limit Down (ARB)",
  "dividend_yield": "Dividend Yield",
  "stock_tier_bluechip": "Blue-Chip (Tier 1)",
  "stock_tier_gorengan": "Meme / Penny Stock",
  "order_status_open": "Open Order (In Queue)",
  "order_status_filled": "Filled",
  "order_status_rejected": "Rejected (Auto Rejection)"
}
```

---

## 5. RANGKUMAN PENERAPAN PADA FITUR SIMULATOR TRADE HEROES

1. **Kalkulasi Lot Otomatis:**
   Seluruh input kuantitas di UI adalah `Lot`. Engine simulator mengonversi:
   $$\text{Total Shares} = \text{Lots} \times 100$$
   $$\text{Total Nilai Transaksi} = \text{Lots} \times 100 \times \text{Price}$$
   $$\text{Estimasi Biaya Beli} = \text{Total Nilai Transaksi} \times 1.0015 \quad (0.15\% \text{ fee})$$

2. **Validasi Fraksi Harga (Tick Rules):**
   Mencegah user menginput harga acak di luar fraksi BEI:
   - Jika harga < 200: kelipatan Rp 1
   - Jika harga 200 - 498: kelipatan Rp 2
   - Jika harga 500 - 1.995: kelipatan Rp 5
   - Jika harga 2.000 - 4.990: kelipatan Rp 10
   - Jika harga >= 5.000: kelipatan Rp 25

3. **Validasi ARA / ARB:**
   Sistem menolak pesanan jika harga order beli > batas ARA atau order jual < batas ARB dari harga acuan hari bursa berjalan.
