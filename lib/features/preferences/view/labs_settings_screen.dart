import 'package:element_x/features/preferences/cubit/preferences_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LabsSettingsScreen extends StatelessWidget {
  const LabsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<PreferencesCubit>().state.preferences;
    final cubit = context.read<PreferencesCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Labs')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Threads'),
            value: preferences.labsThreads,
            onChanged: (value) =>
                cubit.update(preferences.copyWith(labsThreads: value)),
          ),
          SwitchListTile(
            title: const Text('Rich text composer'),
            subtitle: const Text('Demo toggle. The composer stays plain text.'),
            value: preferences.labsRichText,
            onChanged: (value) =>
                cubit.update(preferences.copyWith(labsRichText: value)),
          ),
        ],
      ),
    );
  }
}
