import 'package:easy_localization/easy_localization.dart';
import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/theme/rop_spacing.dart';
import 'package:element_x/widgets/app_preference_controls.dart';
import 'package:element_x/widgets/settings_row.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings_title'.tr())),
      body: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: RopSpacing.contentMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const AppPreferenceControls(),
              _SectionLabel('settings_section_account'.tr()),
              SettingsRow(
                icon: Icons.person_outline,
                title: 'settings_account'.tr(),
                onTap: () => context.push(RoutePaths.settingsAccount),
              ),
              SettingsRow(
                icon: Icons.notifications_outlined,
                title: 'settings_notifications'.tr(),
                onTap: () => context.push(RoutePaths.settingsNotifications),
              ),
              SettingsRow(
                icon: Icons.shield_outlined,
                title: 'settings_security'.tr(),
                onTap: () => context.push(RoutePaths.settingsSecurity),
              ),
              SettingsRow(
                icon: Icons.block_outlined,
                title: 'settings_blocked'.tr(),
                onTap: () => context.push(RoutePaths.settingsBlocked),
              ),
              _SectionLabel('settings_section_communication'.tr()),
              SettingsRow(
                icon: Icons.perm_media_outlined,
                title: 'settings_media'.tr(),
                onTap: () => context.push(RoutePaths.settingsMedia),
              ),
              SettingsRow(
                icon: Icons.location_on_outlined,
                title: 'settings_location'.tr(),
                onTap: () => context.push(RoutePaths.settingsLocation),
              ),
              SettingsRow(
                icon: Icons.admin_panel_settings_outlined,
                title: 'settings_moderation'.tr(),
                onTap: () => context.push(RoutePaths.settingsModeration),
              ),
              SettingsRow(
                icon: Icons.document_scanner_outlined,
                title: 'settings_scanner'.tr(),
                onTap: () => context.push(RoutePaths.settingsScanner),
              ),
              _SectionLabel('settings_section_app'.tr()),
              SettingsRow(
                icon: Icons.science_outlined,
                title: 'settings_labs'.tr(),
                onTap: () => context.push(RoutePaths.settingsLabs),
              ),
              SettingsRow(
                icon: Icons.code_outlined,
                title: 'settings_developer'.tr(),
                onTap: () => context.push(RoutePaths.settingsDeveloper),
              ),
              SettingsRow(
                icon: Icons.analytics_outlined,
                title: 'settings_analytics'.tr(),
                onTap: () => context.push(RoutePaths.settingsAnalytics),
              ),
              SettingsRow(
                icon: Icons.cleaning_services_outlined,
                title: 'settings_cache'.tr(),
                onTap: () => context.push(RoutePaths.settingsCache),
              ),
              SettingsRow(
                icon: Icons.network_check,
                title: 'settings_network'.tr(),
                onTap: () => context.push(RoutePaths.network),
              ),
              SettingsRow(
                icon: Icons.business_outlined,
                title: 'settings_enterprise'.tr(),
                onTap: () => context.push(RoutePaths.settingsEnterprise),
              ),
              SettingsRow(
                icon: Icons.info_outline,
                title: 'settings_about'.tr(),
                onTap: () => context.push(RoutePaths.settingsAbout),
              ),
              SettingsRow(
                icon: Icons.description_outlined,
                title: 'settings_licenses'.tr(),
                onTap: () => context.push(RoutePaths.licenses),
              ),
              SettingsRow(
                icon: Icons.bug_report_outlined,
                title: 'report_bug'.tr(),
                onTap: () => context.push(RoutePaths.bugReport),
              ),
              const Divider(),
              SettingsRow(
                icon: Icons.logout,
                title: 'sign_out'.tr(),
                onTap: () => context.push(RoutePaths.logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 28, 16, 8),
      child: Text(label, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
