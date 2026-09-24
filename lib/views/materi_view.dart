import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../state/app_state.dart';
import '../widgets/ad_overlay.dart';
import '../widgets/vip_pass_modal.dart';
import 'package:path_provider/path_provider.dart';

class MateriView extends StatefulWidget {
  const MateriView({Key? key}) : super(key: key);

  @override
  State<MateriView> createState() => _MateriViewState();
}

class _MateriViewState extends State<MateriView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final List<Map<String, dynamic>> _modules = [
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
      'desc': "Pelajari apa itu saham, cara kerja perusahaan publik, dan pentingnya berinvestasi saham sejak dini.",
      'content': "<h1>Pengenalan Investasi Saham</h1><p>Saham merupakan bukti kepemilikan modal atas suatu perusahaan. Ketika Anda membeli saham dari sebuah perusahaan terbuka di Bursa Efek Indonesia, Anda berhak disebut sebagai salah satu pemilik perusahaan tersebut, sekecil apapun persentase saham yang Anda miliki.</p><h2>Kenapa Harus Investasi Saham?</h2><p>Investasi saham dalam jangka panjang terbukti memberikan imbal hasil rata-rata yang lebih tinggi dibandingkan inflasi maupun instrumen investasi tradisional lainnya seperti tabungan bank. Ada dua sumber keuntungan utama saham: <b>Capital Gain</b> (keuntungan selisih harga jual dan beli) serta <b>Dividen</b> (bagian keuntungan perusahaan yang dibagikan ke pemegang saham).</p>",
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
      'desc': "Panduan lengkap langkah demi langkah mulai dari mendaftar broker saham (sekuritas) hingga melakukan pembelian lot pertama.",
      'content': "<h1>Membeli Saham Pertama Anda</h1><p>Untuk membeli saham secara resmi di Indonesia, Anda wajib mendaftar melalui Perusahaan Efek atau biasa disebut Broker/Sekuritas yang telah berizin dan diawasi oleh OJK (Otoritas Jasa Keuangan).</p><h2>Langkah-langkah Pendaftaran:</h2><p>1. Pilih sekuritas yang memiliki aplikasi mobile stabil dan fee transaksi terjangkau.<br>2. Siapkan e-KTP, NPWP, dan rekening tabungan pribadi.<br>3. Isi formulir pembuatan RDI (Rekening Dana Investor). RDI adalah rekening khusus atas nama Anda sendiri untuk menampung dana transaksi saham.<br>4. Transfer modal awal ke RDI.<br>5. Buka aplikasi trading sekuritas Anda, masukkan kode saham yang ingin dibeli (misal: BBCA, ASII, TLKM), tentukan jumlah lot (1 lot = 100 lembar) dan klik tombol BUY.</p>",
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
      'desc': "Kupas tuntas 3 pilar laporan keuangan utama: Neraca, Laba Rugi, dan Arus Kas untuk membedakan perusahaan sehat dan bermasalah.",
      'content': "<h1>Membaca Laporan Keuangan Sederhana</h1><p>Laporan keuangan adalah 'raport' kinerja perusahaan. Ada 3 bagian utama yang wajib diperiksa:</p><h2>1. Laporan Laba Rugi (Income Statement)</h2><p>Menunjukkan berapa pendapatan kotor perusahaan dan berapa laba bersih yang tersisa setelah dikurangi biaya operasional, bunga utang, dan pajak.</p><h2>2. Neraca (Balance Sheet)</h2><p>Menunjukkan aset perusahaan, utang (liabilitas), dan modal bersih (ekuitas). Pastikan ekuitas bertumbuh dan utang perusahaan tidak terlalu besar dibanding modalnya.</p><h2>3. Laporan Arus Kas (Cash Flow)</h2><p>Mencatat keluar masuknya uang tunai riil. Perusahaan yang mencetak laba buku tetapi arus kas operasinya minus terus menerus patut dicurigai.</p>",
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
      'desc': "Dasar membaca candlestick chart untuk memprediksi arah pergerakan harga jangka pendek berdasarkan psikologi pasar.",
      'content': "<h1>Pengenalan Grafik Candlestick</h1><p>Grafik candlestick awalnya digunakan oleh pedagang beras di Jepang untuk membaca pergerakan harga. Setiap lilin (candle) menggambarkan dinamika pergerakan harga dalam satu satuan waktu (misal: 1 hari, 1 jam).</p><h2>Bagian-bagian Candlestick:</h2><p><b>Badan (Body)</b>: Menunjukkan jarak harga pembukaan (open) dan penutupan (close). Lilin hijau artinya harga ditutup naik, sedangkan lilin merah artinya harga ditutup turun.<br><b>Sumbu/Ekor (Shadow)</b>: Menunjukkan harga tertinggi (atas) dan terendah (bawah) yang sempat disentuh selama periode tersebut. Ekor yang panjang menggambarkan penolakan harga (price rejection) dan menjadi sinyal pembalikan arah pasar.</p>",
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
      'desc': "Panduan strategi membeli dan menjual saham di hari yang sama dengan teknik scalping kilat memanfaatkan volatilitas tinggi.",
      'content': "<h1>Rahasia Sukses Day Trading Saham</h1><p><i>Konten Eksklusif Premium Plan</i></p><p>Day trading atau trading harian memerlukan disiplin luar biasa, refleks cepat, dan pemahaman mendalam tentang likuiditas bid/offer (tape reading). Strategi ini berfokus pada perolehan cuan kecil berkali-kali dalam sehari.</p><h2>Strategi Scalping Momentum:</h2><p>1. Carilah saham-saham yang masuk dalam daftar Top Gainers dengan volume transaksi melonjak tajam di pagi hari.<br>2. Perhatikan antrean Bid/Offer. Bid tebal di bawah harga berjalan menunjukkan penyangga beli yang kuat.<br>3. Masuk transaksi saat terjadi penembusan harga tertinggi hari itu (breakout high) dengan alokasi modal kecil.<br>4. Segera jual saat harga bergerak naik 1-3%. Jangan serakah, pasang stop loss ketat demi mengamankan modal Anda.</p>",
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
      'desc': "Mengapa 90% trader gagal? Pelajari cara mengendalikan keserakahan (greed), ketakutan (fear), dan emosi balas dendam saat pasar crash.",
      'content': "<h1>Psikologi Trader Profesional</h1><p><i>Konten Eksklusif Premium Plan</i></p><p>Musuh utama seorang trader bukanlah market maker atau bandar, melainkan cerminan emosi diri sendiri. Trader profesional sukses bukan karena memiliki indikator ajaib, melainkan karena mampu mengendalikan emosinya secara konsisten.</p><h2>Metode Pengendalian Emosi Trading:</h2><p><b>FOMO (Fear of Missing Out)</b>: Belajarlah merelakan saham yang sudah naik terlalu tinggi tanpa Anda. Pasar saham selalu buka setiap hari Senin-Jumat, kesempatan baru akan selalu ada.<br><b>Revenge Trading</b>: Setelah mengalami loss beruntun, berhentilah trading hari itu. Tutup monitor, pergi berjalan-jalan, pulihkan kejernihan berpikir Anda.<br><b>Disiplin Rencana</b>: Tulislah rencana trading sebelum pasar buka: beli di harga berapa, stop loss di berapa, dan target profit di berapa. Patuhi 100% rencana tersebut tanpa tawar-menawar.</p>",
      'xp': 10,
      'isPremium': true
    }
  ];

  final List<Map<String, dynamic>> _tradingTips = [
    {
      'id': 1,
      'title': "Panduan Manajemen Risiko 2%",
      'desc': "Pelajari rumus baku matematika untuk menjaga akun trading Anda agar tidak pernah bangkrut meski sering rugi.",
      'tag': "Manajemen Risiko",
      'isPdf': true,
      'isPremium': false,
      'content': "MANAJEMEN RISIKO: ATURAN 2%\n\nDalam dunia trading profesional, mempertahankan modal adalah tugas nomor satu. Aturan 2% menyatakan bahwa Anda tidak boleh merisikokan lebih dari 2% dari total modal Anda pada satu transaksi tunggal.\n\nContoh Kasus Riil:\nAnda memiliki modal Rp 10.000.000 di akun dana investor (RDI). Maka risiko maksimal Anda per transaksi adalah:\nRp 10.000.000 x 2% = Rp 200.000\n\nJika Anda ingin membeli saham ABCD di harga Rp 1.000 dan berencana melakukan stop loss di harga Rp 950 (risiko per lembar saham adalah Rp 50), berapa lembar saham yang boleh Anda beli?\n\nJumlah saham = Risiko Maksimal / Risiko per Lembar\nJumlah saham = Rp 200.000 / Rp 50 = 4.000 lembar saham (40 lot)\n\nDengan disiplin menerapkan aturan ini, Anda membutuhkan 50 kali kesalahan transaksi beruntun untuk menghabiskan modal Anda. Sesuatu yang sangat jarang terjadi jika Anda memiliki strategi yang rasional."
    },
    {
      'id': 2,
      'title': "Cara Memilih Saham Blue Chip",
      'desc': "Kriteria memilih saham lapis satu yang aman dikoleksi oleh pemula untuk investasi jangka panjang.",
      'tag': "Investasi",
      'isPdf': false,
      'isPremium': false,
      'content': "Cara Memilih Saham Blue Chip\n\nSaham Blue Chip (lapis satu) adalah saham dari perusahaan papan atas yang memiliki reputasi prima, fundamental bisnis kuat, dan rutin membagikan dividen. Di Indonesia, saham-saham ini biasanya terdaftar dalam indeks LQ45.\n\nKriteria Utama Saham Blue Chip:\n1. Nilai Kapitalisasi Pasar Besar: Memiliki kapitalisasi pasar di atas Rp 10 Triliun, sehingga harganya sulit dimanipulasi oleh pelaku pasar bermodal besar.\n2. Kinerja Keuangan Konsisten: Membukukan pertumbuhan laba bersih yang stabil hampir setiap tahun, bukan emiten musiman.\n3. Pemimpin Pasar (Market Leader): Merupakan produsen barang/jasa yang dominan dan produknya digunakan oleh mayoritas masyarakat secara harian (contoh: perbankan besar, konsumer raksasa).\n4. Rutin Dividen: Selalu membagi dividen kepada pemegang saham setiap tahun sebagai bukti nyata bahwa perusahaan mencetak keuntungan tunai nyata."
    },
    {
      'id': 3,
      'title': "Mengatasi FOMO & Serakah",
      'desc': "Tips psikologi praktis menahan diri untuk tidak membeli saham di harga pucuk karena emosi.",
      'tag': "Psikologi",
      'isPdf': false,
      'isPremium': false,
      'content': "Mengatasi FOMO & Serakah\n\nDua emosi terbesar penghancur portofolio investasi adalah Fear (ketakutan) dan Greed (keserakahan). Membeli saham hanya karena melihat harganya naik puluhan persen dalam sehari adalah bentuk keserakahan yang dibungkus rasa takut tertinggal (FOMO).\n\nCara Menghindari Jebakan FOMO:\nTerapkan Aturan 24 Jam: Ketika Anda mendapat rekomendasi saham 'panas' dari media sosial, jangan langsung membeli. Masukkan saham tersebut ke dalam daftar pantau (watchlist) dan analisislah secara objektif setelah pasar tutup. Jika keesokan harinya analisis fundamental/teknikal Anda tetap mendukung, barulah Anda boleh bertransaksi.\n\nIngat Siklus Pasar: Apapun yang naik terlalu cepat, pasti akan turun untuk konsolidasi. Menunggu harga koreksi ke area support (retracement) jauh lebih aman daripada mengejar harga di pucuk trend."
    },
    {
      'id': 4,
      'title': "Strategi Swing Trading Eksklusif",
      'desc': "Strategi komprehensif mendeteksi pembalikan arah tren menggunakan indikator Moving Average.",
      'tag': "Strategi Trading",
      'isPdf': true,
      'isPremium': true,
      'content': "STRATEGI SWING TRADING PREMIUM\n\nSwing trading bertujuan memanfaatkan ayunan harga saham dalam rentang waktu beberapa hari hingga beberapa minggu.\n\nIndikator yang digunakan:\n1. Exponential Moving Average 20 (EMA 20) & EMA 50.\n2. Indikator MACD (Moving Average Convergence Divergence) dengan parameter standar (12, 26, 9).\n\nAturan Entry (Membeli):\nLakukan pembelian (Buy) saat terjadi Golden Cross: EMA 20 memotong ke atas EMA 50, dan garis MACD memotong ke atas garis sinyal di bawah area nol.\n\nAturan Exit (Menjual):\nJual saham Anda ketika harga menembus ke bawah garis EMA 20, atau ketika MACD membentuk Death Cross di area atas."
    }
  ];

  final List<Map<String, dynamic>> _glossary = [
    { 'term': "Bullish", 'def': "Kondisi di mana pasar atau harga saham sedang mengalami tren naik secara konsisten dalam jangka waktu tertentu. Dinamakan 'bull' karena banteng menyerang musuh dengan menanduk ke atas.", 'example': "Saham BBCA sedang bergerak bullish, mencetak rekor harga tertinggi baru hari ini." },
    { 'term': "Bearish", 'def': "Kondisi pasar atau harga saham yang sedang dalam tren turun. Dinamakan 'bear' karena beruang menyerang musuhnya dengan mencakar ke bawah.", 'example': "Rilis laporan keuangan yang buruk memicu sentimen bearish pada saham komoditas itu." },
    { 'term': "Dividen", 'def': "Bagian keuntungan perusahaan yang dibagikan secara tunai kepada para pemegang saham, disetujui melalui Rapat Umum Pemegang Saham (RUPS).", 'example': "Emiten tersebut mengumumkan pembagian dividen final sebesar Rp 150 per lembar saham." },
    { 'term': "IPO (Initial Public Offering)", 'def': "Proses penawaran perdana saham perusahaan tertutup kepada masyarakat luas sehingga resmi terdaftar di bursa efek menjadi perusahaan publik (tbk).", 'example': "Perusahaan start-up teknologi itu bersiap melakukan IPO tahun depan dengan target dana Rp 1 Triliun." },
    { 'term': "Lot", 'def': "Satuan resmi perdagangan saham di bursa efek. Berdasarkan aturan BEI saat ini, 1 lot setara dengan 100 lembar saham.", 'example': "Budi membeli 5 lot saham TLKM pada harga Rp 4.000 per lembar, menghabiskan dana Rp 2.000.000." },
    { 'term': "Blue Chip", 'def': "Istilah untuk saham lapis satu yang memiliki kapitalisasi pasar sangat besar, likuiditas tinggi, bisnis stabil, dan pemimpin di sektornya.", 'example': "Saham perbankan BUMN termasuk kategori saham blue chip favorit para manajer investasi." },
    { 'term': "IHSG", 'def': "Indeks Harga Saham Gabungan. Angka rata-rata yang mencerminkan pergerakan seluruh saham yang tercatat di Bursa Efek Indonesia secara keseluruhan.", 'example': "IHSG hari ini ditutup menguat 0.5% ke level 7.200 didorong oleh pembelian investor asing." },
    { 'term': "Capital Gain", 'def': "Keuntungan bersih yang didapatkan oleh investor dari selisih harga jual saham yang lebih tinggi dibandingkan dengan harga belinya.", 'example': "Ia meraup capital gain sebesar 25% setelah menyimpan saham tersebut selama enam bulan." }
  ];

  int? _expandedGlossaryIdx;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _downloadPdf(Map<String, dynamic> tip) async {
    final title = tip['title'] as String;
    final content = tip['content'] as String;

    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xff0f172a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xff10b981), width: 1.2)),
          title: const Text("Simulasi Download PDF", style: TextStyle(fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            "Mengunduh file: ${title.toLowerCase().replaceAll(' ', '_')}.pdf\n\nIsi file:\n$content",
            style: const TextStyle(color: Color(0xffcbd5e1), fontSize: 12, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK, UNDERSTOOD", style: TextStyle(fontFamily: 'Outfit', color: Color(0xff10b981), fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    } else {
      try {
        final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/${title.toLowerCase().replaceAll(' ', '_')}.pdf');
        await file.writeAsString(content);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Simulasi file PDF berhasil diunduh ke: ${file.path}")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengunduh file: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      body: Stack(
        children: [
          // Background Image matching main app theme
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xff064e3b).withOpacity(0.92),
                    const Color(0xff0f172a).withOpacity(0.96),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 3D Header Tab Bar
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  decoration: BoxDecoration(
                    color: const Color(0xff1e293b).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: const Color(0xff10b981),
                    indicatorWeight: 3.5,
                    labelColor: const Color(0xff10b981),
                    unselectedLabelColor: const Color(0xff94a3b8),
                    labelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.w900),
                    unselectedLabelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(icon: Icon(Icons.menu_book_rounded, size: 16), text: "Modul Belajar"),
                      Tab(icon: Icon(Icons.star_rounded, size: 16), text: "Favorit Anda"),
                      Tab(icon: Icon(Icons.lightbulb_rounded, size: 16), text: "Tips Trading"),
                      Tab(icon: Icon(Icons.spellcheck_rounded, size: 16), text: "Kamus Istilah"),
                    ],
                  ),
                ),

                // Tab Views Body
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildModulesTab(appState),
                      _buildFavoritesTab(appState),
                      _buildTipsTab(appState),
                      _buildGlossaryTab(appState),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. MODUL BELAJAR TAB (3D Cards)
  Widget _buildModulesTab(AppState appState) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: _modules.length,
      itemBuilder: (context, idx) {
        final mod = _modules[idx];
        final isRead = appState.readModules.contains(mod['id']);
        final isLocked = mod['isPremium'] && !appState.isPremium;

        String badgeText = mod['category'];
        Color badgeColor = const Color(0xff1e293b);
        Color badgeTextColor = const Color(0xff60a5fa);
        Color badgeBorder = const Color(0xff3b82f6).withOpacity(0.5);

        if (isRead) {
          badgeText = "SELESAI DIBACA";
          badgeColor = const Color(0xff064e3b);
          badgeTextColor = const Color(0xff34d399);
          badgeBorder = const Color(0xff10b981);
        } else if (isLocked) {
          badgeText = "PREMIUM EXCLUSIVE";
          badgeColor = const Color(0xff78350f);
          badgeTextColor = const Color(0xfff59e0b);
          badgeBorder = const Color(0xfff59e0b);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: Stack(
            children: [
              // 3D Bottom Extrusion Shadow
              Positioned.fill(
                top: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xff022c22),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              // Main Card Face
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xff0f172a).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isRead
                        ? const Color(0xff10b981).withOpacity(0.6)
                        : isLocked
                            ? const Color(0xfff59e0b).withOpacity(0.6)
                            : Colors.white.withOpacity(0.12),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category Badge Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: badgeBorder, width: 1.0),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: badgeTextColor,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        // XP Reward Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xff78350f).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xfff59e0b).withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "+${mod['xp']} XP",
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xfff59e0b),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Title
                    Text(
                      mod['title'],
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Description
                    Text(
                      mod['desc'],
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: Color(0xffcbd5e1),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    const SizedBox(height: 10),
                    // 3D Read Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          if (isLocked) {
                            AudioService.playClick();
                            _showPremiumLockedDialog();
                            return;
                          }
                          AudioService.playConfirm();
                          _openModuleContent(appState, mod);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isLocked
                                ? const LinearGradient(colors: [Color(0xffea580c), Color(0xffc2410c)])
                                : const LinearGradient(colors: [Color(0xff059669), Color(0xff10b981)]),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: isLocked
                                    ? const Color(0xffea580c).withOpacity(0.4)
                                    : const Color(0xff10b981).withOpacity(0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isLocked ? "TERKUNCI" : "BACA SEKARANG →",
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.6,
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
            ],
          ),
        );
      },
    );
  }

  // 3D Module Reading Content Modal
  void _openModuleContent(AppState appState, Map<String, dynamic> mod) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: mod['title'],
      barrierColor: Colors.black.withOpacity(0.85),
      pageBuilder: (ctx, anim1, anim2) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xff0f172a),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xff10b981), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff10b981).withOpacity(0.3),
                blurRadius: 20,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        mod['title'],
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: const Icon(Icons.close_rounded, color: Color(0xff94a3b8)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.white.withOpacity(0.12)),
                const SizedBox(height: 10),
                // Key Takeaways Summary Box
                if (mod['takeaways'] != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xff064e3b).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xff10b981).withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: Color(0xfffbbf24), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              "RINGKASAN INTISARI (${mod['readTimeStr'] ?? ''})",
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xff6ee7b7),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...(mod['takeaways'] as List<String>).map(
                          (point) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("• ", style: TextStyle(color: Color(0xff34d399), fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    point,
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      (mod['content'] as String)
                          .replaceAll("<h1>", "")
                          .replaceAll("</h1>", "\n\n")
                          .replaceAll("<h2>", "\n📌 ")
                          .replaceAll("</h2>", "\n")
                          .replaceAll("<p>", "")
                          .replaceAll("</p>", "\n\n")
                          .replaceAll("<b>", "")
                          .replaceAll("</b>", "")
                          .replaceAll("<br>", "\n"),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        color: Color(0xffcbd5e1),
                        height: 1.55,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff10b981),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    AudioService.playReward();
                    Navigator.of(ctx).pop();
                    appState.completeModule(mod['id'], mod['xp'], context);
                    AdOverlay.show(context, () {});
                  },
                  child: Text(
                    "SELESAI MEMBACA (+${mod['xp']} XP)",
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 2. FAVORIT TAB (3D Cards)
  Widget _buildFavoritesTab(AppState appState) {
    if (appState.favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_border_rounded, size: 64, color: Color(0xff475569)),
            const SizedBox(height: 16),
            const Text(
              "Belum ada soal kuis favorit tersimpan.",
              style: TextStyle(fontFamily: 'Outfit', color: Color(0xffcbd5e1), fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: appState.favorites.length,
      itemBuilder: (context, idx) {
        final fav = appState.favorites[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xff0f172a).withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xfff59e0b).withOpacity(0.5), width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  fav['questionText'],
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13.5, color: Colors.white, height: 1.4),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  AudioService.playClick();
                  appState.toggleFavorite(fav['levelId'], fav['qIndex'], fav['questionText']);
                },
                child: const Icon(Icons.star_rounded, color: Color(0xfff59e0b), size: 24),
              ),
            ],
          ),
        );
      },
    );
  }

  // 3. TIPS TRADING TAB (3D Cards)
  Widget _buildTipsTab(AppState appState) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: _tradingTips.length,
      itemBuilder: (context, idx) {
        final tip = _tradingTips[idx];
        final isLocked = tip['isPremium'] && !appState.isPremium;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xff0f172a).withOpacity(0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Banner
              Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  gradient: LinearGradient(
                    colors: tip['isPdf']
                        ? [const Color(0xffdc2626), const Color(0xffef4444)]
                        : [const Color(0xff059669), const Color(0xff10b981)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  tip['isPdf'] ? "📄 DOKUMEN PDF" : "💡 TIPS TRADING",
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip['title'],
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tip['desc'],
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, color: Color(0xffcbd5e1), height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xff1e293b),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tip['tag'],
                            style: const TextStyle(fontFamily: 'Outfit', fontSize: 10, color: Color(0xff60a5fa), fontWeight: FontWeight.bold),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLocked ? const Color(0xffea580c) : const Color(0xff10b981),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            if (isLocked) {
                              AudioService.playClick();
                              _showPremiumLockedDialog();
                              return;
                            }
                            AudioService.playConfirm();
                            if (tip['isPdf']) {
                              _downloadPdf(tip);
                            } else {
                              _openTipsContent(tip);
                            }
                          },
                          icon: Icon(isLocked ? Icons.lock_rounded : (tip['isPdf'] ? Icons.download_rounded : Icons.read_more_rounded), size: 14, color: Colors.white),
                          label: Text(
                            isLocked ? "BUKA KUNCI" : (tip['isPdf'] ? "UNDUH PDF" : "BACA TIPS"),
                            style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openTipsContent(Map<String, dynamic> tip) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff0f172a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xff10b981), width: 1.2)),
        title: Text(tip['title'], style: const TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            tip['content'],
            style: const TextStyle(color: Color(0xffcbd5e1), fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("TUTUP", style: TextStyle(fontFamily: 'Outfit', color: Color(0xff10b981), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // 4. KAMUS ISTILAH TAB (3D Search & Interactive Cards)
  Widget _buildGlossaryTab(AppState appState) {
    final filteredGlossary = _glossary.where((item) {
      final termMatch = item['term'].toLowerCase().contains(_searchQuery.toLowerCase());
      final defMatch = item['def'].toLowerCase().contains(_searchQuery.toLowerCase());
      return termMatch || defMatch;
    }).toList();

    return Column(
      children: [
        // 3D Glass Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: "Cari istilah pasar modal...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xff10b981)),
              filled: true,
              fillColor: const Color(0xff1e293b).withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xff10b981), width: 1.8),
              ),
            ),
            onChanged: (text) {
              setState(() {
                _searchQuery = text;
              });
            },
          ),
        ),

        // Glossary List
        Expanded(
          child: filteredGlossary.isEmpty
              ? const Center(child: Text("Istilah tidak ditemukan.", style: TextStyle(fontFamily: 'Outfit', color: Color(0xffcbd5e1))))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredGlossary.length,
                  itemBuilder: (context, idx) {
                    final item = filteredGlossary[idx];
                    final isExpanded = _expandedGlossaryIdx == idx;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xff0f172a).withOpacity(0.92),
                        border: Border.all(
                          color: isExpanded ? const Color(0xff10b981) : Colors.white.withOpacity(0.12),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: isExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _expandedGlossaryIdx = expanded ? idx : null;
                            });
                          },
                          title: Text(
                            item['term'],
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.volume_up_rounded, color: Color(0xff10b981), size: 20),
                                onPressed: () {
                                  AudioService.playClick();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Mengucapkan: '${item['term']}' (dalam lafal bahasa Inggris)"),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                color: const Color(0xff94a3b8),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['def'],
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xffcbd5e1), height: 1.5),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xff1e293b),
                                      border: const Border(
                                        left: BorderSide(color: Color(0xff10b981), width: 3),
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "Contoh Penggunaan:\n\"${item['example']}\"",
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Color(0xffcbd5e1),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showPremiumLockedDialog() {
    VipPassModal.show(context);
  }
}
