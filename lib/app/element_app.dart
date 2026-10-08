import 'package:easy_localization/easy_localization.dart';
import 'package:element_x/app/call_navigator.dart';
import 'package:element_x/core/di/di.dart';
import 'package:element_x/core/settings/app_settings_cubit.dart';
import 'package:element_x/core/settings/app_settings_state.dart';
import 'package:element_x/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ElementApp extends StatelessWidget {
  const ElementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppSettingsCubit, AppSettingsState>(
      bloc: sl<AppSettingsCubit>(),
      listenWhen: (previous, current) =>
          previous.localeCode != current.localeCode,
      listener: (context, state) {
        final locale = Locale(state.localeCode);
        if (context.locale != locale) {
          context.setLocale(locale);
        }
      },
      child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
        bloc: sl<AppSettingsCubit>(),
        builder: (context, settings) {
          final useInter = settings.localeCode != 'ar';
          return MaterialApp.router(
            title: 'app_name'.tr(),
            theme: AppTheme.light(useInter: useInter),
            darkTheme: AppTheme.dark(useInter: useInter),
            themeMode: settings.themeMode,
            builder: (context, child) =>
                CallNavigator(child: child ?? const SizedBox.shrink()),
            routerConfig: sl<GoRouter>(),
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
          );
        },
      ),
    );
  }
}
