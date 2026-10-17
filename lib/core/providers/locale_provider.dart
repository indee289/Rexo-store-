import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App language. `null` = follow the device locale (default).
///
/// The chosen language is persisted in SharedPreferences so it survives
/// restarts. Supported: English (en) and Hindi (hi); more can be added by
/// dropping another `app_<code>.arb` file and extending [supported].
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null) {
    _load();
  }

  static const _prefsKey = 'app_locale_code_v1';

  /// Language codes the app ships translations for.
  static const List<String> supported = ['en', 'hi'];

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      if (code != null && supported.contains(code)) {
        state = Locale(code);
      }
    } catch (_) {
      // Non-fatal: fall back to device locale.
    }
  }

  /// Set a specific language, or pass `null` to follow the device locale.
  Future<void> setLocale(Locale? locale) async {
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, locale.languageCode);
      }
    } catch (_) {
      // Non-fatal.
    }
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale?>((ref) => LocaleNotifier());
