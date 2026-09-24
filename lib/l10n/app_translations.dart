import 'en.dart';
import 'id.dart';
import 'locale_resolver.dart';

class AppTranslations {
  AppTranslations._();

  static const defaultLocale = 'id';
  static const supportedLocales = <String>['id', 'en'];

  static final Map<String, Map<String, String>> _dynamicTranslations = {};

  static final RegExp _standardKeyRegex = RegExp(
    r'^[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_-]+)*$',
  );

  /// Check whether a key follows the standard dotted identifier format (e.g. 'home.nav_quiz').
  /// Returns false for raw text containing spaces, punctuation, or non-key characters.
  static bool isStandardKey(String? key) {
    if (key == null || key.isEmpty) return false;
    if (key.contains(' ') || key.contains('\t') || key.contains('\n')) {
      return false;
    }
    return _standardKeyRegex.hasMatch(key);
  }

  /// Normalize a raw locale string (e.g. 'en_US', 'ID', ' en ') to a supported code.
  /// If the locale is recognized in static or dynamic dictionaries, returns the clean code.
  /// Otherwise returns [defaultLocale] ('id').
  static String normalizeLocale(String? locale) {
    if (locale == null || locale.trim().isEmpty) return defaultLocale;
    final clean = locale.trim().toLowerCase().split(RegExp(r'[-_]')).first;
    if (clean.isEmpty) return defaultLocale;
    if (supportedLocales.contains(clean) ||
        _dynamicTranslations.containsKey(clean) ||
        allSupportedLanguages.contains(clean)) {
      return clean;
    }
    return defaultLocale;
  }

  /// Add or merge dynamic translations at runtime (e.g. for friend features or remote dictionaries).
  static void addDynamicTranslations(
    String locale,
    Map<String, String> translations,
  ) {
    final cleanLocale = locale.trim().toLowerCase().split(RegExp(r'[-_]')).first;
    if (cleanLocale.isEmpty) return;
    _dynamicTranslations.putIfAbsent(cleanLocale, () => {});
    _dynamicTranslations[cleanLocale]!.addAll(translations);
    registerSupportedLanguage(cleanLocale);
  }

  /// Alias for [addDynamicTranslations].
  static void registerTranslations(
    String locale,
    Map<String, String> translations,
  ) {
    addDynamicTranslations(locale, translations);
  }

  /// Replace dynamic translations for a specific locale.
  static void setDynamicTranslations(
    String locale,
    Map<String, String> translations,
  ) {
    final cleanLocale = locale.trim().toLowerCase().split(RegExp(r'[-_]')).first;
    if (cleanLocale.isEmpty) return;
    _dynamicTranslations[cleanLocale] = Map<String, String>.from(translations);
    registerSupportedLanguage(cleanLocale);
  }

  /// Clear dynamic translations for a specific locale, or all locales if [locale] is null.
  static void clearDynamicTranslations([String? locale]) {
    if (locale != null) {
      final cleanLocale = locale.trim().toLowerCase().split(RegExp(r'[-_]')).first;
      _dynamicTranslations.remove(cleanLocale);
    } else {
      _dynamicTranslations.clear();
      clearDynamicSupportedLanguages();
    }
  }

  /// Get a copy of dynamic translations for inspection or debugging.
  static Map<String, String> getDynamicTranslations(String locale) {
    final cleanLocale = locale.trim().toLowerCase().split(RegExp(r'[-_]')).first;
    return Map<String, String>.unmodifiable(_dynamicTranslations[cleanLocale] ?? {});
  }

  /// Check whether any translation exists for [key] in [locale] or fallbacks.
  static bool hasTranslation(String locale, String key) {
    if (key.isEmpty) return false;
    final cleanLocale = normalizeLocale(locale);
    if (_dynamicTranslations[cleanLocale]?.containsKey(key) ?? false) return true;
    if (_dynamicTranslations[defaultLocale]?.containsKey(key) ?? false) return true;
    final staticMap = cleanLocale == 'en' ? enTranslations : idTranslations;
    if (staticMap.containsKey(key)) return true;
    if (idTranslations.containsKey(key)) return true;
    return false;
  }

  /// Returns all active locales including static and dynamic additions.
  static List<String> get activeLocales => <String>{
    ...supportedLocales,
    ..._dynamicTranslations.keys,
  }.toList();

  /// Resolve translation string with maximum resilience:
  /// 1. Dynamic dictionary for requested locale
  /// 2. Dynamic dictionary fallback for default locale ('id')
  /// 3. If raw text (has spaces or non-standard format), return text directly with parameters replaced
  /// 4. Bundled static dictionaries (requested locale)
  /// 5. Bundled static dictionaries fallback to 'id'
  /// 6. Safe final fallback: return key itself with parameters replaced
  static String text(
    String locale,
    String key, {
    Map<String, String> params = const {},
  }) {
    if (key.isEmpty) return key;

    final cleanLocale = normalizeLocale(locale);

    // 1. Dynamic dictionary lookup for requested locale
    String? resolved = _dynamicTranslations[cleanLocale]?[key];

    // 2. Dynamic dictionary fallback to ID if requested locale is not ID
    if (resolved == null && cleanLocale != defaultLocale) {
      resolved = _dynamicTranslations[defaultLocale]?[key];
    }

    // 3. Raw text resilience: if key has spaces or doesn't match standard key format,
    // and was not explicitly mapped in dynamic translations, return it directly.
    if (resolved == null && (!isStandardKey(key) || key.contains(' '))) {
      return _applyParams(key, params);
    }

    // 4. Bundled static dictionaries lookup
    if (resolved == null) {
      final staticMap = cleanLocale == 'en' ? enTranslations : idTranslations;
      resolved = staticMap[key];
    }

    // 5. Fallback to Indonesian if missing in requested locale
    if (resolved == null && cleanLocale != defaultLocale) {
      resolved = idTranslations[key];
    }

    // 6. Safe final fallback: return key itself
    final value = resolved ?? key;
    return _applyParams(value, params);
  }

  /// Alias for [text].
  static String translate(
    String locale,
    String key, {
    Map<String, String> params = const {},
  }) {
    return text(locale, key, params: params);
  }

  static String _applyParams(String template, Map<String, String> params) {
    if (params.isEmpty || !template.contains('{')) return template;
    var result = template;
    for (final entry in params.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }
}
