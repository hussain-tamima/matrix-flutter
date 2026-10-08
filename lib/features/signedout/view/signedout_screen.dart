import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/signedout/cubit/signedout_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SignedOutScreen extends StatelessWidget {
  const SignedOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final message = context.watch<SignedOutCubit>().state.message;
    return Scaffold(
      appBar: AppBar(title: const Text('Signed out')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.lock_outline, size: 64),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go(RoutePaths.login),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}
