import 'package:element_x/core/utils/test_keys.dart';
import 'package:element_x/features/messages/cubit/thread_cubit.dart';
import 'package:element_x/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThreadScreen extends StatefulWidget {
  const ThreadScreen({super.key});

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thread')),
      body: BlocBuilder<ThreadCubit, ThreadState>(
        builder: (context, state) {
          final cubit = context.read<ThreadCubit>();
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final event in state.events)
                      MessageBubble(
                        event: event,
                        senderName: cubit.nameFor(event.senderId),
                        isMine: cubit.mine(event.senderId),
                      ),
                  ],
                ),
              ),
              SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _composer,
                        decoration: const InputDecoration(hintText: 'Reply'),
                      ),
                    ),
                    IconButton(
                      key: const Key(TestKeys.send),
                      onPressed: () {
                        cubit.send(_composer.text);
                        _composer.clear();
                      },
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
