import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../state/app_state.dart';
import '../widgets/quiz_overlay.dart';
import '../widgets/daily_reward_modal.dart';
import '../widgets/leaderboard_modal.dart';
import '../widgets/ad_overlay.dart';

class KuisView extends StatefulWidget {
  const KuisView({Key? key}) : super(key: key);

  @override
  State<KuisView> createState() => _KuisViewState();
}

class _KuisViewState extends State<KuisView> with TickerProviderStateMixin {
  int? _selectedLevelId;
  int? _pressedLevelId;
  late ScrollController _scrollController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Question database for reference
  final List<Map<String, dynamic>> _levelData = [
    {
      'id': 1,
      'title': "Pengenalan Saham",
      'desc': "Pahami konsep dasar kepemilikan modal & inflasi.",
      'zone': 1,
      'xFactor': 0.5,
      'y': 1580.0,
      'icon': Icons.book_outlined,
      'questions': [
        {
          'type': 'pilgan',
          'q': "Apa pengertian dasar dari saham?",
          'options': [
            "Surat utang yang diterbitkan oleh pemerintah",
            "Bukti kepemilikan modal atas suatu perusahaan",
            "Mata uang kripto hasil penambangan digital",
            "Sertifikat deposito bank komersial"
          ],
          'a': 1,
          'explanation': "Saham adalah surat berharga yang menunjukkan bagian kepemilikan atas suatu perusahaan."
        },
        {
          'type': 'esai',
          'q': "Tuliskan nama instrumen bukti kepemilikan sebagian aset perusahaan (dimulai dengan huruf S):",
          'a': "saham",
          'explanation': "Saham merupakan bukti kepemilikan modal di suatu perseroan terbatas."
        },
        {
          'type': 'pilgan',
          'q': "Jika Anda membeli saham PT Telkom Indonesia, Anda berstatus sebagai...",
          'options': [
            "Karyawan tetap Telkom",
            "Kreditor pemberi pinjaman",
            "Salah satu pemilik Telkom",
            "Direktur utama Telkom"
          ],
          'a': 2,
          'explanation': "Membeli saham berarti memiliki porsi modal perusahaan, sehingga Anda menjadi salah satu pemilik (pemegang saham) perusahaan tersebut."
        }
      ]
    },
    {
      'id': 2,
      'title': "Bursa Efek",
      'desc': "Kenali institusi tempat perdagangan efek berlangsung.",
      'zone': 1,
      'xFactor': 0.28,
      'y': 1440.0,
      'icon': Icons.business,
      'questions': [
        {
          'type': 'esai',
          'q': "Apa singkatan resmi dari Bursa Efek Indonesia?",
          'a': "bei",
          'explanation': "Bursa Efek Indonesia biasa disingkat BEI (atau IDX dalam bahasa Inggris)."
        },
        {
          'type': 'pilgan',
          'q': "Tempat bertemunya para penjual dan pembeli saham/efek secara resmi dinamakan...",
          'options': [
            "Bank Indonesia",
            "Pasar Tradisional",
            "Bursa Efek",
            "Koperasi Unit Desa"
          ],
          'a': 2,
          'explanation': "Bursa Efek adalah lembaga resmi penyedia sistem perdagangan efek."
        },
        {
          'type': 'esai',
          'q': "Singkatan dari indeks rata-rata pergerakan harga seluruh saham di BEI adalah...",
          'a': "ihsg",
          'explanation': "IHSG singkatan dari Indeks Harga Saham Gabungan."
        }
      ]
    },
    {
      'id': 3,
      'title': "Dividen & Capital Gain",
      'desc': "Pelajari 2 sumber keuntungan utama investasi saham.",
      'zone': 1,
      'xFactor': 0.72,
      'y': 1300.0,
      'icon': Icons.attach_money,
      'questions': [
        {
          'type': 'pilgan',
          'q': "Keuntungan yang didapat dari selisih kenaikan harga jual saham dibanding harga beli disebut...",
          'options': [
            "Dividen",
            "Capital Gain",
            "Capital Loss",
            "Kupon Obligasi"
          ],
          'a': 1,
          'explanation': "Capital Gain terjadi saat harga saham yang Anda beli mengalami kenaikan saat dijual."
        },
        {
          'type': 'esai',
          'q': "Bagian laba bersih perusahaan yang dibagikan kepada pemegang saham dinamakan...",
          'a': "dividen",
          'explanation': "Dividen dibayarkan perusahaan secara berkala berdasarkan keputusan RUPS."
        },
        {
          'type': 'pilgan',
          'q': "Kerugian yang timbul ketika Anda menjual saham di bawah harga pembeliaan awal disebut...",
          'options': [
            "Capital Gain",
            "Capital Loss",
            "Dividen Yield",
            "Cashback"
          ],
          'a': 1,
          'explanation': "Capital Loss adalah kerugian modal ketika harga penutupan/jual lebih rendah dari modal beli."
        }
      ]
    },
    {
      'id': 4,
      'title': "Candlestick Dasar",
      'desc': "Belajar memahami pergerakan harga melalui grafik lilin.",
      'zone': 2,
      'xFactor': 0.28,
      'y': 1060.0,
      'icon': Icons.candlestick_chart,
      'questions': [
        {
          'type': 'pilgan',
          'q': "Secara umum pada grafik saham, lilin berwarna hijau menandakan bahwa harga...",
          'options': [
            "Ditutup lebih rendah dari harga buka (Turun)",
            "Ditutup lebih tinggi dari harga buka (Naik)",
            "Sama sekali tidak bergerak",
            "Mengalami transaksi bodong"
          ],
          'a': 1,
          'explanation': "Lilin hijau (Bullish) menunjukkan penutupan harga lebih tinggi dari harga pembukaan."
        },
        {
          'type': 'esai',
          'q': "Titik teratas pada sumbu (shadow) grafik candlestick menggambarkan harga...",
          'a': "tertinggi",
          'explanation': "Ujung atas ekor candlestick adalah harga tertinggi (High) pada periode tersebut."
        },
        {
          'type': 'pilgan',
          'q': "Lilin berwarna merah pada candlestick chart mengindikasikan dominan tekanan...",
          'options': [
            "Pembelian (Beli)",
            "Penjualan (Jual)",
            "Stagnan",
            "Pembagian Dividen"
          ],
          'a': 1,
          'explanation': "Lilin merah (Bearish) menandakan harga saham tertekan turun oleh dorongan aksi jual."
        }
      ]
    },
    {
      'id': 5,
      'title': "Support & Resistance",
      'desc': "Tentukan batas lantai dan atap pergerakan harga saham.",
      'zone': 2,
      'xFactor': 0.72,
      'y': 920.0,
      'icon': Icons.horizontal_rule,
      'questions': [
        {
          'type': 'esai',
          'q': "Area batas bawah psikologis di mana harga saham cenderung menahan penurunan disebut...",
          'a': "support",
          'explanation': "Support adalah tingkat harga di mana pembeli diprakirakan cukup kuat untuk menahan harga turun."
        },
        {
          'type': 'pilgan',
          'q': "Apa arti dari batas Resistance dalam grafik teknikal saham?",
          'options': [
            "Langsung naik drastis tanpa hambatan",
            "Tertahan naik dan berpotensi berbalik turun",
            "Volume perdagangan langsung habis",
            "Perusahaan melakukan stock split"
          ],
          'a': 1,
          'explanation': "Resistance bertindak sebagai 'atap' psikologis di mana pasokan jual bertambah dan menahan kenaikan harga."
        },
        {
          'type': 'pilgan',
          'q': "Apa yang terjadi jika suatu level Resistance berhasil ditembus ke atas (Breakout)?",
          'options': [
            "Level tersebut hilang selamanya",
            "Level tersebut berpotensi berubah menjadi Support baru",
            "Harga saham langsung disuspensi",
            "Investor wajib menjual semua sahamnya"
          ],
          'a': 1,
          'explanation': "Dalam analisis teknikal, Resistance yang tertembus ke atas cenderung berbalik fungsi menjadi Support baru (Principle of Role Reversal)."
        }
      ]
    },
    {
      'id': 6,
      'title': "Trendlines",
      'desc': "Membaca arah tren pasar saham.",
      'zone': 2,
      'xFactor': 0.28,
      'y': 780.0,
      'icon': Icons.trending_up,
      'questions': [
        {
          'type': 'esai',
          'q': "Tren pergerakan harga saham yang terus mencetak puncak dan lembah lebih tinggi disebut...",
          'a': "uptrend",
          'explanation': "Uptrend dicirikan dengan formasi Higher High (HH) dan Higher Low (HL)."
        },
        {
          'type': 'pilgan',
          'q': "Keadaan pasar di mana harga bergerak mendatar dalam range tertentu disebut...",
          'options': [
            "Uptrend",
            "Downtrend",
            "Sideways",
            "Bullrun"
          ],
          'a': 2,
          'explanation': "Sideways (atau konsolidasi) adalah fase pasar tanpa tren naik atau turun yang dominan."
        },
        {
          'type': 'pilgan',
          'q': "Untuk menggambar garis Downtrend yang valid, kita harus menghubungkan...",
          'options': [
            "Titik-titik lembah terendah (swing lows)",
            "Titik-titik puncak tertinggi (swing highs) yang semakin menurun",
            "Harga pembukaan di pagi hari saja",
            "Harga penutupan di akhir tahun saja"
          ],
          'a': 1,
          'explanation': "Downtrend line digambar dengan menghubungkan minimal dua titik puncak harga (lower highs) untuk membatasi pergerakan naik."
        }
      ]
    },
    {
      'id': 7,
      'title': "Indikator Dasar",
      'desc': "Menggunakan alat bantu visual matematis untuk trading.",
      'zone': 2,
      'xFactor': 0.72,
      'y': 640.0,
      'icon': Icons.settings,
      'questions': [
        {
          'type': 'esai',
          'q': "Indikator rata-rata pergerakan harga historis saham disingkat MA, kepanjangannya adalah...",
          'a': "moving average",
          'explanation': "Moving Average (Rerata Bergerak) meratakan fluktuasi harga untuk membantu melihat tren utama."
        },
        {
          'type': 'pilgan',
          'q': "Fungsi utama dari indikator osilator RSI adalah mengukur...",
          'options': [
            "Likuiditas bandar saham",
            "Kondisi jenuh beli (overbought) dan jenuh jual (oversold)",
            "Pendapatan tahunan perusahaan terbaru",
            "Ketebalan antrean bid dan offer"
          ],
          'a': 1,
          'explanation': "Relative Strength Index (RSI) mengukur momentum kekuatan harga pada rentang skala 0 hingga 100."
        },
        {
          'type': 'pilgan',
          'q': "Angka standar indikator RSI yang menandakan saham masuk area jenuh beli (Overbought) adalah...",
          'options': [
            "Di bawah 30",
            "Di atas 50",
            "Di atas 70",
            "Tepat di angka 0"
          ],
          'a': 2,
          'explanation': "Umumnya, nilai RSI di atas 70 menunjukkan overbought (potensi jenuh beli/turun), sedangkan di bawah 30 menunjukkan oversold (potensi jenuh jual/naik)."
        }
      ]
    },
    {
      'id': 8,
      'title': "Money Management",
      'desc': "Lindungi modal trading Anda dari kebangkrutan.",
      'zone': 3,
      'xFactor': 0.28,
      'y': 400.0,
      'icon': Icons.security,
      'questions': [
        {
          'type': 'pilgan',
          'q': "Berapa persen batasan risiko maksimal dari total modal per transaksi yang disarankan bagi trader?",
          'options': [
            "10% - 20%",
            "50%",
            "1% - 2%",
            "Tidak ada batasan risiko"
          ],
          'a': 2,
          'explanation': "Aturan 1-2% memastikan modal trader tidak habis meskipun mengalami kerugian berturut-turut."
        },
        {
          'type': 'esai',
          'q': "Perbandingan antara risiko kerugian dan potensi keuntungan transaksi disebut Risk to... Ratio:",
          'a': "reward",
          'explanation': "Risk to Reward Ratio membantu mengukur apakah suatu trading layak diambil dibanding risikonya."
        },
        {
          'type': 'pilgan',
          'q': "Jika Anda memiliki modal Rp 10.000.000 dan menerapkan batasan risiko 2%, batas kerugian maksimal per trading adalah...",
          'options': [
            "Rp 2.000.000",
            "Rp 200.000",
            "Rp 500.000",
            "Rp 20.000"
          ],
          'a': 1,
          'explanation': "Rp 10.000.000 x 2% = Rp 200.000."
        }
      ]
    },
    {
      'id': 9,
      'title': "Psikologi Trading",
      'desc': "Kuasai emosi FOMO dan serakah saat trading.",
      'zone': 3,
      'xFactor': 0.72,
      'y': 260.0,
      'icon': Icons.psychology,
      'questions': [
        {
          'type': 'esai',
          'q': "Sindrom takut tertinggal peluang cuan di saham sehingga beli terburu-buru di harga pucuk disebut...",
          'a': "fomo",
          'explanation': "FOMO singkatan dari Fear Of Missing Out."
        },
        {
          'type': 'pilgan',
          'q': "Apa pemicu utama trader pemula enggan melakukan Cut Loss ketika saham terus merosot?",
          'options': [
            "Terlalu disiplin mengikuti rencana awal",
            "Rasa enggan mengakui kerugian (loss aversion) & harapan semu",
            "Ketentuan komisi broker yang terlalu murah",
            "Saran dari Bursa Efek Indonesia"
          ],
          'a': 1,
          'explanation': "Loss aversion menyebabkan trader menolak kenyataan bahwa mereka salah dan terus memegang saham turun dengan harapan berbalik arah."
        },
        {
          'type': 'pilgan',
          'q': "Apa istilah trading impulsif dengan modal besar demi membalas kerugian sebelumnya?",
          'options': [
            "Swing Trading",
            "Revenge Trading",
            "Scalping",
            "Value Investing"
          ],
          'a': 1,
          'explanation': "Revenge trading (trading balas dendam) dipicu emosi kemarahan dan seringkali merusak perencanaan trading secara rasional."
        }
      ]
    },
    {
      'id': 10,
      'title': "Cut Loss vs TP",
      'desc': "Ketahui kapan harus mengunci profit dan memotong kerugian.",
      'zone': 3,
      'xFactor': 0.28,
      'y': 120.0,
      'icon': Icons.swap_vert,
      'questions': [
        {
          'type': 'esai',
          'q': "Menjual saham yang merugi demi melindungi sisa modal dari penurunan lebih dalam disebut Cut...",
          'a': "loss",
          'explanation': "Cut Loss adalah tindakan wajib untuk membatasi risiko kerugian secara disiplin."
        },
        {
          'type': 'esai',
          'q': "Mengamankan keuntungan trading dengan menjual saham sesuai target awal dinamakan Take...",
          'a': "profit",
          'explanation': "Take Profit mengunci keuntungan agar tidak berbalik menjadi kerugian."
        },
        {
          'type': 'pilgan',
          'q': "Apa nama fitur perdagangan otomatis yang membantu menutup posisi rugi secara instan?",
          'options': [
            "Limit Order",
            "Stop Loss / Trailing Stop",
            "Market Maker",
            "Dividen Payout"
          ],
          'a': 1,
          'explanation': "Stop Loss otomatis memicu order jual ketika harga menyentuh batas bawah pengaman yang ditentukan."
        }
      ]
    }
  ];

