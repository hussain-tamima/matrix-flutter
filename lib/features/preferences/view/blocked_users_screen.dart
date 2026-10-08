import 'package:element_x/features/preferences/cubit/preferences_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final blocked = context.watch<PreferencesCubit>().state.blocked;
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: blocked.isEmpty
          ? const Center(child: Text('You have not blocked anyone.'))
          : ListView(
              children: [
                for (final user in blocked)
                  ListTile(
                    title: Text(user.displayName),
                    subtitle: Text(user.id),
                    trailing: TextButton(
                      onPressed: () =>
                          context.read<PreferencesCubit>().unblock(user.id),
                      child: const Text('Unblock'),
                    ),
                  ),
              ],
            ),
    );
  }
}
