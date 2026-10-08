import 'package:element_x/features/knockrequests/cubit/knockrequests_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class KnockRequestsScreen extends StatelessWidget {
  const KnockRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Knock requests')),
      body: BlocBuilder<KnockRequestsCubit, KnockRequestsState>(
        builder: (context, state) {
          if (state.requests.isEmpty) {
            return const Center(child: Text('No one is waiting to join.'));
          }
          final cubit = context.read<KnockRequestsCubit>();
          return ListView(
            children: [
              for (final request in state.requests)
                ListTile(
                  title: Text(cubit.nameFor(request.userId)),
                  subtitle: Text(request.reason),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => cubit.decline(request),
                        child: const Text('Decline'),
                      ),
                      FilledButton(
                        onPressed: () => cubit.accept(request),
                        child: const Text('Accept'),
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
