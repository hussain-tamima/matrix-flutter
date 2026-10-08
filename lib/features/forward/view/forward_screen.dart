import 'package:element_x/features/forward/cubit/forward_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ForwardScreen extends StatelessWidget {
  const ForwardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForwardCubit, ForwardState>(
      listenWhen: (previous, current) =>
          current.sentTo != null && previous.sentTo != current.sentTo,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Message forwarded')));
        context.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Forward')),
        body: BlocBuilder<ForwardCubit, ForwardState>(
          builder: (context, state) {
            return ListView(
              children: [
                if (state.event != null)
                  ListTile(
                    title: const Text('Message'),
                    subtitle: Text(state.event!.body),
                  ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Text(
                      state.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (state.sending) const LinearProgressIndicator(),
                for (final room in state.rooms)
                  ListTile(
                    title: Text(room.name),
                    enabled: !state.sending,
                    onTap: () => context.read<ForwardCubit>().send(room.id),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
