import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/securityandprivacy/cubit/securityandprivacy_cubit.dart';
import 'package:element_x/widgets/settings_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SecurityAndPrivacyScreen extends StatelessWidget {
  const SecurityAndPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SecurityAndPrivacyCubit>().state;
    return Scaffold(
      appBar: AppBar(title: const Text('Security and privacy')),
      body: ListView(
        children: [
          SettingsRow(
            title: 'Secure backup',
            subtitle: state.preferences.secureBackupEnabled ? 'On' : 'Off',
            onTap: () => context.push(RoutePaths.secureBackup),
          ),
          SettingsRow(
            title: 'Session verification',
            subtitle: state.preferences.sessionVerified
                ? 'Verified'
                : 'Not verified',
            onTap: () => context.push(RoutePaths.verify),
          ),
          SettingsRow(
            title: 'Link a new device',
            onTap: () => context.push(RoutePaths.linkDevice),
          ),
          const Divider(),
          const ListTile(title: Text('Devices')),
          for (final device in state.devices)
            ListTile(
              leading: Icon(
                device.verified ? Icons.verified_user : Icons.devices_other,
              ),
              title: Text(device.name),
              subtitle: Text(device.current ? 'This device' : device.id),
            ),
        ],
      ),
    );
  }
}
