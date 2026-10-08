import 'package:element_x/features/analytics/cubit/analytics_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AnalyticsSettingsScreen extends StatelessWidget {
  const AnalyticsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final enabled = context.watch<AnalyticsCubit>().state.enabled;
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SwitchListTile(
        title: const Text('Share anonymous usage data'),
        subtitle: const Text('Off by default. Nothing is sent in this demo.'),
        value: enabled,
        onChanged: context.read<AnalyticsCubit>().setEnabled,
      ),
    );
  }
}
