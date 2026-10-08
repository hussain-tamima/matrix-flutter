import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/roomcall/cubit/roomcall_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RoomCallScreen extends StatelessWidget {
  const RoomCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoomCallCubit, RoomCallState>(
      listenWhen: (previous, current) => current.started && !previous.started,
      listener: (context, state) => context.push(RoutePaths.call),
      child: Builder(
        builder: (context) {
          final error = context.watch<RoomCallCubit>().state.error;
          return Scaffold(
            appBar: AppBar(title: const Text('Call')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(error),
                    ),
                  FilledButton(
                    onPressed: () => context.read<RoomCallCubit>().start(),
                    child: const Text('Voice call'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () =>
                        context.read<RoomCallCubit>().start(video: true),
                    child: const Text('Video call'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
