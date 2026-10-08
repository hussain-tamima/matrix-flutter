import 'package:element_x/features/rageshake/cubit/rageshake_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RageshakeScreen extends StatefulWidget {
  const RageshakeScreen({super.key});

  @override
  State<RageshakeScreen> createState() => _RageshakeScreenState();
}

class _RageshakeScreenState extends State<RageshakeScreen> {
  final _description = TextEditingController();

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report a bug')),
      body: BlocBuilder<RageshakeCubit, RageshakeState>(
        builder: (context, state) {
          if (state.sent) {
            return const Center(
              child: Text('Thanks. The report was saved on this device.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                controller: _description,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'What went wrong?',
                  errorText: state.error,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    context.read<RageshakeCubit>().submit(_description.text),
                child: const Text('Send'),
              ),
            ],
          );
        },
      ),
    );
  }
}
