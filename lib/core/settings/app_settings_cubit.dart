import 'package:element_x/core/local_storage/session_store.dart';
import 'package:element_x/core/settings/app_settings_keys.dart';
import 'package:element_x/core/settings/app_settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit(this._store)
    : super(
        const AppSettingsState(themeMode: ThemeMode.system, localeCode: 'en'),
      );

  final SessionStore _store;

  Future<void> load() async {
    final themeRaw = _store.read(AppSettingsKeys.themeMode) as String?;
    final localeRaw = _store.read(AppSettingsKeys.locale) as String?;
    emit(
      AppSettingsState(
        themeMode: _parseThemeMode(themeRaw),
        localeCode: _parseLocale(localeRaw),
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == state.themeMode) {
      return;
    }
    await _store.write(AppSettingsKeys.themeMode, _themeModeToString(mode));
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setLocaleCode(String code) async {
    final normalized = _parseLocale(code);
    if (normalized == state.localeCode) {
      return;
    }
    await _store.write(AppSettingsKeys.locale, normalized);
    emit(state.copyWith(localeCode: normalized));
  }

  static ThemeMode _parseThemeMode(String? raw) {
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.system,
    };
  }

  static String _themeModeToString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }

  static String _parseLocale(String? raw) {
    if (raw == 'ar') {
      return 'ar';
    }
    return 'en';
  }
}
