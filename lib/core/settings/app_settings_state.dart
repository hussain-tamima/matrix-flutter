import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AppSettingsState extends Equatable {
  const AppSettingsState({required this.themeMode, required this.localeCode});

  final ThemeMode themeMode;
  final String localeCode;

  bool isDarkFor(BuildContext context) {
    return switch (themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
  }

  AppSettingsState copyWith({ThemeMode? themeMode, String? localeCode}) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
    );
  }

  @override
  List<Object?> get props => [themeMode, localeCode];
}
