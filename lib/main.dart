import 'package:easy_localization/easy_localization.dart';
// Localization.load is the only way to resolve keys before the widget loads.
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:element_x/app/element_app.dart';
import 'package:element_x/core/di/di.dart';
import 'package:element_x/core/settings/app_settings_cubit.dart';
import 'package:flutter/material.dart';

const _translationsPath = 'assets/translations';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await initDependencies();
  final appSettings = sl<AppSettingsCubit>();
  await appSettings.load();
  final startLocale = Locale(appSettings.state.localeCode);
  await _preloadLocale(startLocale);
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: _translationsPath,
      fallbackLocale: const Locale('en'),
      startLocale: startLocale,
      child: const ElementApp(),
    ),
  );
}

Future<void> _preloadLocale(Locale locale) async {
  final data = await const RootBundleAssetLoader().load(
    _translationsPath,
    locale,
  );
  if (data == null) {
    return;
  }
  Localization.load(locale, translations: Translations(data));
}
