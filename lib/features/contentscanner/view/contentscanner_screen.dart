import 'package:element_x/features/contentscanner/cubit/contentscanner_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContentScannerScreen extends StatelessWidget {
  const ContentScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final enabled = context.watch<ContentScannerCubit>().state.enabled;
    return Scaffold(
      appBar: AppBar(title: const Text('Content scanner')),
      body: SwitchListTile(
        title: const Text('Scan media before opening'),
        subtitle: const Text(
          'A live client would send files to your homeserver’s scanner.',
        ),
        value: enabled,
        onChanged: context.read<ContentScannerCubit>().setEnabled,
      ),
    );
  }
}
