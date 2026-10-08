import 'package:element_x/features/reportroom/cubit/reportroom_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ReportRoomScreen extends StatefulWidget {
  const ReportRoomScreen({super.key});

  @override
  State<ReportRoomScreen> createState() => _ReportRoomScreenState();
}

class _ReportRoomScreenState extends State<ReportRoomScreen> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportRoomCubit, ReportRoomState>(
      listenWhen: (previous, current) =>
          current.submitted && !previous.submitted,
      listener: (context, state) => context.pop(),
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Report room')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Reports are stored on this device in the demo. A live client would send them to the room moderators.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reason,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  errorText: state.error,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    context.read<ReportRoomCubit>().submit(_reason.text),
                child: const Text('Submit report'),
              ),
            ],
          ),
        );
      },
    );
  }
}
