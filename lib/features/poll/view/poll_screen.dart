import 'package:element_x/features/poll/cubit/poll_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PollScreen extends StatefulWidget {
  const PollScreen({super.key});

  @override
  State<PollScreen> createState() => _PollScreenState();
}

class _PollScreenState extends State<PollScreen> {
  final _question = TextEditingController();
  final _first = TextEditingController();
  final _second = TextEditingController();

  @override
  void dispose() {
    _question.dispose();
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PollCubit, PollState>(
      listenWhen: (previous, current) => current.created && !previous.created,
      listener: (context, state) => context.pop(),
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Create poll')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                controller: _question,
                decoration: InputDecoration(
                  labelText: 'Question',
                  errorText: state.error,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _first,
                decoration: const InputDecoration(labelText: 'Option 1'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _second,
                decoration: const InputDecoration(labelText: 'Option 2'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.read<PollCubit>().create(
                  question: _question.text,
                  first: _first.text,
                  second: _second.text,
                ),
                child: const Text('Create poll'),
              ),
            ],
          ),
        );
      },
    );
  }
}
