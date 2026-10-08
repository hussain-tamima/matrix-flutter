import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/invite/cubit/invite_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class InviteScreen extends StatelessWidget {
  const InviteScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    final room = context.watch<InviteCubit>().state.room;
    final address = room == null
        ? roomId
        : room.alias.isEmpty
        ? room.id
        : room.alias;
    return Scaffold(
      appBar: AppBar(title: const Text('Invite')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            room?.name ?? 'Room',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Share this address so people can join.'),
          const SizedBox(height: 12),
          SelectableText(address),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.push(RoutePaths.invitePeople(roomId)),
            child: const Text('Invite people'),
          ),
        ],
      ),
    );
  }
}
