import 'package:element_x/features/networkmonitor/cubit/networkmonitor_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NetworkMonitorScreen extends StatelessWidget {
  const NetworkMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final online = context.watch<NetworkMonitorCubit>().state.online;
    return Scaffold(
      appBar: AppBar(title: const Text('Network')),
      body: SwitchListTile(
        title: Text(online ? 'Online' : 'Offline'),
        subtitle: const Text(
          'Demo switch. A live client follows the device connection.',
        ),
        value: online,
        onChanged: context.read<NetworkMonitorCubit>().setOnline,
      ),
    );
  }
}
