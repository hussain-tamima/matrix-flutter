import 'package:element_x/features/preferences/cubit/preferences_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MediaSettingsScreen extends StatelessWidget {
  const MediaSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<PreferencesCubit>().state.preferences;
    return Scaffold(
      appBar: AppBar(title: const Text('Media')),
      body: SwitchListTile(
        title: const Text('Auto-load images'),
        value: preferences.mediaAutoLoad,
        onChanged: (value) => context.read<PreferencesCubit>().update(
          preferences.copyWith(mediaAutoLoad: value),
        ),
      ),
    );
  }
}
