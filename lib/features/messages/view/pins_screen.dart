import 'package:element_x/features/messages/cubit/pins_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PinsScreen extends StatelessWidget {
  const PinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pinned messages')),
      body: BlocBuilder<PinsCubit, PinsState>(
        builder: (context, state) {
          if (state.events.isEmpty) {
            return const Center(child: Text('No pinned messages'));
          }
          return ListView(
            children: [
              for (final event in state.events)
                ListTile(
                  title: Text(event.body),
                  subtitle: Text(
                    context.read<PinsCubit>().nameFor(event.senderId),
                  ),
                  trailing: IconButton(
                    tooltip: 'Unpin',
                    onPressed: () => context.read<PinsCubit>().unpin(event),
                    icon: const Icon(Icons.push_pin),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
