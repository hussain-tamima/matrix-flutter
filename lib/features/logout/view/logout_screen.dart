import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/core/utils/test_keys.dart';
import 'package:element_x/features/logout/cubit/logout_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LogoutCubit, LogoutState>(
      listenWhen: (previous, current) => current.done && !previous.done,
      listener: (context, state) => context.go(RoutePaths.signedOut),
      child: Scaffold(
        appBar: AppBar(title: const Text('Sign out')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Signing out removes the session from this device. Encrypted history stays on the homeserver if you have a recovery key.',
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key(TestKeys.signOut),
              onPressed: () => context.read<LogoutCubit>().confirm(),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
