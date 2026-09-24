import 'dart:ui';

const String defaultLanguage = 'id';
const List<String> supportedLanguages = ['id', 'en'];

final Set<String> _dynamicSupportedLanguages = {};

/// Register an additional supported language at runtime (e.g. from custom/friend additions).
void registerSupportedLanguage(String languageCode) {
  final clean = languageCode.trim().toLowerCase().split(RegExp(r'[-_]')).first;
  if (clean.isNotEmpty && !supportedLanguages.contains(clean)) {
    _dynamicSupportedLanguages.add(clean);
  }
}

/// Clear any dynamically registered languages.
void clearDynamicSupportedLanguages() {
  _dynamicSupportedLanguages.clear();
}

/// All currently supported languages (base + dynamically registered).
List<String> get allSupportedLanguages => [
  ...supportedLanguages,
  ..._dynamicSupportedLanguages,
];

String? cleanSupportedLanguage(String? raw, {Iterable<String>? extraSupported}) {
  if (raw == null) return null;
  final clean = raw.trim().toLowerCase().split(RegExp(r'[-_]')).first;
  if (clean.isEmpty) return null;
  if (supportedLanguages.contains(clean) ||
      _dynamicSupportedLanguages.contains(clean) ||
      (extraSupported != null && extraSupported.contains(clean))) {
    return clean;
  }
  return null;
}

String resolveLanguageCode({
  required String? savedLanguage,
  required Iterable<Locale> deviceLocales,
  String? fallbackSavedLanguage,
  Iterable<String>? extraSupportedLanguages,
}) {
  final cleanSaved = cleanSupportedLanguage(
        savedLanguage,
        extraSupported: extraSupportedLanguages,
      ) ??
      cleanSupportedLanguage(
        fallbackSavedLanguage,
        extraSupported: extraSupportedLanguages,
      );
  if (cleanSaved != null) {
    return cleanSaved;
  }
  for (final deviceLocale in deviceLocales) {
    final code = cleanSupportedLanguage(
      deviceLocale.languageCode,
      extraSupported: extraSupportedLanguages,
    );
    if (code != null) {
      return code;
    }
  }
  return defaultLanguage;
}

Locale resolveInitialLocale({
  required String? savedLanguage,
  required Iterable<Locale> deviceLocales,
  String? fallbackSavedLanguage,
  Iterable<String>? extraSupportedLanguages,
}) {
  return Locale(resolveLanguageCode(
    savedLanguage: savedLanguage,
    deviceLocales: deviceLocales,
    fallbackSavedLanguage: fallbackSavedLanguage,
    extraSupportedLanguages: extraSupportedLanguages,
  ));
}
