import 'package:element_x/features/roomdetailsedit/cubit/roomdetailsedit_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RoomDetailsEditScreen extends StatefulWidget {
  const RoomDetailsEditScreen({super.key});

  @override
  State<RoomDetailsEditScreen> createState() => _RoomDetailsEditScreenState();
}

class _RoomDetailsEditScreenState extends State<RoomDetailsEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _topic;

  @override
  void initState() {
    super.initState();
    final state = context.read<RoomDetailsEditCubit>().state;
    _name = TextEditingController(text: state.name);
    _topic = TextEditingController(text: state.topic);
  }

  @override
  void dispose() {
    _name.dispose();
    _topic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoomDetailsEditCubit, RoomDetailsEditState>(
      listenWhen: (previous, current) => current.saved && !previous.saved,
      listener: (context, state) => context.pop(),
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Edit room')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: 'Name',
                  errorText: state.error,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _topic,
                decoration: const InputDecoration(labelText: 'Topic'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.read<RoomDetailsEditCubit>().save(
                  name: _name.text,
                  topic: _topic.text,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }
}
