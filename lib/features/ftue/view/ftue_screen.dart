import 'package:element_x/features/ftue/cubit/ftue_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class FtueScreen extends StatelessWidget {
  const FtueScreen({super.key});

  static const _pages = [
    (
      Icons.lock_outline,
      'Encryption',
      'Rooms are encrypted on your device. Set up a recovery key before you sign out.',
    ),
    (
      Icons.notifications_none,
      'Notifications',
      'Choose whether Element notifies you for every message or only mentions.',
    ),
    (
      Icons.people_outline,
      'People',
      'Start a direct chat or create a room from the home screen.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FtueCubit, FtueState>(
      listenWhen: (previous, current) => current.done && !previous.done,
      listener: (context, state) => context.pop(),
      builder: (context, state) {
        final page = _pages[state.page];
        final last = state.page == FtueCubit.pageCount - 1;
        return Scaffold(
          appBar: AppBar(title: const Text('Get started')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(page.$1, size: 72),
              const SizedBox(height: 16),
              Text(page.$2, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(page.$3),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => last
                    ? context.read<FtueCubit>().finish()
                    : context.read<FtueCubit>().next(),
                child: Text(last ? 'Done' : 'Next'),
              ),
            ],
          ),
        );
      },
    );
  }
}
