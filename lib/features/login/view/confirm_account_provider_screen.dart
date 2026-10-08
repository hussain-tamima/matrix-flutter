import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/core/utils/test_keys.dart';
import 'package:element_x/features/login/cubit/login_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ConfirmAccountProviderScreen extends StatelessWidget {
  const ConfirmAccountProviderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeserver = context.watch<LoginCubit>().state.homeserver;
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm server')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'You are signing in to',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(homeserver, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const Text(
            'Element will use this server for your account and encrypted history.',
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key(TestKeys.confirmProvider),
            onPressed: () => context.push(RoutePaths.loginPassword),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
