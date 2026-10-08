import 'package:element_x/features/securebackup/cubit/securebackup_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SecureBackupScreen extends StatefulWidget {
  const SecureBackupScreen({super.key});

  @override
  State<SecureBackupScreen> createState() => _SecureBackupScreenState();
}

class _SecureBackupScreenState extends State<SecureBackupScreen> {
  final _key = TextEditingController();

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secure backup')),
      body: BlocBuilder<SecureBackupCubit, SecureBackupState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                state.enabled ? 'Backup is on for this session.' : 'Store a recovery key so a new device can restore encrypted history.',
              ),
              if (state.recoveryKey != null) ...[
                const SizedBox(height: 12),
                SelectableText(state.recoveryKey!),
              ],
              if (!state.enabled) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _key,
                  decoration: InputDecoration(
                    labelText: 'Recovery key',
                    errorText: state.error,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      context.read<SecureBackupCubit>().enable(_key.text),
                  child: const Text('Enable backup'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
