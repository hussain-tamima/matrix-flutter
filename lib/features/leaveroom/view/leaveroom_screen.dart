import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/leaveroom/cubit/leaveroom_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LeaveRoomScreen extends StatelessWidget {
  const LeaveRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeaveRoomCubit, LeaveRoomState>(
      listenWhen: (previous, current) => current.left && !previous.left,
      listener: (context, state) => context.go(RoutePaths.home),
      child: Scaffold(
        appBar: AppBar(title: const Text('Leave room')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'You will stop receiving messages from this room. You can join again later if it is still public.',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.read<LeaveRoomCubit>().confirm(),
              child: const Text('Leave'),
            ),
          ],
        ),
      ),
    );
  }
}
