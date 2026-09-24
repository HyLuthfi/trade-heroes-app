class MateriData {
  MateriData._();

  static List<Map<String, dynamic>> getModules(String language) {
    final isEn = language.toLowerCase().startsWith('en');
    if (isEn) {
      return [
        {
          'id': 1,
          'title': "Introduction to Stock Investing",
          'category': "Beginner Stocks",
          'readTimeStr': "⏱️ 3 Min Read",
          'takeaways': [
            "A stock represents official ownership equity in a public company on the exchange.",
            "Two primary sources of profit: Capital Gains (price appreciation) & Dividends (profit sharing).",
            "Long-term equity investment has historically outperformed annual inflation rates."
          ],
          'desc':
              "Learn what stocks are, how public companies work, and why investing early builds long-term wealth.",
          'content':
              "<h1>Introduction to Stock Investing</h1><p>A stock represents a share in the ownership of a company. When you purchase shares of a publicly traded company on the Indonesia Stock Exchange (IDX), you become an official co-owner of that enterprise, regardless of how small your percentage is.</p><h2>Why Invest in Stocks?</h2><p>Over the long term, stock investments have historically delivered higher average returns compared to inflation and traditional savings accounts. There are two primary sources of stock returns: <b>Capital Gains</b> (the profit from selling shares at a higher price than you bought them) and <b>Dividends</b> (the portion of company earnings distributed directly to shareholders).</p>",
          'xp': 5,
          'isPremium': false
        },
        {
          'id': 2,
          'title': "How to Buy Your First Stock",
          'category': "Practical Guide",
          'readTimeStr': "⏱️ 4 Min Read",
          'takeaways': [
            "Stock trading accounts must be opened through licensed broker-dealers regulated by financial authorities.",
            "Prepare ID, tax ID, and personal bank account to establish a Customer Fund Account (RDN).",
            "Stock purchases on IDX are measured in standard Lots (1 Lot = 100 shares)."
          ],
          'desc':
              "A step-by-step beginner guide from opening a licensed brokerage account to placing your first lot order.",
          'content':
              "<h1>How to Buy Your First Stock</h1><p>To purchase stocks officially, you must register through a licensed Securities Brokerage regulated by the financial authority (such as OJK/SEC).</p><h2>Registration Steps:</h2><p>1. Choose an established brokerage with a responsive mobile trading app and transparent transaction fees.<br>2. Prepare your national identity card, tax number, and active bank account.<br>3. Complete the Customer Fund Account (RDN/RDI) application. The RDN is a segregated bank account held in your name dedicated solely to holding trading capital.<br>4. Transfer your starting capital into your RDN.<br>5. Open your trading app, enter the ticker symbol you wish to buy (e.g., BBCA, ASII, TLKM), specify the quantity in lots (1 lot = 100 shares), and press the BUY button.</p>",
          'xp': 5,
          'isPremium': false
        },
        {
          'id': 3,
          'title': "Reading Simple Financial Statements",
          'category': "Fundamental",
          'readTimeStr': "⏱️ 5 Min Read",
          'takeaways': [
            "3 Pillars of Financial Statements: Balance Sheet (Assets/Liabilities/Equity), Income Statement, and Cash Flow.",
            "Ensure Net Equity is growing steadily and corporate debt remains well under control.",
            "Avoid companies with large accounting profits but consistently negative Operating Cash Flow."
          ],
          'desc':
              "Unpack the three essential financial statements: Balance Sheet, Income Statement, and Cash Flow to spot healthy companies.",
          'content':
              "<h1>Reading Simple Financial Statements</h1><p>Financial statements are a company's financial report card. There are three essential sections every investor must inspect:</p><h2>1. Income Statement</h2><p>Shows how much total revenue the business generated and how much net income remains after deducting operating costs, interest expenses, and corporate taxes.</p><h2>2. Balance Sheet</h2><p>Details company assets, liabilities (debt), and shareholders' equity (net book value). Look for growing equity and conservative debt-to-equity ratios.</p><h2>3. Cash Flow Statement</h2><p>Tracks actual cash inflows and outflows. Companies showing high accounting net income but persistently negative Operating Cash Flow should raise caution.</p>",
          'xp': 5,
          'isPremium': false
        },
        {
          'id': 4,
          'title': "Introduction to Candlestick Charts",
          'category': "Technical",
          'readTimeStr': "⏱️ 4 Min Read",
          'takeaways': [
            "The Candle Body illustrates the distance between the Open and Close prices.",
            "Shadows/Wicks mark the session's Highest (High) and Lowest (Low) traded prices.",
            "A long lower wick indicates strong buying rejection and a potential bullish rebound."
          ],
          'desc':
              "Master candlestick chart reading to interpret short-term price momentum and crowd market psychology.",
          'content':
              "<h1>Introduction to Candlestick Charts</h1><p>Candlestick charts originated with Japanese rice merchants to analyze price momentum. Each candle visually synthesizes price action over a specific timeframe (e.g., 1 day, 1 hour).</p><h2>Anatomy of a Candlestick:</h2><p><b>Body</b>: Shows the range between the open and close price. A green candle indicates prices closed higher than open, while a red candle means prices closed lower.<br><b>Shadow / Wick</b>: Represents the extreme high and low points reached during the session. A long lower shadow indicates buyer rejection at lower levels, signaling potential bullish trend reversal.</p>",
          'xp': 5,
          'isPremium': false
        },
        {
          'id': 5,
          'title': "Secrets to Day Trading Success",
          'category': "Exclusive Trading",
          'readTimeStr': "⏱️ 6 Min Read",
          'takeaways': [
            "Focus on Top Gainer tickers with abnormal opening volume surges.",
            "Evaluate Bid/Offer queue depth to gauge authentic institutional support.",
            "Take quick disciplined gains (1-3%) and enforce strict emotionless Stop Losses."
          ],
          'desc':
              "Strategic playbook for intraday buying and selling using momentum scalping and tape reading techniques.",
          'content':
              "<h1>Secrets to Day Trading Success</h1><p><i>Premium Plan Exclusive Content</i></p><p>Day trading requires laser discipline, rapid execution, and deep order book tape reading skills. The objective is capturing consistent small percentage moves multiple times throughout the trading session.</p><h2>Momentum Scalping Playbook:</h2><p>1. Screen for stocks appearing on the Top Gainers list with heavy opening trading volume surges.<br>2. Inspect Level 2 Bid/Offer queues. Thick bid blocks just below market price indicate buying cushions.<br>3. Enter when price breaks out cleanly above session resistance with calibrated position sizing.<br>4. Take profits rapidly when the trade advances +1% to +3%. Never let greed dictate decisions, and keep strict stop losses in place.</p>",
          'xp': 10,
          'isPremium': true
        },
        {
          'id': 6,
          'title': "Psychology of Professional Traders",
          'category': "Exclusive Trading",
          'readTimeStr': "⏱️ 5 Min Read",
          'takeaways': [
            "Tame FOMO (fear of missing out); profitable setups in the market will always return tomorrow.",
            "Never engage in Revenge Trading; step away from screens when emotionally destabilized.",
            "Write a concrete trading plan before the opening bell and adhere to it without compromise."
          ],
          'desc':
              "Why do 90% of traders fail? Learn how to master greed, fear, and impulsive revenge trades when volatility spikes.",
          'content':
              "<h1>Psychology of Professional Traders</h1><p><i>Premium Plan Exclusive Content</i></p><p>The toughest adversary a trader encounters is not institutional market makers, but their own emotional impulses. Elite traders succeed not through secret indicators, but by maintaining relentless psychological discipline.</p><h2>Core Emotional Mastery Rules:</h2><p><b>FOMO (Fear of Missing Out)</b>: Make peace with stocks that have already surged without you. Markets operate continuously Monday through Friday; fresh setups develop every day.<br><b>Revenge Trading</b>: After experiencing consecutive losses, cease trading immediately. Close monitors, take a walk, and reset mental clarity before deploying another dollar.<br><b>Plan Adherence</b>: Construct entry, stop-loss, and profit targets prior to market open. Execute the plan 100% without second-guessing or hesitation.</p>",
          'xp': 10,
          'isPremium': true
        },
      ];
    }

    // Default Indonesian
    return [
      {
        'id': 1,
        'title': "Pengenalan Investasi Saham",
        'category': "Saham Pemula",
        'readTimeStr': "⏱️ 3 Min Baca",
        'takeaways': [
          "Saham adalah bukti kepemilikan modal resmi atas suatu perusahaan terbuka di BEI.",
          "Dua sumber keuntungan saham: Capital Gain (selisih harga) & Dividen (bagi hasil).",
          "Investasi saham jangka panjang terbukti mampu mengalahkan tingkat inflasi tahunan."
        ],
        'desc':
            "Pelajari apa itu saham, cara kerja perusahaan publik, dan pentingnya berinvestasi saham sejak dini.",
        'content':
            "<h1>Pengenalan Investasi Saham</h1><p>Saham merupakan bukti kepemilikan modal atas suatu perusahaan. Ketika Anda membeli saham dari sebuah perusahaan terbuka di Bursa Efek Indonesia, Anda berhak disebut sebagai salah satu pemilik perusahaan tersebut, sekecil apapun persentase saham yang Anda miliki.</p><h2>Kenapa Harus Investasi Saham?</h2><p>Investasi saham dalam jangka panjang terbukti memberikan imbal hasil rata-rata yang lebih tinggi dibandingkan inflasi maupun instrumen investasi tradisional lainnya seperti tabungan bank. Ada dua sumber keuntungan utama saham: <b>Capital Gain</b> (keuntungan selisih harga jual dan beli) serta <b>Dividen</b> (bagian keuntungan perusahaan yang dibagikan ke pemegang saham).</p>",
        'xp': 5,
        'isPremium': false
      },
      {
        'id': 2,
        'title': "Cara Membeli Saham Pertama Anda",
        'category': "Panduan Praktis",
        'readTimeStr': "⏱️ 4 Min Baca",
        'takeaways': [
          "Pendaftaran beli saham wajib melalui Sekuritas resmi berizin dan diawasi OJK.",
          "Siapkan e-KTP, NPWP, dan rekening bank pribadi untuk membuat RDI (Rekening Dana Investor).",
          "Pembelian saham diukur dalam satuan Lot (1 Lot = 100 lembar saham)."
        ],
        'desc':
            "Panduan lengkap langkah demi langkah mulai dari mendaftar broker saham (sekuritas) hingga melakukan pembelian lot pertama.",
        'content':
            "<h1>Membeli Saham Pertama Anda</h1><p>Untuk membeli saham secara resmi di Indonesia, Anda wajib mendaftar melalui Perusahaan Efek atau biasa disebut Broker/Sekuritas yang telah berizin dan diawasi oleh OJK (Otoritas Jasa Keuangan).</p><h2>Langkah-langkah Pendaftaran:</h2><p>1. Pilih sekuritas yang memiliki aplikasi mobile stabil dan fee transaksi terjangkau.<br>2. Siapkan e-KTP, NPWP, dan rekening tabungan pribadi.<br>3. Isi formulir pembuatan RDI (Rekening Dana Investor). RDI adalah rekening khusus atas nama Anda sendiri untuk menampung dana transaksi saham.<br>4. Transfer modal awal ke RDI.<br>5. Buka aplikasi trading sekuritas Anda, masukkan kode saham yang ingin dibeli (misal: BBCA, ASII, TLKM), tentukan jumlah lot (1 lot = 100 lembar) dan klik tombol BUY.</p>",
        'xp': 5,
        'isPremium': false
      },
      {
        'id': 3,
        'title': "Membaca Laporan Keuangan Sederhana",
        'category': "Fundamental",
        'readTimeStr': "⏱️ 5 Min Baca",
        'takeaways': [
          "3 Pilar Laporan Keuangan: Neraca (Assets/Liabilities), Laba Rugi, dan Arus Kas.",
          "Pastikan Ekuitas (modal bersih) bertumbuh dan utang perusahaan terkendali.",
          "Hindari perusahaan dengan laba akuntansi besar tapi Arus Kas Operasi minus terus."
        ],
        'desc':
            "Kupas tuntas 3 pilar laporan keuangan utama: Neraca, Laba Rugi, dan Arus Kas untuk membedakan perusahaan sehat dan bermasalah.",
        'content':
            "<h1>Membaca Laporan Keuangan Sederhana</h1><p>Laporan keuangan adalah 'raport' kinerja perusahaan. Ada 3 bagian utama yang wajib diperiksa:</p><h2>1. Laporan Laba Rugi (Income Statement)</h2><p>Menunjukkan berapa pendapatan kotor perusahaan dan berapa laba bersih yang tersisa setelah dikurangi biaya operasional, bunga utang, dan pajak.</p><h2>2. Neraca (Balance Sheet)</h2><p>Menunjukkan aset perusahaan, utang (liabilitas), dan modal bersih (ekuitas). Pastikan ekuitas bertumbuh dan utang perusahaan tidak terlalu besar dibanding modalnya.</p><h2>3. Laporan Arus Kas (Cash Flow)</h2><p>Mencatat keluar masuknya uang tunai riil. Perusahaan yang mencetak laba buku tetapi arus kas operasinya minus terus menerus patut dicurigai.</p>",
        'xp': 5,
        'isPremium': false
      },
      {
        'id': 4,
        'title': "Pengenalan Grafik Candlestick",
        'category': "Teknikal",
        'readTimeStr': "⏱️ 4 Min Baca",
        'takeaways': [
          "Badan (Body) lilin menunjukkan jarak antara harga Pembukaan (Open) dan Penutupan (Close).",
          "Sumbu/Ekor (Shadow) menggambarkan harga Tertinggi (High) dan Terendah (Low).",
          "Ekor panjang di bawah mengindikasikan penolakan harga dan potensi pantulan naik."
        ],
        'desc':
            "Dasar membaca candlestick chart untuk memprediksi arah pergerakan harga jangka pendek berdasarkan psikologi pasar.",
        'content':
            "<h1>Pengenalan Grafik Candlestick</h1><p>Grafik candlestick awalnya digunakan oleh pedagang beras di Jepang untuk membaca pergerakan harga. Setiap lilin (candle) menggambarkan dinamika pergerakan harga dalam satu satuan waktu (misal: 1 hari, 1 jam).</p><h2>Bagian-bagian Candlestick:</h2><p><b>Badan (Body)</b>: Menunjukkan jarak harga pembukaan (open) dan penutupan (close). Lilin hijau artinya harga ditutup naik, sedangkan lilin merah artinya harga ditutup turun.<br><b>Sumbu/Ekor (Shadow)</b>: Menunjukkan harga tertinggi (atas) dan terendah (bawah) yang sempat disentuh selama periode tersebut. Ekor yang panjang menggambarkan penolakan harga (price rejection) dan menjadi sinyal pembalikan arah pasar.</p>",
        'xp': 5,
        'isPremium': false
      },
      {
        'id': 5,
        'title': "Rahasia Sukses Day Trading Saham",
        'category': "Eksklusif Trading",
        'readTimeStr': "⏱️ 6 Min Baca",
        'takeaways': [
          "Fokus pada saham Top Gainers dengan lonjakan volume transaksi tinggi di pagi hari.",
          "Pantau ketebalan antrean Bid/Offer demi mengukur dukungan pembeli.",
          "Disiplin ambil cuan cepat (1-3%) dan gunakan Stop Loss ketat tanpa emosi."
        ],
        'desc':
            "Panduan strategi membeli dan menjual saham di hari yang sama dengan teknik scalping kilat memanfaatkan volatilitas tinggi.",
        'content':
            "<h1>Rahasia Sukses Day Trading Saham</h1><p><i>Konten Eksklusif Premium Plan</i></p><p>Day trading atau trading harian memerlukan disiplin luar biasa, refleks cepat, dan pemahaman mendalam tentang likuiditas bid/offer (tape reading). Strategi ini berfokus pada perolehan cuan kecil berkali-kali dalam sehari.</p><h2>Strategi Scalping Momentum:</h2><p>1. Carilah saham-saham yang masuk dalam daftar Top Gainers dengan volume transaksi melonjak tajam di pagi hari.<br>2. Perhatikan antrean Bid/Offer. Bid tebal di bawah harga berjalan menunjukkan penyangga beli yang kuat.<br>3. Masuk transaksi saat terjadi penembusan harga tertinggi hari itu (breakout high) dengan alokasi modal kecil.<br>4. Segera jual saat harga bergerak naik 1-3%. Jangan serakah, pasang stop loss ketat demi mengamankan modal Anda.</p>",
        'xp': 10,
        'isPremium': true
      },
      {
        'id': 6,
        'title': "Psikologi Trader Profesional",
        'category': "Eksklusif Trading",
        'readTimeStr': "⏱️ 5 Min Baca",
        'takeaways': [
          "Kendalikan FOMO (takut ketinggalan cuan); kesempatan di pasar saham selalu ada.",
          "Hindari Revenge Trading (balas dendam setelah rugi); istirahat saat pikiran emosional.",
          "Tulis trading plan resmi sebelum pasar buka dan patuhi 100% tanpa pengecualian."
        ],
        'desc':
            "Mengapa 90% trader gagal? Pelajari cara mengendalikan keserakahan (greed), ketakutan (fear), dan emosi balas dendam saat pasar crash.",
        'content':
            "<h1>Psikologi Trader Profesional</h1><p><i>Konten Eksklusif Premium Plan</i></p><p>Musuh utama seorang trader bukanlah market maker atau bandar, melainkan cerminan emosi diri sendiri. Trader profesional sukses bukan karena memiliki indikator ajaib, melainkan karena mampu mengendalikan emosinya secara konsisten.</p><h2>Metode Pengendalian Emosi Trading:</h2><p><b>FOMO (Fear of Missing Out)</b>: Belajarlah merelakan saham yang sudah naik terlalu tinggi tanpa Anda. Pasar saham selalu buka setiap hari Senin-Jumat, kesempatan baru akan selalu ada.<br><b>Revenge Trading</b>: Setelah mengalami loss beruntun, berhentilah trading hari itu. Tutup monitor, pergi berjalan-jalan, pulihkan kejernihan berpikir Anda.<br><b>Disiplin Rencana</b>: Tulislah rencana trading sebelum pasar buka: beli di harga berapa, stop loss di berapa, dan target profit di berapa. Patuhi 100% rencana tersebut tanpa tawar-menawar.</p>",
        'xp': 10,
        'isPremium': true
      }
    ];
  }

  static List<Map<String, dynamic>> getTradingTips(String language) {
    final isEn = language.toLowerCase().startsWith('en');
    if (isEn) {
      return [
        {
          'id': 1,
          'title': "The 2% Risk Management Rule",
          'desc':
              "Learn the core mathematical formula to protect your trading capital from ruin during adverse market streaks.",
          'tag': "Risk Management",
          'isPdf': true,
          'isPremium': false,
          'content':
              "RISK MANAGEMENT: THE 2% RULE\n\nIn professional trading, capital preservation is job number one. The 2% rule dictates that you must never risk more than 2% of your total account equity on any single trade.\n\nPractical Example:\nSuppose you hold IDR 10,000,000 in your customer trading account (RDN). Your maximum risk per trade is:\nIDR 10,000,000 x 2% = IDR 200,000\n\nIf you plan to buy stock ABCD at IDR 1,000 with a planned stop-loss at IDR 950 (risk per share = IDR 50):\nNumber of shares = Max Risk / Risk per Share\nNumber of shares = IDR 200,000 / IDR 50 = 4,000 shares (40 lots)\n\nBy systematically applying this sizing rule, it would require 50 consecutive total failures to deplete your account—an extreme statistical rarity under rational trading strategies."
        },
        {
          'id': 2,
          'title': "How to Select Blue Chip Stocks",
          'desc':
              "Essential criteria for selecting top-tier large-cap companies ideal for beginner long-term investment portfolios.",
          'tag': "Investing",
          'isPdf': false,
          'isPremium': false,
          'content':
              "HOW TO SELECT BLUE CHIP STOCKS\n\nBlue Chip stocks represent premier listed companies renowned for financial strength, dependable earnings, and regular dividend distributions. In Indonesia, these are primarily constituents of the LQ45 index.\n\nKey Selection Criteria:\n1. Large Market Capitalization: Total market cap exceeding IDR 10 Trillion, preventing unilateral price manipulation.\n2. Predictable Earnings Trajectory: Sustained net income expansion across multi-year cycles rather than cyclical windfalls.\n3. Industry Market Leadership: Dominant providers of essential everyday products and services (e.g. tier-1 banks, consumer staples giants).\n4. Reliable Dividend Track Record: Annual dividend payments that demonstrate authentic cash generation."
        },
        {
          'id': 3,
          'title': "Mastering FOMO & Greed",
          'desc':
              "Practical psychological techniques to resist buying stocks at overextended peak levels driven by emotion.",
          'tag': "Psychology",
          'isPdf': false,
          'isPremium': false,
          'content':
              "MASTERING FOMO & GREED\n\nThe two greatest destroyers of retail trading capital are Fear and Greed. Chasing a stock simply because its price surged double digits in a morning session is greed masquerading as fear of missing out (FOMO).\n\nPractical Antidotes to FOMO:\nThe 24-Hour Rule: When encountering 'hot' ticker tips across social feeds, never buy impulsively. Add the stock to your watchlist and analyze its fundamentals and technical structure after the closing bell. Only execute if objective criteria are met.\n\nRespect Market Cycles: Every rapid vertical rally requires healthy price consolidation. Waiting for orderly pullbacks into technical support is infinitely safer than chasing peak momentum."
        },
        {
          'id': 4,
          'title': "Exclusive Swing Trading Strategy",
          'desc':
              "Comprehensive framework for detecting multi-day trend reversals using Moving Averages and MACD indicators.",
          'tag': "Trading Strategy",
          'isPdf': true,
          'isPremium': true,
          'content':
              "PREMIUM SWING TRADING STRATEGY\n\nSwing trading aims to capture multi-day to multi-week price swings within prevailing market trends.\n\nCore Indicator Setup:\n1. Exponential Moving Averages: EMA 20 & EMA 50.\n2. MACD (Moving Average Convergence Divergence) with standard parameters (12, 26, 9).\n\nEntry Rules (Buy):\nExecute buy orders upon a Golden Cross: EMA 20 crossing upward above EMA 50, alongside MACD crossing above its signal line from below zero.\n\nExit Rules (Sell):\nClose long positions when price closes decisively below the EMA 20, or when MACD creates a Death Cross in overbought territory."
        }
      ];
    }

    // Default Indonesian
    return [
      {
        'id': 1,
        'title': "Panduan Manajemen Risiko 2%",
        'desc':
            "Pelajari rumus baku matematika untuk menjaga akun trading Anda agar tidak pernah bangkrut meski sering rugi.",
        'tag': "Manajemen Risiko",
        'isPdf': true,
        'isPremium': false,
        'content':
            "MANAJEMEN RISIKO: ATURAN 2%\n\nDalam dunia trading profesional, mempertahankan modal adalah tugas nomor satu. Aturan 2% menyatakan bahwa Anda tidak boleh merisikokan lebih dari 2% dari total modal Anda pada satu transaksi tunggal.\n\nContoh Kasus Riil:\nAnda memiliki modal Rp 10.000.000 di akun dana investor (RDI). Maka risiko maksimal Anda per transaksi adalah:\nRp 10.000.000 x 2% = Rp 200.000\n\nJika Anda ingin membeli saham ABCD di harga Rp 1.000 dan berencana melakukan stop loss di harga Rp 950 (risiko per lembar saham adalah Rp 50), berapa lembar saham yang boleh Anda beli?\n\nJumlah saham = Risiko Maksimal / Risiko per Lembar\nJumlah saham = Rp 200.000 / Rp 50 = 4.000 lembar saham (40 lot)\n\nDengan disiplin menerapkan aturan ini, Anda membutuhkan 50 kali kesalahan transaksi beruntun untuk menghabiskan modal Anda. Sesuatu yang sangat jarang terjadi jika Anda memiliki strategi yang rasional."
      },
      {
        'id': 2,
        'title': "Cara Memilih Saham Blue Chip",
        'desc':
            "Kriteria memilih saham lapis satu yang aman dikoleksi oleh pemula untuk investasi jangka panjang.",
        'tag': "Investasi",
        'isPdf': false,
        'isPremium': false,
        'content':
            "Cara Memilih Saham Blue Chip\n\nSaham Blue Chip (lapis satu) adalah saham dari perusahaan papan atas yang memiliki reputasi prima, fundamental bisnis kuat, dan rutin membagikan dividen. Di Indonesia, saham-saham ini biasanya terdaftar dalam indeks LQ45.\n\nKriteria Utama Saham Blue Chip:\n1. Nilai Kapitalisasi Pasar Besar: Memiliki kapitalisasi pasar di atas Rp 10 Triliun, sehingga harganya sulit dimanipulasi oleh pelaku pasar bermodal besar.\n2. Kinerja Keuangan Konsisten: Membukukan pertumbuhan laba bersih yang stabil hampir setiap tahun, bukan emiten musiman.\n3. Pemimpin Pasar (Market Leader): Merupakan produsen barang/jasa yang dominan dan produknya digunakan oleh mayoritas masyarakat secara harian (contoh: perbankan besar, konsumer raksasa).\n4. Rutin Dividen: Selalu membagi dividen kepada pemegang saham setiap tahun sebagai bukti nyata bahwa perusahaan mencetak keuntungan tunai nyata."
      },
      {
        'id': 3,
        'title': "Mengatasi FOMO & Serakah",
        'desc':
            "Tips psikologi praktis menahan diri untuk tidak membeli saham di harga pucuk karena emosi.",
        'tag': "Psikologi",
        'isPdf': false,
        'isPremium': false,
        'content':
            "Mengatasi FOMO & Serakah\n\nDua emosi terbesar penghancur portofolio investasi adalah Fear (ketakutan) dan Greed (keserakahan). Membeli saham hanya karena melihat harganya naik puluhan persen dalam sehari adalah bentuk keserakahan yang dibungkus rasa takut tertinggal (FOMO).\n\nCara Menghindari Jebakan FOMO:\nTerapkan Aturan 24 Jam: Ketika Anda mendapat rekomendasi saham 'panas' dari media sosial, jangan langsung membeli. Masukkan saham tersebut ke dalam daftar pantau (watchlist) dan analisislah secara objektif setelah pasar tutup. Jika keesokan harinya analisis fundamental/teknikal Anda tetap mendukung, barulah Anda boleh bertransaksi.\n\nIngat Siklus Pasar: Apapun yang naik terlalu cepat, pasti akan turun untuk konsolidasi. Menunggu harga koreksi ke area support (retracement) jauh lebih aman daripada mengejar harga di pucuk trend."
      },
      {
        'id': 4,
        'title': "Strategi Swing Trading Eksklusif",
        'desc':
            "Strategi komprehensif mendeteksi pembalikan arah tren menggunakan indikator Moving Average.",
        'tag': "Strategi Trading",
        'isPdf': true,
        'isPremium': true,
        'content':
            "STRATEGI SWING TRADING PREMIUM\n\nSwing trading bertujuan memanfaatkan ayunan harga saham dalam rentang waktu beberapa hari hingga beberapa minggu.\n\nIndikator yang digunakan:\n1. Exponential Moving Average 20 (EMA 20) & EMA 50.\n2. Indikator MACD (Moving Average Convergence Divergence) dengan parameter standar (12, 26, 9).\n\nAturan Entry (Membeli):\nLakukan pembelian (Buy) saat terjadi Golden Cross: EMA 20 memotong ke atas EMA 50, dan garis MACD memotong ke atas garis sinyal di bawah area nol.\n\nAturan Exit (Menjual):\nJual saham Anda ketika harga menembus ke bawah garis EMA 20, atau ketika MACD membentuk Death Cross di area atas."
      }
    ];
  }

  static List<Map<String, dynamic>> getGlossary(String language) {
    final isEn = language.toLowerCase().startsWith('en');
    if (isEn) {
      return [
        {
          'term': "Bullish",
          'def':
              "A market condition where asset prices are consistently trending upward over a sustained period. Named 'bull' because a bull charges enemies with an upward horn thrust.",
          'example':
              "BBCA stock is moving bullish today, breaking out to a fresh all-time high."
        },
        {
          'term': "Bearish",
          'def':
              "A market condition where asset prices are trending downward. Named 'bear' because a bear attacks by swiping downward with its claws.",
          'example':
              "Disappointing quarterly earnings triggered broad bearish sentiment across commodity stocks."
        },
        {
          'term': "Dividend",
          'def':
              "A cash distribution of company profits directly paid to shareholders, approved during the Annual General Meeting of Shareholders (AGMS).",
          'example':
              "The issuer declared a final cash dividend of IDR 150 per share."
        },
        {
          'term': "IPO (Initial Public Offering)",
          'def':
              "The official process through which a private company offers shares to the public for the first time, listing on a recognized stock exchange as a public corporation (Tbk).",
          'example':
              "The tech startup is preparing its IPO next year targeting IDR 1 Trillion in fresh expansion capital."
        },
        {
          'term': "Round Lot (Lot Size)",
          'def':
              "The standard unit of stock trading on the exchange. Under current IDX trading rules, 1 round lot equals exactly 100 shares.",
          'example':
              "Alex purchased 5 lots of TLKM shares at IDR 4,000 per share, committing IDR 2,000,000 in capital."
        },
        {
          'term': "Blue Chip",
          'def':
              "Tier-one, large-cap companies characterized by immense market capitalization, high liquidity, resilient business balance sheets, and sector leadership.",
          'example':
              "State-owned banking stocks remain favorite blue chip holdings among institutional fund managers."
        },
        {
          'term': "IDX Composite (IHSG)",
          'def':
              "Indeks Harga Saham Gabungan (Composite Index). A market-cap weighted benchmark tracking the performance of all common equities listed on the Indonesia Stock Exchange.",
          'example':
              "The IDX Composite rallied 0.5% today to close at 7,200 supported by net foreign inflows."
        },
        {
          'term': "Capital Gain",
          'def':
              "Net financial profit realized when an investor sells an equity asset at a higher price than the initial acquisition cost.",
          'example':
              "She realized a 25% capital gain after patiently holding the stock position for six months."
        },
        {
          'term': "Cut Loss (Stop-Loss)",
          'def':
              "A disciplined risk management decision to liquidate an open trade at a measured deficit to protect total capital from devastating downside drawdowns.",
          'example':
              "The disciplined trader executed an automatic cut loss at 3% when key support collapsed."
        },
        {
          'term': "RDN / RDI (Segregated Account)",
          'def':
              "Rekening Dana Nasabah (Customer Fund Account). A segregated personal bank account held in the investor's legal name dedicated specifically to holding trading capital at a broker-dealer.",
          'example':
              "Ensure your RDN has sufficient buying power before placing aggressive intraday buy orders."
        }
      ];
    }

    // Default Indonesian
    return [
      {
        'term': "Bullish",
        'def':
            "Kondisi di mana pasar atau harga saham sedang mengalami tren naik secara konsisten dalam jangka waktu tertentu. Dinamakan 'bull' karena banteng menyerang musuh dengan menanduk ke atas.",
        'example':
            "Saham BBCA sedang bergerak bullish, mencetak rekor harga tertinggi baru hari ini."
      },
      {
        'term': "Bearish",
        'def':
            "Kondisi pasar atau harga saham yang sedang dalam tren turun. Dinamakan 'bear' karena beruang menyerang musuhnya dengan mencakar ke bawah.",
        'example':
            "Rilis laporan keuangan yang buruk memicu sentimen bearish pada saham komoditas itu."
      },
      {
        'term': "Dividen",
        'def':
            "Bagian keuntungan perusahaan yang dibagikan secara tunai kepada para pemegang saham, disetujui melalui Rapat Umum Pemegang Saham (RUPS).",
        'example':
            "Emiten tersebut mengumumkan pembagian dividen final sebesar Rp 150 per lembar saham."
      },
      {
        'term': "IPO (Initial Public Offering)",
        'def':
            "Proses penawaran perdana saham perusahaan tertutup kepada masyarakat luas sehingga resmi terdaftar di bursa efek menjadi perusahaan publik (tbk).",
        'example':
            "Perusahaan start-up teknologi itu bersiap melakukan IPO tahun depan dengan target dana Rp 1 Triliun."
      },
      {
        'term': "Lot",
        'def':
            "Satuan resmi perdagangan saham di bursa efek. Berdasarkan aturan BEI saat ini, 1 lot setara dengan 100 lembar saham.",
        'example':
            "Budi membeli 5 lot saham TLKM pada harga Rp 4.000 per lembar, menghabiskan dana Rp 2.000.000."
      },
      {
        'term': "Blue Chip",
        'def':
            "Istilah untuk saham lapis satu yang memiliki kapitalisasi pasar sangat besar, likuiditas tinggi, bisnis stabil, dan pemimpin di sektornya.",
        'example':
            "Saham perbankan BUMN termasuk kategori saham blue chip favorit para manajer investasi."
      },
      {
        'term': "IHSG",
        'def':
            "Indeks Harga Saham Gabungan. Angka rata-rata yang mencerminkan pergerakan seluruh saham yang tercatat di Bursa Efek Indonesia secara keseluruhan.",
        'example':
            "IHSG hari ini ditutup menguat 0.5% ke level 7.200 didorong oleh pembelian investor asing."
      },
      {
        'term': "Capital Gain",
        'def':
            "Keuntungan bersih yang didapatkan oleh investor dari selisih harga jual saham yang lebih tinggi dibandingkan dengan harga belinya.",
        'example':
            "Ia meraup capital gain sebesar 25% setelah menyimpan saham tersebut selama enam bulan."
      },
      {
        'term': "Cut Loss (Stop-Loss)",
        'def':
            "Aksi menutup posisi pada kerugian terukur untuk melindungi modal trading agar tidak mengalami penurunan drawdown fatal.",
        'example':
            "Trader disiplin melakukan cut loss di minus 3% saat level support krusial jebol."
      },
      {
        'term': "RDN / RDI (Rekening Investor)",
        'def':
            "Rekening Dana Nasabah (Customer Fund Account). Rekening bank khusus atas nama investor sendiri untuk menampung modal transaksi saham di sekuritas.",
        'example':
            "Pastikan saldo kas di RDN Anda mencukupi sebelum mengirim pesanan beli di jam bursa."
      }
    ];
  }
}
