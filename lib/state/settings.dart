import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main.dart` with the loaded instance.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider not overridden'),
);

class AppSettings {
  const AppSettings({required this.themeMode, required this.localeCode});

  final ThemeMode themeMode;

  /// `th` or `en` (SRS 4.7).
  final String localeCode;

  AppSettings copyWith({ThemeMode? themeMode, String? localeCode}) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        localeCode: localeCode ?? this.localeCode,
      );
}

/// Theme and language chosen on this device.
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  static const _themeKey = 'themeMode';
  static const _localeKey = 'locale';

  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final deviceLocale =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == prefs.getString(_themeKey),
        orElse: () => ThemeMode.system,
      ),
      localeCode:
          prefs.getString(_localeKey) ?? (deviceLocale == 'en' ? 'en' : 'th'),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_themeKey, mode.name);
  }

  Future<void> setLocale(String code) async {
    state = state.copyWith(localeCode: code);
    await _prefs.setString(_localeKey, code);
  }
}
