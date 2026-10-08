import 'package:element_x/features/lockscreen/cubit/lockscreen_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LockscreenScreen extends StatefulWidget {
  const LockscreenScreen({super.key});

  @override
  State<LockscreenScreen> createState() => _LockscreenScreenState();
}

class _LockscreenScreenState extends State<LockscreenScreen> {
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App lock')),
      body: BlocBuilder<LockscreenCubit, LockscreenState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.fingerprint, size: 72),
              const SizedBox(height: 16),
              const Text(
                'Enter the PIN you set in Settings to unlock Element.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pin,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'PIN',
                  errorText: state.error,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () =>
                    context.read<LockscreenCubit>().submit(_pin.text),
                child: const Text('Unlock'),
              ),
            ],
          );
        },
      ),
    );
  }
}
