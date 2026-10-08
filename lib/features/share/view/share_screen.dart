import 'package:element_x/features/share/cubit/share_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: context.read<ShareCubit>().state.text);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ShareCubit, ShareState>(
      listenWhen: (previous, current) => current.sent && !previous.sent,
      listener: (context, state) => context.pop(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Share')),
        body: BlocBuilder<ShareCubit, ShareState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _text,
                  decoration: const InputDecoration(labelText: 'Shared text'),
                  onChanged: context.read<ShareCubit>().updateText,
                ),
                const SizedBox(height: 12),
                const Text('Send to'),
                for (final room in state.rooms)
                  ListTile(
                    title: Text(room.name),
                    onTap: () => context.read<ShareCubit>().send(room.id),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
