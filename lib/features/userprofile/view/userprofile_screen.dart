import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/userprofile/cubit/userprofile_cubit.dart';
import 'package:element_x/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserProfileCubit, UserProfileState>(
      listenWhen: (previous, current) =>
          current.openedRoomId != null &&
          previous.openedRoomId != current.openedRoomId,
      listener: (context, state) =>
          context.push(RoutePaths.room(state.openedRoomId!)),
      builder: (context, state) {
        final user = state.user;
        if (user == null) {
          return const Scaffold(body: Center(child: Text('User not found')));
        }
        final cubit = context.read<UserProfileCubit>();
        return Scaffold(
          appBar: AppBar(title: Text(user.displayName)),
          body: ListView(
            children: [
              const SizedBox(height: 24),
              Center(child: UserAvatar(label: user.displayName, radius: 40)),
              const SizedBox(height: 12),
              Center(child: Text(user.id)),
              if (user.statusMessage.isNotEmpty)
                Center(child: Text(user.statusMessage)),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Message'),
                onTap: cubit.message,
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: Text(state.blocked ? 'Unblock' : 'Block'),
                onTap: cubit.toggleBlock,
              ),
              ListTile(
                leading: Icon(
                  state.verified ? Icons.verified : Icons.verified_outlined,
                ),
                title: Text(
                  state.verified ? 'Session verified' : 'Verify session',
                ),
                onTap: () => context.push(RoutePaths.verify),
              ),
            ],
          ),
        );
      },
    );
  }
}
