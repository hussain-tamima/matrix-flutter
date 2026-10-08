import 'package:element_x/features/preferences/cubit/preferences_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<PreferencesCubit>().state.preferences;
    final cubit = context.read<PreferencesCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable notifications'),
            value: preferences.notificationsEnabled,
            onChanged: (value) =>
                cubit.update(preferences.copyWith(notificationsEnabled: value)),
          ),
          SwitchListTile(
            title: const Text('Send read receipts'),
            value: preferences.sendReadReceipts,
            onChanged: (value) =>
                cubit.update(preferences.copyWith(sendReadReceipts: value)),
          ),
        ],
      ),
    );
  }
}