  late AnimationController _bobController;
  late Animation<double> _bobAnimation;
  late AnimationController _chestWiggleController;
  late Animation<double> _chestWiggleAnimation;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    int activeLevelId = appState.completedLevels.length + 1;
    if (activeLevelId > 10) activeLevelId = 10;
    final activeNode = _levelData.firstWhere(
      (l) => l['id'] == activeLevelId,
      orElse: () => _levelData.first,
    );
    final double activeY = (activeNode['y'] as double);
    final double initialOffset = (activeY - 180.0).clamp(0.0, 1825.0);

    _scrollController = ScrollController(initialScrollOffset: initialOffset);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final double targetScroll = (activeY - 180.0).clamp(0.0, _scrollController.position.maxScrollExtent);
        if ((_scrollController.offset - targetScroll).abs() > 1.0) {
          _scrollController.jumpTo(targetScroll);
        }
      }
    });
    
    _bobController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _bobAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(
        parent: _bobController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.18).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _chestWiggleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _chestWiggleAnimation = Tween<double>(begin: -0.07, end: 0.07).animate(
      CurvedAnimation(
        parent: _chestWiggleController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _chestWiggleController.dispose();
    _pulseController.dispose();
    _bobController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final double mapWidth = screenWidth.clamp(280.0, 480.0);

    int activeLevelId = appState.completedLevels.length + 1;
    if (activeLevelId > 10) activeLevelId = 10;
    final activeLevel = _levelData.firstWhere((l) => l['id'] == activeLevelId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Static fixed background image covering the entire screen
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              // Safe top padding to clear floating transparent AppBar (flush)
              SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight - 42),
              
              // Pinned Unit Banner (Duolingo/Babbel Premium Header Card)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff059669), Color(0xff0f766e)], // Emerald to Dark Teal
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff059669).withOpacity(0.35),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row: Level Tag (Left) & Absen Harian Button (Right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Level Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.18)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bookmark_rounded, color: Color(0xff6ee7b7), size: 13),
                              const SizedBox(width: 5),
                              Text(
                                appState.completedLevels.length >= 10
                                    ? "BAGIAN 1 • SEMUA LEVEL SELESAI"
                                    : "BAGIAN 1 • LEVEL $activeLevelId / 10",
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xff6ee7b7),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right: Interactive 3D Absen Harian Button
                        GestureDetector(
                          onTap: () => DailyRewardModal.show(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: appState.canClaimDailyToday ? const Color(0xfff59e0b) : Colors.black.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: appState.canClaimDailyToday ? const Color(0xfffbbf24) : Colors.white.withOpacity(0.18),
                                width: 1.2,
                              ),
                              boxShadow: appState.canClaimDailyToday
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xfff59e0b).withOpacity(0.55),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 13),
                                const SizedBox(width: 5),
                                Text(
                                  appState.canClaimDailyToday ? "Absen Harian" : "Hadiah Harian",
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                if (appState.canClaimDailyToday) ...[
                                  const SizedBox(width: 5),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Active Level Title & Desc
                    Text(
                      activeLevel['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFamily: 'Outfit',
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeLevel['desc'],
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Progress Bar & Percentage of Active Level Questions
                    Builder(
                      builder: (context) {
                        final activeQList = (activeLevel['questions'] as List?) ?? [];
                        final activeQCount = activeQList.length > 0 ? activeQList.length : 3;
                        final activeCorrect = appState.getCorrectAnswersForLevel(activeLevelId);
                        final double activeProgress = (activeCorrect / activeQCount).clamp(0.0, 1.0);
                        final int activePct = (activeProgress * 100).round();

                        return Row(
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: activeProgress,
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xffa7f3d0), Colors.white],
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(0.5),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "$activePct%",
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    // Quick Action Button: "Lanjutkan Belajar"
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xff065f46),
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {
                          AudioService.playClick();
                          // Smoothly scroll and center back to the active level if scrolled away
                          if (_scrollController.hasClients) {
                            final double activeY = (activeLevel['y'] as double);
                            final double targetScroll = (activeY - 180.0).clamp(0.0, _scrollController.position.maxScrollExtent);
                            _scrollController.animateTo(
                              targetScroll,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                            );
                          }
                          setState(() {
                            _selectedLevelId = activeLevelId;
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              appState.completedLevels.length >= 10 ? Icons.replay_rounded : Icons.play_arrow_rounded,
                              size: 20,
                              color: const Color(0xff047857),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              appState.completedLevels.length >= 10 ? "REVIEW LEVEL 10" : "LANJUTKAN BELAJAR",
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xff047857),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Map
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 115),
                  child: Center(
                      child: Container(
                        width: mapWidth,
                        height: 1825, // Generous Height with Guaranteed 0 Overlap
                        color: Colors.transparent,
                        child: Stack(
                          children: [
                            // 1. Connection lines & Background stars/grid painter (optimized with RepaintBoundary)
                            Positioned.fill(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: RoadmapLinePainter(
                                    levelData: _levelData,
                                    completedLevels: appState.completedLevels,
                                    mapWidth: mapWidth,
                                  ),
                                ),
                              ),
                            ),

                            // 2. Full-Width 3D Rectangular Zone Banners
                            _buildZoneHeader(
                              zoneTag: "Zona 1",
                              title: "Pengenalan & Dasar Saham",
                              levelRange: "Level 1 - 3",
                              activeColor: const Color(0xff059669), // Duolingo Emerald Green
                              activeShadowColor: const Color(0xff047857),
                              isUnlocked: true, // Zone 1 is always unlocked
                              top: 1735,
                            ),

                            _buildZoneHeader(
                              zoneTag: "Zona 2",
                              title: "Analisis Teknikal & Grafik",
                              levelRange: "Level 4 - 7",
                              activeColor: const Color(0xff2563eb), // Sapphire Blue
                              activeShadowColor: const Color(0xff1d4ed8),
                              isUnlocked: appState.completedLevels.contains(3), // Unlocked after level 3
                              top: 1210,
                            ),

                            _buildZoneHeader(
                              zoneTag: "Zona 3",
                              title: "Master Pasar & Manajemen Risiko",
                              levelRange: "Level 8 - 10",
                              activeColor: const Color(0xffd97706), // Golden Amber
                              activeShadowColor: const Color(0xffb45309),
                              isUnlocked: appState.completedLevels.contains(7), // Unlocked after level 7
                              top: 550,
                            ),

                            // 3. Node Circles (Duolingo 3D Button style)
                            ..._levelData.map((level) {
                              final id = level['id'] as int;
                              final isCompleted = appState.completedLevels.contains(id);
                              final isUnlocked = id == 1 || appState.completedLevels.contains(id - 1);
                              
                              final x = (level['xFactor'] as double) * mapWidth;
                              final y = level['y'] as double;
                              
                              final isActive = id == activeLevelId;

                              Color nodeColor;
                              Color shadowColor;
                              Color iconColor;
                              Border nodeBorder;

                              if (isActive) {
                                nodeColor = const Color(0xff58cc02); // Duolingo Emerald Green
                                shadowColor = const Color(0xff46a302);
                                iconColor = Colors.white;
                                nodeBorder = Border.all(color: Colors.white.withOpacity(0.5), width: 2.5);
                              } else if (isCompleted) {
                                nodeColor = const Color(0xff10b981); // Emerald Teal
                                shadowColor = const Color(0xff047857);
                                iconColor = Colors.white;
                                nodeBorder = Border.all(color: const Color(0xfff59e0b), width: 2.5); // Gold Rim
                              } else {
                                // Locked / Future Levels (Classic Duolingo 3D Slate Gray with Lock Icon)
                                nodeColor = const Color(0xff475569); // Slate Gray
                                shadowColor = const Color(0xff334155); // Dark Base
                                iconColor = const Color(0xffcbd5e1); // Silver Lock
                                nodeBorder = Border.all(color: Colors.white.withOpacity(0.12), width: 1.8);
                              }

                              final isPressed = _pressedLevelId == id;

                              // 3D Cartoon Circle Widget
                              Widget nodeWidget = SizedBox(
                                width: 78,
                                height: 84,
                                child: Stack(
                                  children: [
                                    // Bottom 3D shadow basing
                                    Positioned(
                                      top: 7,
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: shadowColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    // Top main button circle
                                    Positioned(
                                      top: isPressed ? 7 : 0,
                                      left: 0,
                                      right: 0,
                                      bottom: isPressed ? 0 : 7,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: nodeColor,
                                          shape: BoxShape.circle,
                                          border: nodeBorder,
                                        ),
                                        alignment: Alignment.center,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Inner coin ring
                                            Container(
                                              margin: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white.withOpacity(isUnlocked ? 0.25 : 0.08),
                                                  width: 1.8,
                                                ),
                                              ),
                                            ),
                                            // Stylized material icon
                                            Icon(
                                              (isActive || isCompleted) ? _getLevelIcon(id) : Icons.lock_rounded,
                                              color: iconColor,
                                              size: (isActive || isCompleted) ? 30 : 24,
                                            ),
                                            // Glossy highlight for unlocked/active nodes
                                            if ((isActive || isCompleted) && !isPressed)
                                              Positioned(
                                                top: 4,
                                                left: 14,
                                                right: 14,
                                                height: 12,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.35),
                                                    borderRadius: const BorderRadius.all(
                                                      Radius.elliptical(20, 6),
                                                    ),
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

                              // Ring indicator around node showing question completion progress (Duolingo Style)
                              final qCount = ((level['questions'] as List?)?.length ?? 3).clamp(1, 100);
                              final correctCount = appState.getCorrectAnswersForLevel(id);
                              final double levelProgress = (correctCount / qCount).clamp(0.0, 1.0);

                              if (isActive || (isUnlocked && levelProgress > 0 && levelProgress < 1.0)) {
                                nodeWidget = AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    final scale = isActive ? _pulseAnimation.value : 1.0;
                                    return Container(
                                      width: 98,
                                      height: 104,
                                      alignment: Alignment.center,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Outer Glowing Pulsing Aura (Only for active level)
                                          if (isActive)
                                            Transform.scale(
                                              scale: scale,
                                              child: Container(
                                                width: 86,
                                                height: 86,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: const Color(0xff58cc02).withOpacity(0.25),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xff58cc02).withOpacity(0.5),
                                                      blurRadius: 18,
                                                      spreadRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          SizedBox(
                                            width: 90,
                                            height: 90,
                                            child: CircularProgressIndicator(
                                              value: levelProgress,
                                              strokeWidth: 7,
                                              strokeCap: StrokeCap.round,
                                              color: const Color(0xff58cc02),
                                              backgroundColor: Colors.white.withOpacity(0.12),
                                            ),
                                          ),
                                          child!,
                                        ],
                                      ),
                                    );
                                  },
                                  child: nodeWidget,
                                );
                              }

                              return Positioned(
                                left: x - 60,
                                width: 120,
                                top: isActive ? y - 8 : y,
                                child: GestureDetector(
                                  onTapDown: (_) {
                                    if (isUnlocked) {
                                      setState(() {
                                        _pressedLevelId = id;
                                      });
                                    }
                                  },
                                  onTapUp: (_) {
                                    if (isUnlocked) {
                                      AudioService.playClick();
                                      setState(() {
                                        _pressedLevelId = null;
                                        _selectedLevelId = id;
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Level ini masih terkunci! Selesaikan level sebelumnya."),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                  onTapCancel: () {
                                    setState(() {
                                      _pressedLevelId = null;
                                    });
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      nodeWidget,
                                      const SizedBox(height: 5),
                                      // 3D Premium Game Level Title Ribbon
                                      _buildLevelTitleBadge(
                                        level: level,
                                        isActive: isActive,
                                        isCompleted: isCompleted,
                                        isUnlocked: isUnlocked,
                                      ),
                                      // Candy Crush Style Dynamic Stars for completed levels
                                      if (isCompleted)
                                        Builder(
                                          builder: (context) {
                                            final stars = appState.getStarsForLevel(id);
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 3),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xff182232).withOpacity(0.9),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: const Color(0xfff59e0b).withOpacity(0.5), width: 0.8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      stars >= 1 ? Icons.star_rounded : Icons.star_outline_rounded,
                                                      color: stars >= 1 ? const Color(0xfff59e0b) : const Color(0xff475569),
                                                      size: 12,
                                                    ),
                                                    const SizedBox(width: 1),
                                                    Icon(
                                                      stars >= 2 ? Icons.star_rounded : Icons.star_outline_rounded,
                                                      color: stars >= 2 ? const Color(0xfff59e0b) : const Color(0xff475569),
                                                      size: 13,
                                                    ),
                                                    const SizedBox(width: 1),
                                                    Icon(
                                                      stars >= 3 ? Icons.star_rounded : Icons.star_outline_rounded,
                                                      color: stars >= 3 ? const Color(0xfff59e0b) : const Color(0xff475569),
                                                      size: 12,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),

                            // 4. Animated "MULAI" Bubble (Centered directly above active node)
                            Builder(
                              builder: (context) {
                                final x = (activeLevel['xFactor'] as double) * mapWidth;
                                final y = activeLevel['y'] as double;

                                return Positioned(
                                  left: x - 46, // Centered perfectly (width is 92, so center is exactly x)
                                  top: y - 68,  // Positioned directly above active node
                                  child: GestureDetector(
                                    onTap: () {
                                      AudioService.playClick();
                                      setState(() {
                                        _selectedLevelId = activeLevelId;
                                      });
                                    },
                                    child: AnimatedBuilder(
                                      animation: _bobAnimation,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(0, _bobAnimation.value),
                                          child: child,
                                        );
                                      },
                                      child: _buildMulaiBubble(),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // 5. Milestone Treasure Chest Nodes (Zone 1 Level 3 & Zone 2 Level 7)
                            _buildTreasureChestNode(
                              context,
                              appState,
                              levelId: 3,
                              x: mapWidth * 0.76,
                              y: 1460,
                              title: "Bonus Zona 1",
                              xpReward: 50,
                            ),

                            _buildTreasureChestNode(
                              context,
                              appState,
                              levelId: 7,
                              x: mapWidth * 0.78,
                              y: 800,
                              title: "Bonus Zona 2",
                              xpReward: 100,
                            ),

                            // 5. Bonus Trophy/Chest Node at the very top (above Level 10)
                            Positioned(
                              left: (mapWidth * 0.5) - 38,
                              top: 30,
                              child: GestureDetector(
                                onTapDown: (_) {
                                  setState(() {
                                    _pressedLevelId = 99;
                                  });
                                },
                                onTapUp: (_) {
                                  setState(() {
                                    _pressedLevelId = null;
                                  });
                                  final allDone = appState.completedLevels.length == 10;
                                  if (!allDone) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Selesaikan semua 10 Level Kuis terlebih dahulu!")),
                                    );
                                    return;
                                  }
                                  if (appState.unlockedBadges.contains("pakar_saham")) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Anda sudah mengklaim Piala Pakar Saham!")),
                                    );
                                    return;
                                  }
                                  appState.addXp(0, context); // Triggers checkAndUnlockBadges internally
                                },
                                onTapCancel: () {
                                  setState(() {
                                    _pressedLevelId = null;
                                  });
                                },
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: 76,
                                      height: 82,
                                      child: Stack(
                                        children: [
                                          // Bottom 3D shadow (Orange shadow)
                                          Positioned(
                                            top: 6,
                                            left: 0,
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Color(0xffc2410c), // Darker orange
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                          // Top main button circle
                                          Positioned(
                                            top: _pressedLevelId == 99 ? 6 : 0,
                                            left: 0,
                                            right: 0,
                                            bottom: _pressedLevelId == 99 ? 0 : 6,
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Color(0xffea580c), // Golden orange
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.emoji_events_rounded,
                                                    color: Colors.white,
                                                    size: 36,
                                                  ),
                                                  if (_pressedLevelId != 99)
                                                    Positioned(
                                                      top: 4,
                                                      left: 12,
                                                      right: 12,
                                                      height: 14,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.35),
                                                          borderRadius: const BorderRadius.all(
                                                            Radius.elliptical(25, 8),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.8),
                                      ),
                                      child: const Text(
                                        "PIALA FINAL",
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xffea580c),
                                        ),
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
                  ),
                ),
              ],
            ),
          if (_selectedLevelId != null) _buildInFrameModalSheet(appState),
        ],
      ),
    );
  }

  IconData _getLevelIcon(int id) {
    switch (id) {
      case 1:
        return Icons.auto_stories_rounded; // Pengenalan Saham (Book)
      case 2:
        return Icons.account_balance_rounded; // Bursa Efek (Bursa Hall)
      case 3:
        return Icons.analytics_rounded; // Fundamental Awal (Reports)
      case 4:
        return Icons.candlestick_chart_rounded; // Candlestick Dasar (Lilin)
      case 5:
        return Icons.stacked_line_chart_rounded; // Support & Resistance (S&R Lines)
      case 6:
        return Icons.show_chart_rounded; // Trendlines (Trends)
      case 7:
        return Icons.insights_rounded; // Indikator Dasar (Indicators)
      case 8:
        return Icons.shield_rounded; // Money Management (Security Shield)
      case 9:
        return Icons.psychology_rounded; // Psikologi Trading (Brain)
      case 10:
        return Icons.flag_rounded; // Cut Loss vs TP (Finish flag)
      default:
        return Icons.star_rounded;
    }
  }

  IconData _getZoneIcon(String zoneTag) {
    if (zoneTag.contains("ZONA 1")) {
      return Icons.eco_rounded; // Emerald Grassland
    } else if (zoneTag.contains("ZONA 2")) {
      return Icons.show_chart_rounded; // Sapphire Chart Tech
    } else {
      return Icons.military_tech_rounded; // Golden Wall Street Trophy
    }
  }

  // 3D Premium Game Level Title Ribbon
  Widget _buildLevelTitleBadge({
    required Map<String, dynamic> level,
    required bool isActive,
    required bool isCompleted,
    required bool isUnlocked,
  }) {
    final id = level['id'] as int;
    final title = level['title'] as String;

    Color badgeBorderColor;
    Color numBgColor;
    Color numTextColor = Colors.white;

    if (isActive) {
      badgeBorderColor = const Color(0xff58cc02); // Duolingo Emerald Green
      numBgColor = const Color(0xff58cc02);
    } else if (isCompleted) {
      badgeBorderColor = const Color(0xfff59e0b); // Shiny Amber Gold
      numBgColor = const Color(0xff10b981);
    } else {
      badgeBorderColor = Colors.white.withOpacity(0.12);
      numBgColor = const Color(0xff334155);
      numTextColor = const Color(0xff94a3b8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      decoration: BoxDecoration(
        color: isUnlocked
            ? const Color(0xff0f172a).withOpacity(0.92)
            : const Color(0xff0f172a).withOpacity(0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeBorderColor,
          width: isActive ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 6,
            offset: const Offset(0, 3), // 3D shadow depth
          ),
          if (isActive)
            BoxShadow(
              color: const Color(0xff58cc02).withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
      constraints: const BoxConstraints(maxWidth: 115),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Level Number Pill Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: numBgColor,
              borderRadius: BorderRadius.circular(7),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              "$id",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: numTextColor,
              ),
            ),
          ),
          const SizedBox(width: 5),
          // Level Title Text
          Flexible(
            child: Text(
              title,
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10,
                fontWeight: isUnlocked ? FontWeight.w900 : FontWeight.bold,
                color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.55),
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 2),
        ],
      ),
    );
  }

  Widget _buildZoneHeader({
    required String zoneTag,
    required String title,
    required String levelRange,
    required Color activeColor,
    required Color activeShadowColor,
    required bool isUnlocked,
    required double top,
  }) {
    final bgColor = isUnlocked ? activeColor : const Color(0xff334155);
    final shadowColor = isUnlocked ? activeShadowColor : const Color(0xff1e293b);
    final iconData = isUnlocked ? _getZoneIcon(zoneTag) : Icons.lock_rounded;
    final badgeText = isUnlocked ? levelRange : "Terkunci";

    return Positioned(
      left: 0,
      right: 0,
      top: top,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 0,
              offset: const Offset(0, 4), // 3D bottom bar shadow
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isUnlocked ? Colors.white.withOpacity(0.22) : Colors.black.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: isUnlocked ? Colors.white : const Color(0xffcbd5e1),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    zoneTag.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isUnlocked ? Colors.white.withOpacity(0.85) : const Color(0xff94a3b8),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isUnlocked ? Colors.white : const Color(0xffcbd5e1),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isUnlocked ? Colors.black.withOpacity(0.22) : Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUnlocked ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.08),
                ),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: isUnlocked ? Colors.white : const Color(0xff94a3b8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreasureChestNode(
    BuildContext context,
    AppState appState, {
    required int levelId,
    required double x,
    required double y,
    required String title,
    required int xpReward,
  }) {
    final bool isCompleted = appState.completedLevels.contains(levelId);
    final bool isClaimed = appState.isChestClaimed(levelId);

    Color chestBg = const Color(0xff1e293b);
    Color chestBorder = const Color(0xff475569);
    IconData chestIcon = Icons.lock_rounded;
    Color iconColor = const Color(0xff94a3b8);
    String labelText = title;

    if (isCompleted) {
      if (isClaimed) {
        chestBg = const Color(0xff064e3b);
        chestBorder = const Color(0xff10b981);
        chestIcon = Icons.card_giftcard_rounded;
        iconColor = const Color(0xff34d399);
        labelText = "Diklaim";
      } else {
        chestBg = const Color(0xff78350f);
        chestBorder = const Color(0xfff59e0b);
        chestIcon = Icons.card_giftcard_rounded;
        iconColor = const Color(0xfffbbf24);
        labelText = "KLAIM +$xpReward XP";
      }
    }

    final bool isReadyToClaim = isCompleted && !isClaimed;

    return Positioned(
      left: x - 65,
      top: y,
      child: GestureDetector(
        onTap: () {
          _showTreasureChestModal(
            context,
            appState,
            levelId: levelId,
            title: title,
            xpReward: xpReward,
            isCompleted: isCompleted,
            isClaimed: isClaimed,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating Badge Pill (Above Pure Chest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: isReadyToClaim
                    ? const Color(0xff78350f)
                    : (isClaimed ? const Color(0xff064e3b) : const Color(0xff1e293b)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isReadyToClaim
                      ? const Color(0xfff59e0b)
                      : (isClaimed ? const Color(0xff10b981) : const Color(0xff475569)),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isReadyToClaim
                        ? const Color(0xfff59e0b).withOpacity(0.5)
                        : Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                isClaimed ? "Diklaim" : (isCompleted ? "+$xpReward XP" : title),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: isReadyToClaim
                      ? const Color(0xfffbbf24)
                      : (isClaimed ? const Color(0xff34d399) : const Color(0xff94a3b8)),
                  letterSpacing: 0.3,
                ),
              ),
            ),
            // PURE ANIMATED 3D GAME TREASURE CHEST ASSET (Snug Label Alignment - No Gap)
            Transform.translate(
              offset: const Offset(0, -12), // Pulls chest asset up to sit snugly right under the label
              child: SizedBox(
                width: 130,
                height: 115,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      1, 0, 0, 0, 0,
                      0, 1, 0, 0, 0,
                      0, 0, 1, 0, 0,
                      -1, -1, -1, 1, 510,
                    ]),
                    child: Image.asset(
                      'assets/images/chest-gif.gif',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTreasureChestModal(
    BuildContext context,
    AppState appState, {
    required int levelId,
    required String title,
    required int xpReward,
    required bool isCompleted,
    required bool isClaimed,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff0f172a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isCompleted && !isClaimed ? const Color(0xfff59e0b) : const Color(0xff10b981),
            width: 1.8,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // High-Res 3D Chest GIF Preview
            SizedBox(
              width: 110,
              height: 100,
              child: Center(
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    1, 0, 0, 0, 0,
                    0, 1, 0, 0, 0,
                    0, 0, 1, 0, 0,
                    -1, -1, -1, 1, 510,
                  ]),
                  child: Image.asset(
                    'assets/images/chest-gif.gif',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isClaimed
                  ? "Hadiah +$xpReward XP telah diklaim"
                  : isCompleted
                      ? "Bonus +$xpReward XP siap diklaim!"
                      : "Selesaikan Level $levelId untuk membuka",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isClaimed
                    ? const Color(0xff34d399)
                    : (isCompleted ? const Color(0xfffbbf24) : const Color(0xff94a3b8)),
              ),
            ),
            const SizedBox(height: 18),
            if (isCompleted && !isClaimed)
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  appState.claimChest(levelId, xpReward, context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Selamat! Bonus +$xpReward XP telah diklaim!"),
                      backgroundColor: const Color(0xff059669),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xff10b981),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xff047857),
                        offset: Offset(0, 4), // 3D Button Depth
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "KLAIM +$xpReward XP",
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xff1e293b),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "TUTUP",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMulaiBubble() {
    return SizedBox(
      width: 92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 92,
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xff182232),
              border: Border.all(color: const Color(0xff58cc02), width: 2.5),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Text(
              "MULAI",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xff58cc02),
                letterSpacing: 1.0,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -6),
            child: Transform.rotate(
              angle: 0.785398, // 45 degrees
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xff182232),
                  border: Border(
                    right: BorderSide(color: Color(0xff58cc02), width: 2.5),
                    bottom: BorderSide(color: Color(0xff58cc02), width: 2.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildInFrameModalSheet(AppState appState) {
    final level = _levelData.firstWhere((l) => l['id'] == _selectedLevelId);
    final id = level['id'] as int;
    final isCompleted = appState.completedLevels.contains(id);
    final qCount = (level['questions'] as List).length;
    final xpReward = qCount * 10;

    return Positioned.fill(
      child: Stack(
        children: [
          // 1. Dark semi-transparent backdrop barrier
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedLevelId = null;
                });
              },
              child: Container(
                color: Colors.black.withOpacity(0.55),
              ),
            ),
          ),
          // 2. Centered Modal Card
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xff182232),
                    border: Border.all(color: const Color(0xff334155), width: 1.5),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 35,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xff58cc02).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xff58cc02).withOpacity(0.4)),
                                ),
                                child: Text(
                                  "LEVEL $id",
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xff58cc02),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isCompleted)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xfff59e0b).withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xfff59e0b).withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.check_circle_rounded, color: Color(0xfff59e0b), size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        "SELESAI",
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xfff59e0b),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedLevelId = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Color(0xff94a3b8), size: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        level['title'],
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        level['desc'],
                        style: const TextStyle(fontSize: 13, color: Color(0xff94a3b8), height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      // Info Row (Reward XP & Question count)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xff0f172a),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xff334155)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xfff59e0b), size: 16),
                                const SizedBox(width: 5),
                                Text(
                                  isCompleted ? "+${qCount * 3} XP (Review)" : "+$xpReward XP",
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xfff59e0b),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xff0f172a),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xff334155)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.quiz_rounded, color: Color(0xff38bdf8), size: 16),
                                const SizedBox(width: 5),
                                Text(
                                  "$qCount Soal Kuis",
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff38bdf8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // 3D Beveled Green Start Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: Stack(
                          children: [
                            Positioned(
                              top: 4,
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xff46a302),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              bottom: 4,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff58cc02),
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: () {
                                  if (appState.petir <= 0 && !appState.isPremium) {
                                    AudioService.playWrong();
                                    _showRefillLivesModal(context, appState);
                                    return;
                                  }
                                  AudioService.playConfirm();
                                  final qList = List<Map<String, dynamic>>.from(level['questions']);
                                  setState(() {
                                    _selectedLevelId = null;
                                  });
                                  QuizOverlay.start(context, id, level['title'], qList);
                                },
                                child: Text(
                                  isCompleted ? "ULANG LATIHAN" : "MULAI KUIS",
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRefillLivesModal(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff0f172a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xffef4444), width: 1.5),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: Color(0xffef4444), size: 64),
            const SizedBox(height: 12),
            const Text(
              "PETIR ANDA HABIS!",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xffef4444),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Nyawa petir Anda kosong. Klaim hadiah milestone XP, tunggu pemulihan otomatis, atau tonton iklan instan untuk memulai kuis!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xffcbd5e1), height: 1.5),
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
                    const SnackBar(content: Text("1 Nyawa petir telah berhasil dipulihkan.")),
                  );
                });
              },
              child: const Text(
                "TONTON IKLAN (+1 NYAWA)",
                style: TextStyle(fontFamily: 'Outfit', color: Color(0xff10b981), fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("TUTUP", style: TextStyle(color: Color(0xff94a3b8), fontFamily: 'Outfit')),
            ),
          ],
        ),
      ),
    );
  }
}

