import 'package:flutter/material.dart';

/// Centralized bilingual repository for quiz levels and questions with Procedural Map Generation
class KuisData {
  /// Procedural S-curve horizontal oscillation pattern (Duolingo style)
  static const List<double> _xCurvePattern = [0.5, 0.72, 0.76, 0.5, 0.28, 0.24];

  /// Computes procedural layout metadata for dynamic map rendering
  static Map<String, dynamic> computeMapLayout(List<Map<String, dynamic>> levels) {
    if (levels.isEmpty) {
      return {
        'totalHeight': 1825.0,
        'zoneHeaders': <Map<String, dynamic>>[],
        'milestoneChests': <Map<String, dynamic>>[],
        'trophyTop': 30.0,
      };
    }

    final int n = levels.length;

    // 1. Calculate Y coordinates upward from bottom or downward from top (Level N at 120.0px)
    final Map<int, double> yMap = {};
    yMap[n] = 120.0;

    for (int i = n - 1; i >= 1; i--) {
      final int currZone = (levels[i - 1]['zone'] as num?)?.toInt() ?? 1;
      final int upperZone = (levels[i]['zone'] as num?)?.toInt() ?? 1;

      if (currZone == upperZone) {
        yMap[i] = yMap[i + 1]! + 140.0;
      } else {
        // Generous vertical clearance for Zone Header + Milestone Chest
        yMap[i] = yMap[i + 1]! + 240.0;
      }
    }

    // 2. Attach computed procedural xFactor and y to each level map
    for (int i = 0; i < levels.length; i++) {
      final l = levels[i];
      final int lid = l['id'] as int;
      l['xFactor'] = _xCurvePattern[(lid - 1) % _xCurvePattern.length];
      l['y'] = yMap[lid] ?? (1580.0 - (lid - 1) * 140.0);
    }

    // 3. Group levels by zone for procedural headers & milestone chests
    final Map<int, List<Map<String, dynamic>>> zones = {};
    for (final l in levels) {
      final int z = (l['zone'] as num?)?.toInt() ?? 1;
      zones.putIfAbsent(z, () => []).add(l);
    }

    final List<Map<String, dynamic>> zoneHeaders = [];
    final List<Map<String, dynamic>> milestoneChests = [];
    final sortedZones = zones.keys.toList()..sort();

    for (final z in sortedZones) {
      final zLevels = zones[z]!;
      final firstLevel = zLevels.first;
      final lastLevel = zLevels.last;

      double headerTop;
      if (z == 1) {
        headerTop = (firstLevel['y'] as double) + 155.0;
      } else {
        final prevLast = zones[z - 1]!.last;
        headerTop = (prevLast['y'] as double) - 90.0;
      }

      zoneHeaders.add({
        'zone': z,
        'top': headerTop,
        'firstLevelId': firstLevel['id'],
        'lastLevelId': lastLevel['id'],
        'rangeStr': 'Level ${firstLevel['id']} - ${lastLevel['id']}',
      });

      // Milestone Chest for completed zone (at the finish of each zone except the last)
      if (z < sortedZones.last) {
        final double lastY = (lastLevel['y'] as double);
        final double lastX = (lastLevel['xFactor'] as double);
        milestoneChests.add({
          'zone': z,
          'levelId': lastLevel['id'] as int,
          'y': lastY - 45.0, // Sits snugly directly above the zone-ending node
          'xFactor': lastX <= 0.5 ? 0.76 : 0.24,
          'xpReward': z * 50,
        });
      }
    }

    final double totalHeight = (yMap[1] ?? 1580.0) + 245.0;

    return {
      'totalHeight': totalHeight,
      'zoneHeaders': zoneHeaders,
      'milestoneChests': milestoneChests,
      'trophyTop': 30.0,
    };
  }

