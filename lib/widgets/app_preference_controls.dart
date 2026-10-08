import 'package:easy_localization/easy_localization.dart';
import 'package:element_x/core/di/di.dart';
import 'package:element_x/core/settings/app_settings_cubit.dart';
import 'package:element_x/core/settings/app_settings_state.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Theme and language controls for onboarding and settings.
class AppPreferenceControls extends StatelessWidget {
  const AppPreferenceControls({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      bloc: sl<AppSettingsCubit>(),
      builder: (context, settings) {
        if (compact) {
          return _CompactControls(settings: settings);
        }
        return _ExpandedControls(settings: settings);
      },
    );
  }
}

class _CompactControls extends StatelessWidget {
  const _CompactControls({required this.settings});

  final AppSettingsState settings;

  @override
  Widget build(BuildContext context) {
    final cubit = sl<AppSettingsCubit>();
    final onPrimary = RopTheme.of(context).textOnPrimary;
    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ToggleButtons(
            isSelected: [
              settings.localeCode == 'en',
              settings.localeCode == 'ar',
            ],
            onPressed: (index) => cubit.setLocaleCode(index == 0 ? 'en' : 'ar'),
            borderRadius: BorderRadius.circular(8),
            constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
            borderColor: onPrimary.withValues(alpha: 0.5),
            selectedBorderColor: onPrimary,
            fillColor: onPrimary.withValues(alpha: 0.2),
            selectedColor: onPrimary,
            color: onPrimary.withValues(alpha: 0.85),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('EN'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('ع'),
              ),
            ],
          ),
          PopupMenuButton<ThemeMode>(
            tooltip: 'settings_theme'.tr(),
            initialValue: settings.themeMode,
            onSelected: cubit.setThemeMode,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ThemeMode.system,
                child: Text('settings_theme_system'.tr()),
              ),
              PopupMenuItem(
                value: ThemeMode.light,
                child: Text('settings_theme_light_label'.tr()),
              ),
              PopupMenuItem(
                value: ThemeMode.dark,
                child: Text('settings_theme_dark_label'.tr()),
              ),
            ],
            icon: Icon(switch (settings.themeMode) {
              ThemeMode.system => Icons.brightness_auto_outlined,
              ThemeMode.light => Icons.light_mode_outlined,
              ThemeMode.dark => Icons.dark_mode_outlined,
            }),
            iconColor: onPrimary,
          ),
        ],
      ),
    );
  }
}

class _ExpandedControls extends StatelessWidget {
  const _ExpandedControls({required this.settings});

  final AppSettingsState settings;

  @override
  Widget build(BuildContext context) {
    final cubit = sl<AppSettingsCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'settings_appearance'.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'settings_theme_hint'.tr(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        SegmentedButton<ThemeMode>(
          segments: [
            ButtonSegment(
              value: ThemeMode.system,
              icon: const Icon(Icons.brightness_auto_outlined),
              label: Text('settings_theme_system'.tr()),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              icon: const Icon(Icons.light_mode_outlined),
              label: Text('settings_theme_light_label'.tr()),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: const Icon(Icons.dark_mode_outlined),
              label: Text('settings_theme_dark_label'.tr()),
            ),
          ],
          selected: {settings.themeMode},
          onSelectionChanged: (selection) =>
              cubit.setThemeMode(selection.first),
        ),
        const SizedBox(height: 8),
        Text(
          'settings_language'.tr(),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _LanguageToggle(
          localeCode: settings.localeCode,
          onChanged: cubit.setLocaleCode,
        ),
      ],
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.localeCode, required this.onChanged});

  final String localeCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'en', label: Text('settings_language_en'.tr())),
        ButtonSegment(value: 'ar', label: Text('settings_language_ar'.tr())),
      ],
      selected: {localeCode},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
