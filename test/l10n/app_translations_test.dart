import 'package:flutter_test/flutter_test.dart';
import 'package:kursus_saham/l10n/app_translations.dart';
import 'package:kursus_saham/l10n/locale_resolver.dart';

void main() {
  setUp(() {
    AppTranslations.clearDynamicTranslations();
  });

  tearDown(() {
    AppTranslations.clearDynamicTranslations();
  });

  test('returns Indonesian text for id locale', () {
    expect(AppTranslations.text('id', 'settings.language'), 'Bahasa Aplikasi');
  });

  test('returns English text for en locale', () {
    expect(AppTranslations.text('en', 'settings.language'), 'App Language');
  });

  test('falls back from missing English key to Indonesian', () {
    expect(
      AppTranslations.text('en', 'settings.language_fallback_probe'),
      'Teks fallback',
    );
  });

  test('falls back to Indonesian for unsupported locale', () {
    expect(AppTranslations.text('de', 'settings.language'), 'Bahasa Aplikasi');
  });

  test('normalizes country code and uppercase locale', () {
    expect(AppTranslations.text('en_US', 'settings.language'), 'App Language');
    expect(AppTranslations.text('ID', 'settings.language'), 'Bahasa Aplikasi');
  });

  test('returns key when key is missing', () {
    expect(AppTranslations.text('en', 'missing.key'), 'missing.key');
  });

  test('replaces named parameters', () {
    expect(
      AppTranslations.text(
        'en',
        'market.buy_success',
        params: {'lots': '10', 'ticker': 'BBCA'},
      ),
      'Bought 10 lots of BBCA',
    );
  });

  // Phase 2: shell & navigation keys
  test('translates shell labels by locale', () {
    expect(AppTranslations.text('id', 'home.nav_quiz'), 'Kuis');
    expect(AppTranslations.text('en', 'home.nav_quiz'), 'Quiz');
  });

  test('translates home nav market by locale', () {
    expect(AppTranslations.text('id', 'home.nav_market'), 'Market');
    expect(AppTranslations.text('en', 'home.nav_market'), 'Market');
  });

  test('translates home nav materi by locale', () {
    expect(AppTranslations.text('id', 'home.nav_materi'), 'Materi');
    expect(AppTranslations.text('en', 'home.nav_materi'), 'Academy');
  });

  test('translates home nav profile by locale', () {
    expect(AppTranslations.text('id', 'home.nav_profile'), 'Saya');
    expect(AppTranslations.text('en', 'home.nav_profile'), 'Profile');
  });

  test('translates home dynamic titles by locale', () {
    expect(AppTranslations.text('id', 'home.title_market'), 'Live Market');
    expect(AppTranslations.text('en', 'home.title_market'), 'Live Market');
    expect(AppTranslations.text('id', 'home.title_materi'), 'Materi Belajar');
    expect(AppTranslations.text('en', 'home.title_materi'), 'Learning Academy');
    expect(AppTranslations.text('id', 'home.title_profile'), 'Profil Anda');
    expect(AppTranslations.text('en', 'home.title_profile'), 'Your Profile');
  });

  test('translates home tooltips by locale', () {
    expect(
      AppTranslations.text('id', 'home.tooltip_premium_lives'),
      'Nyawa tak terbatas',
    );
    expect(
      AppTranslations.text('en', 'home.tooltip_premium_lives'),
      'Unlimited lives',
    );
    expect(
      AppTranslations.text('id', 'home.tooltip_lives'),
      'Nyawa petir Anda',
    );
    expect(
      AppTranslations.text('en', 'home.tooltip_lives'),
      'Your lightning lives',
    );
    expect(
      AppTranslations.text('id', 'home.tooltip_total_xp'),
      'Total XP Terkumpul',
    );
    expect(
      AppTranslations.text('en', 'home.tooltip_total_xp'),
      'Total XP earned',
    );
  });

  // Phase 2: auth validation messages
  test('translates auth validation messages by locale', () {
    expect(
      AppTranslations.text('id', 'auth.password_short'),
      'Kata sandi minimal harus 6 karakter.',
    );
    expect(
      AppTranslations.text('en', 'auth.password_short'),
      'Password must be at least 6 characters.',
    );
  });

  test('translates auth email invalid message by locale', () {
    expect(
      AppTranslations.text('id', 'auth.email_invalid'),
      'Silakan masukkan alamat email yang valid.',
    );
    expect(
      AppTranslations.text('en', 'auth.email_invalid'),
      'Please enter a valid email address.',
    );
  });

  test('translates auth name required message by locale', () {
    expect(
      AppTranslations.text('id', 'auth.name_required'),
      'Silakan masukkan nama lengkap atau panggilan Anda.',
    );
    expect(
      AppTranslations.text('en', 'auth.name_required'),
      'Please enter your full name or nickname.',
    );
  });

  test('translates auth action labels by locale', () {
    expect(AppTranslations.text('id', 'auth.login_tab'), 'Masuk');
    expect(AppTranslations.text('en', 'auth.login_tab'), 'Log In');
    expect(AppTranslations.text('id', 'auth.signup_tab'), 'Daftar');
    expect(AppTranslations.text('en', 'auth.signup_tab'), 'Sign Up');
    expect(AppTranslations.text('id', 'auth.login_action'), 'Masuk ke Akun');
    expect(AppTranslations.text('en', 'auth.login_action'), 'Log In');
    expect(AppTranslations.text('id', 'auth.signup_action'), 'Buat Akun');
    expect(AppTranslations.text('en', 'auth.signup_action'), 'Create Account');
    expect(
      AppTranslations.text('id', 'auth.google_action'),
      'Lanjutkan dengan Google',
    );
    expect(
      AppTranslations.text('en', 'auth.google_action'),
      'Continue with Google',
    );
    expect(
      AppTranslations.text('id', 'auth.guest_action'),
      'Masuk sebagai Tamu',
    );
    expect(
      AppTranslations.text('en', 'auth.guest_action'),
      'Continue as Guest',
    );
  });

  test('translates auth signup success message by locale', () {
    expect(
      AppTranslations.text('id', 'auth.signup_success'),
      'Akun berhasil didaftarkan! Selamat datang di Trade Heroes.',
    );
    expect(
      AppTranslations.text('en', 'auth.signup_success'),
      'Account created! Welcome to Trade Heroes.',
    );
  });

  test('Profile and Settings keys resolve in both supported languages', () {
    const keys = <String>[
      'profile.title',
      'profile.edit',
      'profile.save',
      'profile.cancel',
      'profile.badges',
      'profile.statistics',
      'profile.settings',
      'settings.dark_mode_title',
      'settings.daily_reminder_title',
      'settings.sound_haptic_title',
      'settings.bgm_title',
      'settings.choose_bgm',
      'profile.logout',
    ];

    for (final key in keys) {
      expect(AppTranslations.text('id', key), isNot(key), reason: 'Missing ID key: $key');
      expect(AppTranslations.text('en', key), isNot(key), reason: 'Missing EN key: $key');
    }
  });

  group('Standard key format validation (isStandardKey)', () {
    test('validates standard dotted keys', () {
      expect(AppTranslations.isStandardKey('settings.language'), isTrue);
      expect(AppTranslations.isStandardKey('home.nav_quiz'), isTrue);
      expect(AppTranslations.isStandardKey('friend_module.sub_item.action_btn'), isTrue);
      expect(AppTranslations.isStandardKey('custom-feature.v2.title'), isTrue);
      expect(AppTranslations.isStandardKey('singlekey'), isTrue);
    });

    test('rejects keys containing spaces or whitespace', () {
      expect(AppTranslations.isStandardKey('Fitur Baru Teman'), isFalse);
      expect(AppTranslations.isStandardKey(' leading_space'), isFalse);
      expect(AppTranslations.isStandardKey('trailing_space '), isFalse);
      expect(AppTranslations.isStandardKey('tab\tseparated'), isFalse);
      expect(AppTranslations.isStandardKey('new\nline'), isFalse);
    });

    test('rejects keys containing punctuation or special symbols', () {
      expect(AppTranslations.isStandardKey('Halo Dunia!'), isFalse);
      expect(AppTranslations.isStandardKey('Apakah Anda yakin?'), isFalse);
      expect(AppTranslations.isStandardKey('Key:Value'), isFalse);
      expect(AppTranslations.isStandardKey('a,b,c'), isFalse);
      expect(AppTranslations.isStandardKey('item@email'), isFalse);
    });

    test('rejects empty or malformed dotted strings', () {
      expect(AppTranslations.isStandardKey(''), isFalse);
      expect(AppTranslations.isStandardKey(null), isFalse);
      expect(AppTranslations.isStandardKey('.leading_dot'), isFalse);
      expect(AppTranslations.isStandardKey('trailing_dot.'), isFalse);
      expect(AppTranslations.isStandardKey('double..dot'), isFalse);
    });
  });

  group('Raw text resilience (friend additions without translation keys)', () {
    test('returns raw text with spaces directly in English locale', () {
      const rawText = 'Fitur Baru Saham Teman';
      expect(AppTranslations.text('en', rawText), rawText);
    });

    test('returns raw text with spaces directly in Indonesian locale', () {
      const rawText = 'Lihat Papan Peringkat Teman';
      expect(AppTranslations.text('id', rawText), rawText);
    });

    test('returns raw text with punctuation directly', () {
      const rawPrompt = 'Apakah Anda ingin menantang teman ini?';
      expect(AppTranslations.text('en', rawPrompt), rawPrompt);
      expect(AppTranslations.text('id', rawPrompt), rawPrompt);
    });

    test('replaces params inside raw text with spaces', () {
      expect(
        AppTranslations.text(
          'en',
          'Skor teman Anda: {score} XP di level {level}!',
          params: {'score': '1250', 'level': '7'},
        ),
        'Skor teman Anda: 1250 XP di level 7!',
      );
    });

    test('handles repeated parameters inside raw text', () {
      expect(
        AppTranslations.text(
          'id',
          '{player} menantang {player} dalam duel trading',
          params: {'player': 'Budi'},
        ),
        'Budi menantang Budi dalam duel trading',
      );
    });

    test('preserves unmatched param brackets in raw text without error', () {
      expect(
        AppTranslations.text(
          'en',
          'Selamat datang {user}, bonus Anda {bonus} koin',
          params: {'user': 'Alex'},
        ),
        'Selamat datang Alex, bonus Anda {bonus} koin',
      );
    });

    test('handles empty key and whitespace string safely', () {
      expect(AppTranslations.text('en', ''), '');
      expect(AppTranslations.text('id', '   '), '   ');
    });
  });

  group('Missing key and fallback mechanism', () {
    test('standard key missing in EN falls back to ID', () {
      expect(
        AppTranslations.text('en', 'settings.language_fallback_probe'),
        'Teks fallback',
      );
    });

    test('standard key missing in both EN and ID safely returns the key itself', () {
      const unknownKey = 'friend_feature.completely_unknown_key';
      expect(AppTranslations.text('en', unknownKey), unknownKey);
      expect(AppTranslations.text('id', unknownKey), unknownKey);
    });

    test('unsupported locale falls back to ID bundled translations', () {
      expect(AppTranslations.text('fr', 'settings.language'), 'Bahasa Aplikasi');
      expect(AppTranslations.text('es', 'auth.login_tab'), 'Masuk');
    });

    test('unsupported locale returns key itself if missing in ID', () {
      const missing = 'custom.not_in_any_dict';
      expect(AppTranslations.text('fr', missing), missing);
    });
  });

  group('Dynamic dictionary maps at runtime', () {
    test('adds dynamic translations for EN and ID', () {
      AppTranslations.addDynamicTranslations('en', {
        'friend.pvp_title': 'Friend Trading Battle',
        'friend.pvp_desc': 'Challenge friends in 5-minute trading duels',
      });
      AppTranslations.addDynamicTranslations('id', {
        'friend.pvp_title': 'Pertarungan Trading Teman',
        'friend.pvp_desc': 'Tantang teman dalam duel trading 5 menit',
      });

      expect(
        AppTranslations.text('en', 'friend.pvp_title'),
        'Friend Trading Battle',
      );
      expect(
        AppTranslations.text('id', 'friend.pvp_title'),
        'Pertarungan Trading Teman',
      );
      expect(
        AppTranslations.text('en', 'friend.pvp_desc'),
        'Challenge friends in 5-minute trading duels',
      );
      expect(
        AppTranslations.text('id', 'friend.pvp_desc'),
        'Tantang teman dalam duel trading 5 menit',
      );
    });

    test('dynamic translations take precedence over static translations', () {
      expect(AppTranslations.text('en', 'app.title'), 'Trade Heroes');

      AppTranslations.addDynamicTranslations('en', {
        'app.title': 'Trade Heroes — Friends Edition',
      });

      expect(
        AppTranslations.text('en', 'app.title'),
        'Trade Heroes — Friends Edition',
      );
    });

    test('dynamic translations fall back from EN to ID when key only in ID dynamic dict', () {
      AppTranslations.addDynamicTranslations('id', {
        'friend.room_id_only': 'Ruang Khusus Teman',
      });

      expect(
        AppTranslations.text('en', 'friend.room_id_only'),
        'Ruang Khusus Teman',
      );
    });

    test('allows dynamic translation overrides for raw text keys', () {
      AppTranslations.addDynamicTranslations('en', {
        'Mulai Pertandingan': 'Start Match',
      });

      expect(AppTranslations.text('en', 'Mulai Pertandingan'), 'Start Match');
      expect(
        AppTranslations.text('id', 'Mulai Pertandingan'),
        'Mulai Pertandingan',
      );
    });

    test('interpolates parameters in dynamic translations', () {
      AppTranslations.addDynamicTranslations('en', {
        'friend.duel_result': 'You defeated {opponent} and won {xp} XP!',
      });
      AppTranslations.addDynamicTranslations('id', {
        'friend.duel_result': 'Anda mengalahkan {opponent} dan meraih {xp} XP!',
      });

      expect(
        AppTranslations.text(
          'en',
          'friend.duel_result',
          params: {'opponent': 'Reza', 'xp': '200'},
        ),
        'You defeated Reza and won 200 XP!',
      );
      expect(
        AppTranslations.text(
          'id',
          'friend.duel_result',
          params: {'opponent': 'Reza', 'xp': '200'},
        ),
        'Anda mengalahkan Reza dan meraih 200 XP!',
      );
    });

    test('normalizes locale in dynamic registration and retrieval', () {
      AppTranslations.addDynamicTranslations('en_US', {
        'friend.custom_badge': 'Elite Friend Badge',
      });
      AppTranslations.addDynamicTranslations('ID-id', {
        'friend.custom_badge': 'Lencana Teman Elit',
      });

      expect(
        AppTranslations.text('en', 'friend.custom_badge'),
        'Elite Friend Badge',
      );
      expect(
        AppTranslations.text('id', 'friend.custom_badge'),
        'Lencana Teman Elit',
      );
    });

    test('supports adding an entirely new language at runtime', () {
      AppTranslations.addDynamicTranslations('ja', {
        'app.title': 'トレード・ヒーローズ',
        'friend.battle': '友達バトル',
      });

      expect(AppTranslations.text('ja', 'app.title'), 'トレード・ヒーローズ');
      expect(AppTranslations.text('ja', 'friend.battle'), '友達バトル');
      // Fallback for missing keys in the new language to ID
      expect(AppTranslations.text('ja', 'settings.language'), 'Bahasa Aplikasi');
    });

    test('clears dynamic translations selectively and globally', () {
      AppTranslations.addDynamicTranslations('en', {'temp.key': 'Value EN'});
      AppTranslations.addDynamicTranslations('id', {'temp.key': 'Nilai ID'});

      expect(AppTranslations.text('en', 'temp.key'), 'Value EN');
      expect(AppTranslations.text('id', 'temp.key'), 'Nilai ID');

      // Clear EN only
      AppTranslations.clearDynamicTranslations('en');
      // EN should now fall back to ID dynamic translation
      expect(AppTranslations.text('en', 'temp.key'), 'Nilai ID');

      // Clear all
      AppTranslations.clearDynamicTranslations();
      expect(AppTranslations.text('en', 'temp.key'), 'temp.key');
      expect(AppTranslations.text('id', 'temp.key'), 'temp.key');
    });

    test('hasTranslation returns correct presence across dynamic and static', () {
      expect(AppTranslations.hasTranslation('en', 'settings.language'), isTrue);
      expect(AppTranslations.hasTranslation('en', 'unregistered.key'), isFalse);

      AppTranslations.addDynamicTranslations('en', {
        'unregistered.key': 'Now Registered',
      });
      expect(AppTranslations.hasTranslation('en', 'unregistered.key'), isTrue);
    });

    test('translate method behaves identically to text method', () {
      AppTranslations.addDynamicTranslations('en', {'test.alias': 'Alias Works'});
      expect(
        AppTranslations.translate('en', 'test.alias'),
        AppTranslations.text('en', 'test.alias'),
      );
    });
  });

  group('Friend addition end-to-end adaptability simulation', () {
    test('Friend builds new feature using raw text — zero crash, zero config needed', () {
      // Friend adds a custom widget without updating any translation files:
      final rawButtonText = AppTranslations.text('en', 'Tambah Portofolio Bersama');
      final rawSubtitleText = AppTranslations.text(
        'en',
        'Undang hingga {limit} teman untuk mengelola aset bersama.',
        params: {'limit': '5'},
      );

      expect(rawButtonText, 'Tambah Portofolio Bersama');
      expect(
        rawSubtitleText,
        'Undang hingga 5 teman untuk mengelola aset bersama.',
      );
    });

    test('Friend later provides dynamic dictionary for new feature', () {
      // 1. Initially raw:
      expect(
        AppTranslations.text('en', 'friend_collab.title'),
        'friend_collab.title',
      );

      // 2. Friend dynamically registers the feature dictionary at app start or module init:
      AppTranslations.addDynamicTranslations('en', {
        'friend_collab.title': 'Shared Portfolio',
        'friend_collab.invite_cta': 'Invite Friends',
      });
      AppTranslations.addDynamicTranslations('id', {
        'friend_collab.title': 'Portofolio Bersama',
        'friend_collab.invite_cta': 'Undang Teman',
      });

      // 3. Now dynamically translates:
      expect(AppTranslations.text('en', 'friend_collab.title'), 'Shared Portfolio');
      expect(AppTranslations.text('id', 'friend_collab.title'), 'Portofolio Bersama');
      expect(AppTranslations.text('en', 'friend_collab.invite_cta'), 'Invite Friends');
      expect(AppTranslations.text('id', 'friend_collab.invite_cta'), 'Undang Teman');
    });

    test('Friend partial translation — some keys translated, some rely on ID fallback', () {
      AppTranslations.addDynamicTranslations('id', {
        'friend.feature_a': 'Fitur A',
        'friend.feature_b': 'Fitur B',
      });
      AppTranslations.addDynamicTranslations('en', {
        'friend.feature_a': 'Feature A',
        // feature_b intentionally omitted by friend in EN
      });

      expect(AppTranslations.text('en', 'friend.feature_a'), 'Feature A');
      // Falls back from EN to ID dynamic:
      expect(AppTranslations.text('en', 'friend.feature_b'), 'Fitur B');
    });
  });

  group('LocaleResolver dynamic language registration', () {
    test('supports dynamic language registration and detection', () {
      clearDynamicSupportedLanguages();

      expect(cleanSupportedLanguage('ja'), isNull);

      registerSupportedLanguage('ja');
      expect(cleanSupportedLanguage('ja'), 'ja');
      expect(cleanSupportedLanguage('ja_JP'), 'ja');
      expect(allSupportedLanguages.contains('ja'), isTrue);

      final code = resolveLanguageCode(
        savedLanguage: 'ja',
        deviceLocales: const [],
      );
      expect(code, 'ja');

      clearDynamicSupportedLanguages();
      expect(cleanSupportedLanguage('ja'), isNull);
    });
  });
}
