import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/migration/cubit/migration_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MigrationScreen extends StatelessWidget {
  const MigrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final summary = context.watch<MigrationCubit>().state.summary;
    return Scaffold(
      appBar: AppBar(title: const Text('Element Classic')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(summary),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go(RoutePaths.loginPassword),
            child: const Text('Continue to sign in'),
          ),
        ],
      ),
    );
  }
}
