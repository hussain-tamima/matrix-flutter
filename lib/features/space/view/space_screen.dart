import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/space/cubit/space_cubit.dart';
import 'package:element_x/widgets/room_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SpaceScreen extends StatelessWidget {
  const SpaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpaceCubit, SpaceState>(
      builder: (context, state) {
        final summary = state.summary;
        return Scaffold(
          appBar: AppBar(title: Text(summary?.name ?? 'Space')),
          body: ListView(
            children: [
              if (summary != null)
                ListTile(
                  title: Text(summary.topic.isEmpty ? 'Space' : summary.topic),
                  subtitle: Text('${summary.roomCount} rooms'),
                ),
              for (final room in state.rooms)
                RoomTile(
                  room: room,
                  onTap: () => context.push(RoutePaths.room(room.id)),
                ),
              if (state.rooms.isEmpty)
                const ListTile(title: Text('This space has no rooms yet.')),
            ],
          ),
        );
      },
    );
  }
}
