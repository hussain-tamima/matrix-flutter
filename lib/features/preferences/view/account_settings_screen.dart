import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/preferences/cubit/preferences_cubit.dart';
import 'package:element_x/widgets/settings_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late final TextEditingController _name;
  final _pin = TextEditingController(text: '0000');

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: context.read<PreferencesCubit>().state.displayName,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PreferencesCubit>().state;
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(state.userId),
          Text(state.homeserver),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Display name'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () =>
                context.read<PreferencesCubit>().setDisplayName(_name.text),
            child: const Text('Save name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pin,
            decoration: const InputDecoration(labelText: 'App lock PIN'),
            obscureText: true,
          ),
          SwitchListTile(
            title: const Text('App lock'),
            value: state.preferences.lockScreenEnabled,
            onChanged: (value) => context.read<PreferencesCubit>().setLock(
              enabled: value,
              pin: _pin.text,
            ),
          ),
          SettingsRow(
            title: 'Deactivate account',
            onTap: () => context.push(RoutePaths.settingsDeactivate),
          ),
        ],
      ),
    );
  }
}