// 6. Custom Painter to draw connection lines & background grid layout
class RoadmapLinePainter extends CustomPainter {
  final List<Map<String, dynamic>> levelData;
  final List<int> completedLevels;
  final double mapWidth;

  RoadmapLinePainter({
    required this.levelData,
    required this.completedLevels,
    required this.mapWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (levelData.length < 2) return;

    // Build center points for all nodes
    final List<Offset> points = levelData.map((l) {
      final x = (l['xFactor'] as double) * mapWidth;
      final y = (l['y'] as double) + 38.0;
      return Offset(x, y);
    }).toList();

    // Generate one smooth Catmull-Rom spline through ALL nodes
    const int subdiv = 24;
    final List<Offset> spline = _catmullRomSpline(points, subdivisions: subdiv);

    // Draw each segment between consecutive nodes
    for (int i = 0; i < levelData.length - 1; i++) {
      final nextId = levelData[i + 1]['id'] as int;
      final isUnlocked = nextId == 1 || completedLevels.contains(nextId - 1);

      final int s = i * subdiv;
      final int e = (i + 1) * subdiv;
      if (s >= spline.length) continue;
      final seg = spline.sublist(s, (e + 1).clamp(0, spline.length));
      if (seg.length < 2) continue;

      _drawRoadway(canvas, seg, isUnlocked);
    }
  }

  void _drawRoadway(Canvas canvas, List<Offset> pts, bool isUnlocked) {
    if (pts.length < 2) return;

    // NO UNDERLYING ROAD OR MA LINES - ONLY GIANT 3D CANDLESTICKS!
    const double spacing = 34.0; // Spaced evenly for GIANT MASSIVE candles
    double acc = 0.0;
    int candleIndex = 0;

    for (int i = 1; i < pts.length; i++) {
      final p1 = pts[i - 1];
      final p2 = pts[i];
      final dist = (p2 - p1).distance;
      acc += dist;

      if (acc >= spacing) {
        acc = 0.0;
        candleIndex++;
        final pos = p2;

        // Pseudo-random deterministic variations
        final int hash = (candleIndex * 37 + 17) % 100;
        final bool isBullish = (hash % 10) > 3; // 60% Bullish Green, 40% Bearish Red

        // GIANT MASSIVE Dimensions (Super Visible & Bold!)
        double bodyWidth = 12.0 + (hash % 5) * 2.5;  // 12.0px - 22.0px (SUPER CHUNKY!)
        double bodyHeight = 14.0 + (hash % 7) * 6.0; // 14.0px - 50.0px (MASSIVE CANDLE BODIES!)
        double upperWick = 6.0 + ((hash * 3) % 6) * 3.0; // 6.0px - 21.0px
        double lowerWick = 6.0 + ((hash * 5) % 6) * 3.0; // 6.0px - 21.0px

        // Special Doji Candlestick (wide crosshair body, huge wicks)
        if (hash % 8 == 0) {
          bodyHeight = 5.0;
          bodyWidth = 20.0;
          upperWick = 18.0;
          lowerWick = 18.0;
        }

        final double topY = -bodyHeight / 2 - upperWick;
        final double bottomY = bodyHeight / 2 + lowerWick;

        canvas.save();
        canvas.translate(pos.dx, pos.dy);

        if (isUnlocked) {
          final Color candleColor = isBullish
              ? ((hash % 2 == 0) ? const Color(0xff22c55e) : const Color(0xff10b981))
              : ((hash % 2 == 0) ? const Color(0xffef4444) : const Color(0xffdc2626));

          final Color shadowColor = isBullish
              ? const Color(0xff047857)
              : const Color(0xff991b1b);

          final Color wickColor = isBullish
              ? const Color(0xffa7f3d0)
              : const Color(0xfffca5a5);

          // 3D Drop Shadow on Ground
          canvas.drawLine(
            Offset(0, topY + 3.5),
            Offset(0, bottomY + 3.5),
            Paint()..color = Colors.black.withOpacity(0.45)..strokeWidth = 4.5,
          );

          // 3D Candlestick Wick (Thick 3.5px line)
          canvas.drawLine(
            Offset(0, topY),
            Offset(0, bottomY),
            Paint()
              ..color = wickColor
              ..strokeWidth = 3.5
              ..strokeCap = StrokeCap.round,
          );

          // 3D Candlestick Body Box
          final bodyRect = RRect.fromLTRBR(
            -bodyWidth / 2, -bodyHeight / 2, bodyWidth / 2, bodyHeight / 2,
            Radius.circular(bodyHeight < 8 ? 2.0 : 4.0),
          );

          // Base Shadow Extrusion
          canvas.drawRRect(bodyRect.shift(const Offset(0, 3.0)), Paint()..color = shadowColor);
          // Main Body Face
          canvas.drawRRect(bodyRect, Paint()..color = candleColor);

          // Specular Shine Dot
          if (bodyHeight > 10 && bodyWidth > 8) {
            canvas.drawCircle(
              Offset(-bodyWidth / 4, -bodyHeight / 4),
              1.8,
              Paint()..color = Colors.white.withOpacity(0.85),
            );
          }
        } else {
          // Locked Dark Slate Candlestick (GIANT)
          final wickPaint = Paint()
            ..color = const Color(0xff64748b)
            ..strokeWidth = 3.0
            ..strokeCap = StrokeCap.round;

          canvas.drawLine(Offset(0, topY), Offset(0, bottomY), wickPaint);

          final bodyRect = RRect.fromLTRBR(
            -bodyWidth / 2, -bodyHeight / 2, bodyWidth / 2, bodyHeight / 2,
            Radius.circular(bodyHeight < 8 ? 2.0 : 3.5),
          );

          canvas.drawRRect(bodyRect.shift(const Offset(0, 2.5)), Paint()..color = const Color(0xff0f172a));
          canvas.drawRRect(bodyRect, Paint()..color = const Color(0xff334155));
        }

        canvas.restore();
      }
    }
  }

  List<Offset> _catmullRomSpline(List<Offset> pts, {int subdivisions = 24}) {
    final List<Offset> result = [];
    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = pts[(i - 1).clamp(0, pts.length - 1)];
      final p1 = pts[i];
      final p2 = pts[(i + 1).clamp(0, pts.length - 1)];
      final p3 = pts[(i + 2).clamp(0, pts.length - 1)];
      for (int j = 0; j < subdivisions; j++) {
        final t = j / subdivisions;
        result.add(_crPt(p0, p1, p2, p3, t));
      }
    }
    result.add(pts.last);
    return result;
  }

  Offset _crPt(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final t2 = t * t;
    final t3 = t2 * t;
    final x = 0.5 * ((2 * p1.dx) + (-p0.dx + p2.dx) * t +
        (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
        (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3);
    final y = 0.5 * ((2 * p1.dy) + (-p0.dy + p2.dy) * t +
        (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
        (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3);
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant RoadmapLinePainter oldDelegate) =>
      oldDelegate.completedLevels.length != completedLevels.length ||
      oldDelegate.mapWidth != mapWidth;
}

