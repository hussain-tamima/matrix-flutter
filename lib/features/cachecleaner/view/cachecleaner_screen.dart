import 'package:element_x/features/cachecleaner/cubit/cachecleaner_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CacheCleanerScreen extends StatelessWidget {
  const CacheCleanerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bytes = context.watch<CacheCleanerCubit>().state.bytes;
    final megabytes = (bytes / (1024 * 1024)).toStringAsFixed(1);
    return Scaffold(
      appBar: AppBar(title: const Text('Clear cache')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Cached media uses $megabytes MB.'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: bytes == 0
                ? null
                : () => context.read<CacheCleanerCubit>().clear(),
            child: const Text('Clear cache'),
          ),
        ],
      ),
    );
  }
}
