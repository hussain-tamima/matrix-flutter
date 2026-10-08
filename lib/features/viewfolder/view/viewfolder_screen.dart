import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/viewfolder/cubit/viewfolder_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ViewFolderScreen extends StatelessWidget {
  const ViewFolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final files = context.watch<ViewFolderCubit>().state.files;
    return Scaffold(
      appBar: AppBar(title: const Text('Files')),
      body: files.isEmpty
          ? const Center(child: Text('No files in this room yet.'))
          : ListView(
              children: [
                for (final file in files)
                  ListTile(
                    leading: Icon(_icon(file.kind)),
                    title: Text(file.fileName ?? file.body),
                    subtitle: Text(file.kind.name),
                  ),
              ],
            ),
    );
  }

  IconData _icon(TimelineEventKind kind) {
    return switch (kind) {
      TimelineEventKind.image => Icons.image_outlined,
      TimelineEventKind.voice => Icons.mic_none,
      _ => Icons.insert_drive_file_outlined,
    };
  }
}
