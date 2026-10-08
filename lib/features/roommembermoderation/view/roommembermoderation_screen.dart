import 'package:element_x/features/roommembermoderation/cubit/roommembermoderation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RoomMemberModerationScreen extends StatelessWidget {
  const RoomMemberModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoomMemberModerationCubit, RoomMemberModerationState>(
      listenWhen: (previous, current) => current.removed && !previous.removed,
      listener: (context, state) => context.pop(),
      builder: (context, state) {
        final cubit = context.read<RoomMemberModerationCubit>();
        return Scaffold(
          appBar: AppBar(title: Text(state.displayName)),
          body: ListView(
            children: [
              ListTile(
                title: const Text('Role'),
                subtitle: Text(state.member?.role ?? 'left'),
              ),
              RadioGroup<String>(
                groupValue: state.member?.role,
                onChanged: (value) {
                  if (value != null && state.member != null) {
                    cubit.setRole(value);
                  }
                },
                child: Column(
                  children: [
                    for (final role in const ['admin', 'moderator', 'member'])
                      RadioListTile<String>(
                        value: role,
                        title: Text(role),
                        enabled: state.member != null,
                      ),
                  ],
                ),
              ),
              ListTile(
                title: const Text('Remove from room'),
                onTap: state.member == null ? null : cubit.kick,
              ),
              ListTile(
                title: const Text('Ban'),
                onTap: state.member == null ? null : cubit.ban,
              ),
            ],
          ),
        );
      },
    );
  }
}