  static List<Map<String, dynamic>> getLevelData(String language) {
    final isEn = language == 'en';

    return [
      {
        'id': 1,
        'title': isEn ? "Introduction to Stocks" : "Pengenalan Saham",
        'desc': isEn
            ? "Understand the fundamentals of equity ownership & inflation."
            : "Pahami konsep dasar kepemilikan modal & inflasi.",
        'zone': 1,
        'xFactor': 0.5,
        'y': 1580.0,
        'icon': Icons.book_outlined,
        'questions': [
          {
            'type': 'pilgan',
            'q': isEn
                ? "What is the fundamental definition of a stock (share)?"
                : "Apa pengertian dasar dari saham?",
            'options': isEn
                ? [
                    "A debt certificate issued by the government",
                    "Proof of equity ownership in a corporation",
                    "A cryptocurrency mined digitally",
                    "A commercial bank certificate of deposit"
                  ]
                : [
                    "Surat utang yang diterbitkan oleh pemerintah",
                    "Bukti kepemilikan modal atas suatu perusahaan",
                    "Mata uang kripto hasil penambangan digital",
                    "Sertifikat deposito bank komersial"
                  ],
            'a': 1,
            'explanation': isEn
                ? "A stock is a financial security representing fractional ownership in a corporation."
                : "Saham adalah surat berharga yang menunjukkan bagian kepemilikan atas suatu perusahaan."
          },
          {
            'type': 'esai',
            'q': isEn
                ? "Write the name of the security proving fractional ownership of a company's assets (starts with S):"
                : "Tuliskan nama instrumen bukti kepemilikan sebagian aset perusahaan (dimulai dengan huruf S):",
            'a': isEn ? "stock" : "saham",
            'accepted': isEn
                ? ["stock", "stocks", "shares", "share", "saham"]
                : ["saham", "stock"],
            'explanation': isEn
                ? "Stock (or share) represents partial equity ownership in a corporation."
                : "Saham merupakan bukti kepemilikan modal di suatu perseroan terbatas."
          },
          {
            'type': 'pilgan',
            'q': isEn
                ? "If you purchase shares of PT Telkom Indonesia, your status is..."
                : "Jika Anda membeli saham PT Telkom Indonesia, Anda berstatus sebagai...",
            'options': isEn
                ? [
                    "A permanent employee of Telkom",
                    "A lender creditor",
                    "A fractional co-owner of Telkom",
                    "The Chief Executive Officer of Telkom"
                  ]
                : [
                    "Karyawan tetap Telkom",
                    "Kreditor pemberi pinjaman",
                    "Salah satu pemilik Telkom",
                    "Direktur utama Telkom"
                  ],
            'a': 2,
            'explanation': isEn
                ? "Buying shares means acquiring equity in the company, making you one of its owners (shareholders)."
                : "Membeli saham berarti memiliki porsi modal perusahaan, sehingga Anda menjadi salah satu pemilik (pemegang saham) perusahaan tersebut."
          }
        ]
      },
      {
        'id': 2,
        'title': isEn ? "The Stock Exchange" : "Bursa Efek",
        'desc': isEn
            ? "Get to know the institution where securities trading takes place."
            : "Kenali institusi tempat perdagangan efek berlangsung.",
        'zone': 1,
        'xFactor': 0.28,
        'y': 1440.0,
        'icon': Icons.business,
        'questions': [
          {
            'type': 'esai',
            'q': isEn
                ? "What is the official abbreviation for the Indonesia Stock Exchange?"
                : "Apa singkatan resmi dari Bursa Efek Indonesia?",
            'a': isEn ? "idx" : "bei",
            'accepted': ["idx", "bei"],
            'explanation': isEn
                ? "The Indonesia Stock Exchange is abbreviated as IDX (or BEI in Indonesian)."
                : "Bursa Efek Indonesia biasa disingkat BEI (atau IDX dalam bahasa Inggris)."
          },
          {
            'type': 'pilgan',
            'q': isEn
                ? "The official organized marketplace where securities buyers and sellers meet is called..."
                : "Tempat bertemunya para penjual dan pembeli saham/efek secara resmi dinamakan...",
            'options': isEn
                ? [
                    "Central Bank",
                    "Traditional Market",
                    "Stock Exchange",
                    "Credit Union"
                  ]
                : [
                    "Bank Indonesia",
                    "Pasar Tradisional",
                    "Bursa Efek",
                    "Koperasi Unit Desa"
                  ],
            'a': 2,
            'explanation': isEn
                ? "A stock exchange is an organized, regulated institution providing a facility for trading securities."
                : "Bursa Efek adalah lembaga resmi penyedia sistem perdagangan efek."
          },
          {
            'type': 'esai',
            'q': isEn
                ? "What is the acronym for the benchmark index tracking all listed shares on the IDX?"
                : "Singkatan dari indeks rata-rata pergerakan harga seluruh saham di BEI adalah...",
            'a': "ihsg",
            'accepted': ["ihsg", "idx composite", "composite"],
            'explanation': isEn
                ? "IHSG (or IDX Composite) measures the overall performance of all listed stocks on the IDX."
                : "IHSG singkatan dari Indeks Harga Saham Gabungan."
          }
        ]
      },
      {
        'id': 3,
        'title': isEn ? "Dividends & Capital Gains" : "Dividen & Capital Gain",
        'desc': isEn
            ? "Learn the two primary sources of stock investment returns."
            : "Pelajari 2 sumber keuntungan utama investasi saham.",
        'zone': 1,
        'xFactor': 0.72,
        'y': 1300.0,
        'icon': Icons.attach_money,
        'questions': [
          {
            'type': 'pilgan',
            'q': isEn
                ? "The profit realized from selling a stock at a higher price than its purchase price is called..."
                : "Keuntungan yang didapat dari selisih kenaikan harga jual saham dibanding harga beli disebut...",
            'options': isEn
                ? [
                    "Dividend",
                    "Capital Gain",
                    "Capital Loss",
                    "Bond Coupon"
                  ]
                : [
                    "Dividen",
                    "Capital Gain",
                    "Capital Loss",
                    "Kupon Obligasi"
                  ],
            'a': 1,
            'explanation': isEn
                ? "Capital Gain occurs when a stock is sold for a higher price than its initial purchase price."
                : "Capital Gain terjadi saat harga saham yang Anda beli mengalami kenaikan saat dijual."
          },
          {
            'type': 'esai',
            'q': isEn
                ? "The portion of corporate net profits distributed to shareholders is called..."
                : "Bagian laba bersih perusahaan yang dibagikan kepada pemegang saham dinamakan...",
            'a': isEn ? "dividend" : "dividen",
            'accepted': isEn
                ? ["dividend", "dividends", "dividen"]
                : ["dividen", "dividend"],
            'explanation': isEn
                ? "Dividends are distributions of corporate earnings paid out to shareholders as approved by the AGM."
                : "Dividen dibayarkan perusahaan secara berkala berdasarkan keputusan RUPS."
          },
          {
            'type': 'pilgan',
            'q': isEn
                ? "The financial loss incurred when selling a stock below its original purchase price is called..."
                : "Kerugian yang timbul ketika Anda menjual saham di bawah harga pembeliaan awal disebut...",
            'options': isEn
                ? [
                    "Capital Gain",
                    "Capital Loss",
                    "Dividend Yield",
                    "Cashback"
                  ]
                : [
                    "Capital Gain",
                    "Capital Loss",
                    "Dividen Yield",
                    "Cashback"
                  ],
            'a': 1,
            'explanation': isEn
                ? "Capital Loss is the loss of principal when an asset is sold for less than its acquisition cost."
                : "Capital Loss adalah kerugian modal ketika harga penutupan/jual lebih rendah dari modal beli."
          }
        ]
      },
      {
        'id': 4,
        'title': isEn ? "Candlestick Basics" : "Candlestick Dasar",
        'desc': isEn
            ? "Learn to interpret price movement through candlestick charts."
            : "Belajar memahami pergerakan harga melalui grafik lilin.",
        'zone': 2,
        'xFactor': 0.28,
        'y': 1060.0,
        'icon': Icons.candlestick_chart,
        'questions': [
          {
            'type': 'pilgan',
            'q': isEn
                ? "On standard stock charts, a green candle typically signifies that the price..."
                : "Secara umum pada grafik saham, lilin berwarna hijau menandakan bahwa harga...",
            'options': isEn
                ? [
                    "Closed lower than the open price (Down)",
                    "Closed higher than the open price (Up)",
                    "Did not move at all",
                    "Experienced a fraudulent transaction"
                  ]
                : [
                    "Ditutup lebih rendah dari harga buka (Turun)",
                    "Ditutup lebih tinggi dari harga buka (Naik)",
                    "Sama sekali tidak bergerak",
                    "Mengalami transaksi bodong"
                  ],
            'a': 1,
            'explanation': isEn
                ? "A green (bullish) candlestick indicates that the closing price was higher than the opening price."
                : "Lilin hijau (Bullish) menunjukkan penutupan harga lebih tinggi dari harga pembukaan."
          },
          {
            'type': 'esai',
            'q': isEn
                ? "The upper tip of a candlestick wick/shadow represents the period's price (High/Low):"
                : "Titik teratas pada sumbu (shadow) grafik candlestick menggambarkan harga...",
            'a': isEn ? "high" : "tertinggi",
            'accepted': isEn
                ? ["high", "highest", "tertinggi"]
                : ["tertinggi", "high"],
            'explanation': isEn
                ? "The top of the upper shadow represents the highest price traded during that period."
                : "Ujung atas ekor candlestick adalah harga tertinggi (High) pada periode tersebut."
          },
          {
            'type': 'pilgan',
            'q': isEn
                ? "A red candle on a candlestick chart indicates dominant pressure from..."
                : "Lilin berwarna merah pada candlestick chart mengindikasikan dominan tekanan...",
            'options': isEn
                ? [
                    "Buying pressure",
                    "Selling pressure",
                    "Stagnant market",
                    "Dividend distribution"
                  ]
                : [
                    "Pembelian (Beli)",
                    "Penjualan (Jual)",
                    "Stagnan",
                    "Pembagian Dividen"
                  ],
            'a': 1,
            'explanation': isEn
                ? "A red (bearish) candle indicates that sellers pushed the price below the opening price."
                : "Lilin merah (Bearish) menandakan harga saham tertekan turun oleh dorongan aksi jual."
          }
        ]
      },
      {
        'id': 5,
        'title': "Support & Resistance",
        'desc': isEn
            ? "Identify psychological price floors and ceilings in stock movements."
            : "Tentukan batas lantai dan atap pergerakan harga saham.",
        'zone': 2,
        'xFactor': 0.72,
        'y': 920.0,
        'icon': Icons.horizontal_rule,
        'questions': [
          {
            'type': 'esai',
            'q': isEn
                ? "The psychological price floor where buying interest is strong enough to halt downward movement is called..."
                : "Area batas bawah psikologis di mana harga saham cenderung menahan penurunan disebut...",
            'a': "support",
            'accepted': ["support"],
            'explanation': isEn
                ? "Support is the price level where demand is thought to be strong enough to prevent the price from dropping further."
                : "Support adalah tingkat harga di mana pembeli diprakirakan cukup kuat untuk menahan harga turun."
          },
          {
            'type': 'pilgan',
            'q': isEn
                ? "What does a Resistance level represent in technical stock analysis?"
                : "Apa arti dari batas Resistance dalam grafik teknikal saham?",
            'options': isEn
                ? [
                    "Unrestricted explosive upward momentum",
                    "Upward ceiling where price pauses or reverses downward",
                    "Trading volume drops to zero immediately",
                    "The company executes a stock split"
                  ]
                : [
                    "Langsung naik drastis tanpa hambatan",
                    "Tertahan naik dan berpotensi berbalik turun",
                    "Volume perdagangan langsung habis",
                    "Perusahaan melakukan stock split"
                  ],
            'a': 1,
            'explanation': isEn
                ? "Resistance acts as a psychological ceiling where selling pressure exceeds buying pressure, halting an advance."
                : "Resistance bertindak sebagai 'atap' psikologis di mana pasokan jual bertambah dan menahan kenaikan harga."
          },
          {
            'type': 'pilgan',
            'q': isEn
                ? "What commonly happens when a Resistance level is broken upward (Breakout)?"
                : "Apa yang terjadi jika suatu level Resistance berhasil ditembus ke atas (Breakout)?",
            'options': isEn
                ? [
                    "The level disappears permanently",
                    "The broken level often becomes a new Support level",
                    "The stock is immediately suspended from trading",
                    "Investors are required to liquidate all positions"
                  ]
                : [
                    "Level tersebut hilang selamanya",
                    "Level tersebut berpotensi berubah menjadi Support baru",
                    "Harga saham langsung disuspensi",
                    "Investor wajib menjual semua sahamnya"
                  ],
            'a': 1,
            'explanation': isEn
                ? "Under the principle of role reversal in technical analysis, once resistance is decisively breached, it tends to act as support."
                : "Dalam analisis teknikal, Resistance yang tertembus ke atas cenderung berbalik fungsi menjadi Support baru (Principle of Role Reversal)."
          }
        ]
      },
      {
        'id': 6,
        'title': isEn ? "Trendlines & Trends" : "Trendlines",
        'desc': isEn
            ? "Read the dominant directional trajectory of market prices."
            : "Membaca arah tren pasar saham.",
        'zone': 2,
        'xFactor': 0.28,
        'y': 780.0,
        'icon': Icons.trending_up,
        'questions': [
          {
            'type': 'esai',
            'q': isEn
                ? "A market price pattern that consistently makes higher highs and higher lows is an..."
                : "Tren pergerakan harga saham yang terus mencetak puncak dan lembah lebih tinggi disebut...",
            'a': "uptrend",
            'accepted': ["uptrend", "bullish trend"],
            'explanation': isEn
                ? "An uptrend is characterized by a series of successive Higher Highs (HH) and Higher Lows (HL)."
                : "Uptrend dicirikan dengan formasi Higher High (HH) dan Higher Low (HL)."
          },
          {
            'type': 'pilgan',
            'q': isEn
                ? "A market condition where prices oscillate horizontally within a defined trading range is called..."
                : "Keadaan pasar di mana harga bergerak mendatar dalam range tertentu disebut...",
            'options': isEn
                ? ["Uptrend", "Downtrend", "Sideways", "Bull Run"]
                : ["Uptrend", "Downtrend", "Sideways", "Bullrun"],
            'a': 2,
            'explanation': isEn
                ? "A sideways (or consolidation) trend occurs when the forces of supply and demand are roughly equal."
                : "Sideways (atau konsolidasi) adalah fase pasar tanpa tren naik atau turun yang dominan."
          },
          {
            'type': 'pilgan',
            'q': isEn
                ? "To draw a valid Downtrend line, one must connect..."
                : "Untuk menggambar garis Downtrend yang valid, kita harus menghubungkan...",
            'options': isEn
                ? [
                    "The lowest valley swing lows",
                    "A series of descending swing highs (lower highs)",
                    "Only the morning opening prices",
                    "Only the year-end closing prices"
                  ]
                : [
                    "Titik-titik lembah terendah (swing lows)",
                    "Titik-titik puncak tertinggi (swing highs) yang semakin menurun",
                    "Harga pembukaan di pagi hari saja",
                    "Harga penutupan di akhir tahun saja"
                  ],
            'a': 1,
            'explanation': isEn
                ? "A descending trendline is drawn connecting at least two consecutive lower highs acting as dynamic resistance."
                : "Downtrend line digambar dengan menghubungkan minimal dua titik puncak harga (lower highs) untuk membatasi pergerakan naik."
          }
        ]
      },
      {
        'id': 7,
        'title': isEn ? "Basic Technical Indicators" : "Indikator Dasar",
        'desc': isEn
            ? "Utilize mathematical visual tools for trading analysis."
            : "Menggunakan alat bantu visual matematis untuk trading.",
        'zone': 2,
        'xFactor': 0.72,
        'y': 640.0,
        'icon': Icons.settings,
        'questions': [
          {
            'type': 'esai',
            'q': isEn
                ? "The technical indicator that smooths out price data over time is abbreviated MA, standing for..."
                : "Indikator rata-rata pergerakan harga historis saham disingkat MA, kepanjangannya adalah...",
            'a': "moving average",
            'accepted': ["moving average", "moving averages"],
            'explanation': isEn
                ? "Moving Averages calculate the average price over a specified period to smooth out random price noise."
                : "Moving Average (Rerata Bergerak) meratakan fluktuasi harga untuk membantu melihat tren utama."
          },
          {
            'type': 'pilgan',
            'q': isEn
                ? "The primary purpose of the RSI (Relative Strength Index) oscillator is to measure..."
                : "Fungsi utama dari indikator osilator RSI adalah mengukur...",
            'options': isEn
                ? [
                    "Market maker liquidity depth",
                    "Overbought and oversold momentum conditions",
                    "Corporate quarterly net revenue",
                    "Bid and ask order book thickness"
                  ]
                : [
                    "Likuiditas bandar saham",
                    "Kondisi jenuh beli (overbought) dan jenuh jual (oversold)",
                    "Pendapatan tahunan perusahaan terbaru",
                    "Ketebalan antrean bid dan offer"
                  ],
            'a': 1,
            'explanation': isEn
                ? "The RSI oscillator gauges momentum by measuring the speed and change of price movements on a 0 to 100 scale."
                : "Relative Strength Index (RSI) mengukur momentum kekuatan harga pada rentang skala 0 hingga 100."
          },
          {
            'type': 'pilgan',
            'q': isEn
                ? "The standard threshold indicating that a stock has entered the Overbought zone on the RSI is..."
                : "Angka standar indikator RSI yang menandakan saham masuk area jenuh beli (Overbought) adalah...",
            'options': isEn
                ? ["Below 30", "Above 50", "Above 70", "Exactly 0"]
                : ["Di bawah 30", "Di atas 50", "Di atas 70", "Tepat di angka 0"],
            'a': 2,
            'explanation': isEn
                ? "Traditionally, an RSI reading of 70 or above indicates overbought territory, while 30 or below indicates oversold."
                : "Umumnya, nilai RSI di atas 70 menunjukkan overbought (potensi jenuh beli/turun), sedangkan di bawah 30 menunjukkan oversold (potensi jenuh jual/naik)."
          }
        ]
      },
      {
        'id': 8,
        'title': isEn ? "Money Management & Risk" : "Money Management",
        'desc': isEn
            ? "Protect your trading capital from ruin through disciplined risk control."
            : "Lindungi modal trading Anda dari kebangkrutan.",
        'zone': 3,
        'xFactor': 0.28,
        'y': 400.0,
        'icon': Icons.security,
        'questions': [
          {
            'type': 'pilgan',
            'q': isEn
                ? "What is the recommended maximum percentage of total capital to risk per single trade?"
                : "Berapa persen batasan risiko maksimal dari total modal per transaksi yang disarankan bagi trader?",
            'options': isEn
                ? [
                    "10% - 20%",
                    "50%",
                    "1% - 2%",
                    "No risk limit"
                  ]
                : [
                    "10% - 20%",
                    "50%",
                    "1% - 2%",
                    "Tidak ada batasan risiko"
                  ],
            'a': 2,
            'explanation': isEn
                ? "The 1-2% risk rule ensures a trader can survive a string of consecutive losses without devastating their account."
                : "Aturan 1-2% memastikan modal trader tidak habis meskipun mengalami kerugian berturut-turut."
          },
          {
            'type': 'esai',
            'q': isEn
                ? "The ratio comparing potential loss against expected profit is called the Risk to ... Ratio:"
                : "Perbandingan antara risiko kerugian dan potensi keuntungan transaksi disebut Risk to... Ratio:",
            'a': "reward",
            'accepted': ["reward", "reward ratio"],
            'explanation': isEn
                ? "The Risk to Reward Ratio measures expected returns for every unit of capital put at risk."
                : "Risk to Reward Ratio membantu mengukur apakah suatu trading layak diambil dibanding risikonya."
          },
          {
            'type': 'pilgan',
            'q': isEn
                ? "With a portfolio of Rp 10,000,000 and a 2% risk limit, your maximum allowable loss per trade is..."
                : "Jika Anda memiliki modal Rp 10.000.000 dan menerapkan batasan risiko 2%, batas kerugian maksimal per trading adalah...",
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
        'title': isEn ? "Trading Psychology" : "Psikologi Trading",
        'desc': isEn
            ? "Master emotional discipline, FOMO, and greed in the market."
            : "Kuasai emosi FOMO dan serakah saat trading.",
        'zone': 3,
        'xFactor': 0.72,
        'y': 260.0,
        'icon': Icons.psychology,
        'questions': [
          {
            'type': 'esai',
            'q': isEn
                ? "The psychological syndrome of buying impulsively at the top out of fear of missing gains is called..."
                : "Sindrom takut tertinggal peluang cuan di saham sehingga beli terburu-buru di harga pucuk disebut...",
            'a': "fomo",
            'accepted': ["fomo"],
            'explanation': isEn
                ? "FOMO stands for Fear Of Missing Out."
                : "FOMO singkatan dari Fear Of Missing Out."
          },
          {
            'type': 'pilgan',
            'q': isEn
                ? "What is the primary psychological driver preventing novice traders from cutting losses?"
                : "Apa pemicu utama trader pemula enggan melakukan Cut Loss ketika saham terus merosot?",
            'options': isEn
                ? [
                    "Excessive adherence to the original trading plan",
                    "Loss aversion bias and false hope of price recovery",
                    "Brokerage commission rates that are too low",
                    "Direct advice from the Stock Exchange"
                  ]
                : [
                    "Terlalu disiplin mengikuti rencana awal",
                    "Rasa enggan mengakui kerugian (loss aversion) & harapan semu",
                    "Ketentuan komisi broker yang terlalu murah",
                    "Saran dari Bursa Efek Indonesia"
                  ],
            'a': 1,
            'explanation': isEn
                ? "Loss aversion bias causes individuals to strongly prefer avoiding losses over acquiring equivalent gains, leading to holding declining assets."
                : "Loss aversion menyebabkan trader menolak kenyataan bahwa mereka salah dan terus memegang saham turun dengan harapan berbalik arah."
          },
          {
            'type': 'pilgan',
            'q': isEn
                ? "What term describes the impulsive, emotional urge to recover previous losses by taking reckless trades?"
                : "Apa istilah trading impulsif dengan modal besar demi membalas kerugian sebelumnya?",
            'options': isEn
                ? [
                    "Swing Trading",
                    "Revenge Trading",
                    "Scalping",
                    "Value Investing"
                  ]
                : [
                    "Swing Trading",
                    "Revenge Trading",
                    "Scalping",
                    "Value Investing"
                  ],
            'a': 1,
            'explanation': isEn
                ? "Revenge trading is an emotional response driven by anger and frustration to recoup losses quickly, often leading to catastrophic drawdowns."
                : "Revenge trading (trading balas dendam) dipicu emosi kemarahan dan seringkali merusak perencanaan trading secara rasional."
          }
        ]
      },
      {
        'id': 10,
        'title': isEn ? "Cut Loss vs Take Profit" : "Cut Loss vs TP",
        'desc': isEn
            ? "Know exactly when to lock in profits and truncate losses."
            : "Ketahui kapan harus mengunci profit dan memotong kerugian.",
        'zone': 3,
        'xFactor': 0.28,
        'y': 120.0,
        'icon': Icons.swap_vert,
        'questions': [
          {
            'type': 'esai',
            'q': isEn
                ? "Selling a losing position to preserve remaining capital from steeper declines is called Cut ..."
                : "Menjual saham yang merugi demi melindungi sisa modal dari penurunan lebih dalam disebut Cut...",
            'a': isEn ? "loss" : "loss",
            'accepted': ["loss", "losses"],
            'explanation': isEn
                ? "A Cut Loss (Stop Loss) is essential risk management to protect trading capital from severe drawdowns."
                : "Cut Loss adalah tindakan wajib untuk membatasi risiko kerugian secara disiplin."
          },
          {
            'type': 'esai',
            'q': isEn
                ? "Securing accumulated gains by closing a winning trade at your planned target is called Take ..."
                : "Mengamankan keuntungan trading dengan menjual saham sesuai target awal dinamakan Take...",
            'a': "profit",
            'accepted': ["profit", "profits"],
            'explanation': isEn
                ? "Taking Profit locks in realized gains according to your pre-defined trading plan."
                : "Take Profit mengunci keuntungan agar tidak berbalik menjadi kerugian."
          },
          {
            'type': 'pilgan',
            'q': isEn
                ? "Which automated order type triggers an automatic sell order when a pre-set downside threshold is hit?"
                : "Apa nama fitur perdagangan otomatis yang membantu menutup posisi rugi secara instan?",
            'options': isEn
                ? [
                    "Limit Order",
                    "Stop Loss / Trailing Stop",
                    "Market Maker",
                    "Dividend Payout"
                  ]
                : [
                    "Limit Order",
                    "Stop Loss / Trailing Stop",
                    "Market Maker",
                    "Dividen Payout"
                  ],
            'a': 1,
            'explanation': isEn
                ? "A Stop Loss automatically executes a market or limit order once a specified trigger price is reached to prevent larger losses."
                : "Stop Loss otomatis memicu order jual ketika harga menyentuh batas bawah pengaman yang ditentukan."
          }
        ]
      }
    ];
  }
}
