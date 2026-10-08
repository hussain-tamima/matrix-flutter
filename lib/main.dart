import 'package:easy_localization/easy_localization.dart';
import 'package:element_x/app/element_app.dart';
import 'package:element_x/core/di/di.dart';
import 'package:element_x/core/settings/app_settings_cubit.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await initDependencies();
  final appSettings = sl<AppSettingsCubit>();
  await appSettings.load();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: Locale(appSettings.state.localeCode),
      child: const ElementApp(),
    ),
  );
}
