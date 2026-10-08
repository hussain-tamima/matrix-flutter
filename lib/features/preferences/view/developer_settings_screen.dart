import 'package:element_x/features/preferences/cubit/preferences_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeveloperSettingsScreen extends StatelessWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<PreferencesCubit>().state.preferences;
    final cubit = context.read<PreferencesCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Developer options')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Developer mode'),
            value: preferences.developerMode,
            onChanged: (value) =>
                cubit.update(preferences.copyWith(developerMode: value)),
          ),
          SwitchListTile(
            title: const Text('Show hidden events'),
            value: preferences.showHiddenEvents,
            onChanged: preferences.developerMode
                ? (value) => cubit.update(
                    preferences.copyWith(showHiddenEvents: value),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
