import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/core/utils/test_keys.dart';
import 'package:element_x/features/login/cubit/login_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ChooseAccountProviderScreen extends StatefulWidget {
  const ChooseAccountProviderScreen({super.key});

  @override
  State<ChooseAccountProviderScreen> createState() =>
      _ChooseAccountProviderScreenState();
}

class _ChooseAccountProviderScreenState
    extends State<ChooseAccountProviderScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<LoginCubit>().state.homeserver,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a server')),
      body: BlocBuilder<LoginCubit, LoginState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Enter the homeserver that hosts your account.'),
              const SizedBox(height: 16),
              TextField(
                key: const Key(TestKeys.homeserver),
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Homeserver',
                  errorText: state.homeserverError,
                ),
                onChanged: context.read<LoginCubit>().setHomeserver,
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key(TestKeys.continueProvider),
                onPressed: () {
                  context.read<LoginCubit>().setHomeserver(_controller.text);
                  if (context.read<LoginCubit>().confirmHomeserver()) {
                    context.push(RoutePaths.loginConfirm);
                  }
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      ),
    );
  }
}
