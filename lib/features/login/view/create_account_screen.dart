import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/login/cubit/login_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _displayName = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: BlocBuilder<LoginCubit, LoginState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Homeserver ${state.homeserver}'),
              const SizedBox(height: 16),
              TextField(
                controller: _displayName,
                decoration: InputDecoration(
                  labelText: 'Display name',
                  errorText: state.displayNameError,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _username,
                decoration: InputDecoration(
                  labelText: 'Username',
                  errorText: state.usernameError,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: state.passwordError,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: state.submitting
                    ? null
                    : () async {
                        final opened = await context
                            .read<LoginCubit>()
                            .createAccount(
                              displayName: _displayName.text,
                              username: _username.text,
                              password: _password.text,
                            );
                        if (opened && context.mounted) {
                          context.go(RoutePaths.home);
                        }
                      },
                child: const Text('Create account'),
              ),
            ],
          );
        },
      ),
    );
  }
}
