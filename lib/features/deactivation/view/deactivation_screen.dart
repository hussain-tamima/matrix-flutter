import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/deactivation/cubit/deactivation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DeactivationScreen extends StatefulWidget {
  const DeactivationScreen({super.key});

  @override
  State<DeactivationScreen> createState() => _DeactivationScreenState();
}

class _DeactivationScreenState extends State<DeactivationScreen> {
  final _password = TextEditingController();
  bool _confirmed = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeactivationCubit, DeactivationState>(
      listenWhen: (previous, current) => current.done && !previous.done,
      listener: (context, state) => context.go(RoutePaths.signedOut),
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Deactivate account')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Deactivating disables this account on the homeserver and signs this device out.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: state.error,
                ),
              ),
              CheckboxListTile(
                value: _confirmed,
                onChanged: (value) =>
                    setState(() => _confirmed = value ?? false),
                title: const Text('I understand this signs me out'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.read<DeactivationCubit>().submit(
                  password: _password.text,
                  confirmed: _confirmed,
                ),
                child: const Text('Deactivate'),
              ),
            ],
          ),
        );
      },
    );
  }
}
