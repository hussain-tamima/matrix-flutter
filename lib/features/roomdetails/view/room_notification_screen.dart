import 'package:element_x/features/roomdetails/cubit/roomdetails_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoomNotificationScreen extends StatelessWidget {
  const RoomNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<RoomDetailsCubit>().state.notificationMode;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RadioGroup<String>(
        groupValue: mode,
        onChanged: (value) {
          if (value != null) {
            context.read<RoomDetailsCubit>().setNotificationMode(value);
          }
        },
        child: const Column(
          children: [
            RadioListTile<String>(value: 'all', title: Text('All messages')),
            RadioListTile<String>(
              value: 'mentions',
              title: Text('Mentions and keywords'),
            ),
            RadioListTile<String>(value: 'mute', title: Text('Mute')),
          ],
        ),
      ),
    );
  }
}
