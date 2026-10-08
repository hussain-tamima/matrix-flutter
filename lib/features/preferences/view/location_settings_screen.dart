import 'package:element_x/features/preferences/cubit/preferences_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LocationSettingsScreen extends StatelessWidget {
  const LocationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<PreferencesCubit>().state.preferences;
    return Scaffold(
      appBar: AppBar(title: const Text('Location')),
      body: SwitchListTile(
        title: const Text('Allow location sharing'),
        value: preferences.locationSharingEnabled,
        onChanged: (value) => context.read<PreferencesCubit>().update(
          preferences.copyWith(locationSharingEnabled: value),
        ),
      ),
    );
  }
}
