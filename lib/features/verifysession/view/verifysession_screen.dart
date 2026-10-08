import 'package:element_x/features/verifysession/cubit/verifysession_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VerifySessionScreen extends StatelessWidget {
  const VerifySessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VerifySessionCubit>().state;
    return Scaffold(
      appBar: AppBar(title: const Text('Verify session')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            state.verified
                ? 'This session is verified.'
                : 'Compare these numbers with your other device.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final number in state.emoji) Chip(label: Text('$number')),
            ],
          ),
          const SizedBox(height: 24),
          if (!state.verified)
            FilledButton(
              onPressed: () => context.read<VerifySessionCubit>().confirm(),
              child: const Text('They match'),
            ),
        ],
      ),
    );
  }
}
