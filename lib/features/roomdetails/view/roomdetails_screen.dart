import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/roomdetails/cubit/roomdetails_cubit.dart';
import 'package:element_x/widgets/settings_row.dart';
import 'package:element_x/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RoomDetailsScreen extends StatelessWidget {
  const RoomDetailsScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomDetailsCubit, RoomDetailsState>(
      builder: (context, state) {
        final room = state.room;
        if (state.missing || room == null) {
          return const Scaffold(body: Center(child: Text('Room not found')));
        }
        final cubit = context.read<RoomDetailsCubit>();
        return Scaffold(
          appBar: AppBar(title: Text(room.name)),
          body: ListView(
            children: [
              ListTile(
                leading: UserAvatar(label: room.name, radius: 28),
                title: Text(room.name),
                subtitle: Text(room.topic.isEmpty ? room.id : room.topic),
              ),
              SettingsRow(
                title: room.isEncrypted ? 'Encrypted' : 'Not encrypted',
                subtitle: room.isDirect ? 'Direct chat' : 'Room',
              ),
              SwitchListTile(
                title: const Text('Favourite'),
                value: room.isFavourite,
                onChanged: cubit.setFavourite,
              ),
              SettingsRow(
                title: 'Notifications',
                subtitle: state.notificationMode,
                onTap: () => context.push(RoutePaths.roomNotifications(roomId)),
              ),
              SettingsRow(
                title: 'People',
                subtitle: '${state.members.length} members',
              ),
              for (final member in state.members)
                ListTile(
                  leading: UserAvatar(label: cubit.nameFor(member.userId)),
                  title: Text(cubit.nameFor(member.userId)),
                  subtitle: Text(member.role),
                  onTap: () => context.push(RoutePaths.user(member.userId)),
                  trailing: IconButton(
                    tooltip: 'Moderate',
                    onPressed: () => context.push(
                      RoutePaths.moderate(roomId, member.userId),
                    ),
                    icon: const Icon(Icons.more_horiz),
                  ),
                ),
              SettingsRow(
                title: 'Invite',
                onTap: () => context.push(RoutePaths.roomInvite(roomId)),
              ),
              SettingsRow(
                title: 'Knock requests',
                subtitle: '${state.knockCount}',
                onTap: () => context.push(RoutePaths.roomKnocks(roomId)),
              ),
              SettingsRow(
                title: 'Roles and permissions',
                onTap: () => context.push(RoutePaths.roomRoles(roomId)),
              ),
              SettingsRow(
                title: 'Files',
                onTap: () => context.push(RoutePaths.roomFiles(roomId)),
              ),
              SettingsRow(
                title: 'Edit details',
                onTap: () => context.push(RoutePaths.roomEdit(roomId)),
              ),
              SettingsRow(
                title: state.reported ? 'Reported' : 'Report room',
                onTap: state.reported
                    ? null
                    : () => context.push(RoutePaths.roomReport(roomId)),
              ),
              SettingsRow(
                title: 'Leave room',
                onTap: () => context.push(RoutePaths.roomLeave(roomId)),
              ),
            ],
          ),
        );
      },
    );
  }
}
