import 'package:easy_localization/easy_localization.dart';
import 'package:element_x/core/matrix/matrix_error.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/roomdirectory/cubit/roomdirectory_cubit.dart';
import 'package:element_x/theme/rop_spacing.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:element_x/widgets/form_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RoomDirectoryScreen extends StatelessWidget {
  const RoomDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoomDirectoryCubit, RoomDirectoryState>(
      listenWhen: (previous, current) =>
          current.completed != previous.completed,
      listener: (context, state) {
        final roomId = state.joinedRoomId;
        if (roomId != null) context.push(RoutePaths.room(roomId));
      },
      builder: (context, state) {
        final rop = RopTheme.of(context);
        return Scaffold(
          appBar: AppBar(title: Text('room_directory'.tr())),
          body: Align(
            alignment: AlignmentDirectional.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: RopSpacing.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.loading && state.rooms.isNotEmpty)
                    const LinearProgressIndicator(minHeight: 2),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        RopSpacing.md,
                        RopSpacing.md,
                        RopSpacing.md,
                        0,
                      ),
                      child: FormNotice(message: userFacingError(state.error!)),
                    ),
                  Expanded(
                    child: _DirectoryBody(state: state, rop: rop),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DirectoryBody extends StatelessWidget {
  const _DirectoryBody({required this.state, required this.rop});

  final RoomDirectoryState state;
  final RopTheme rop;

  @override
  Widget build(BuildContext context) {
    if (state.loading && state.rooms.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.rooms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(RopSpacing.xl),
          child: Text(
            'directory_empty'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: rop.textSecondary, height: 1.4),
          ),
        ),
      );
    }
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: RopSpacing.sm),
      itemCount: state.rooms.length,
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsetsDirectional.only(
          start: RopSpacing.md + 40 + RopSpacing.sm,
        ),
        child: Divider(height: 1, thickness: 1, color: rop.separatorSubtle),
      ),
      itemBuilder: (context, index) {
        final room = state.rooms[index];
        return _DirectoryRoom(
          room: room,
          busy: state.joiningId != null,
          joining: state.joiningId == room.id,
        );
      },
    );
  }
}

class _DirectoryRoom extends StatelessWidget {
  const _DirectoryRoom({
    required this.room,
    required this.busy,
    required this.joining,
  });

  final MatrixRoom room;
  final bool busy;
  final bool joining;

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    final name = room.name.trim().isEmpty
        ? (room.alias.isEmpty ? room.id : room.alias)
        : room.name.trim();
    final detail = room.topic.trim().isNotEmpty
        ? room.topic.trim()
        : room.alias.trim();
    final members = _membersLabel(room.memberIds.length);
    final subtitle = [
      if (room.isSpace) 'directory_space'.tr(),
      if (detail.isNotEmpty) detail,
      ?members,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: RopSpacing.md,
        vertical: RopSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Glyph(room.isSpace ? Icons.workspaces_outlined : Icons.tag),
          const SizedBox(width: RopSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: rop.textSecondary, height: 1.35),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: RopSpacing.sm),
          joining
              ? const SizedBox.square(
                  dimension: 44,
                  child: Center(
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  ),
                )
              : FilledButton(
                  onPressed: busy
                      ? null
                      : () => context.read<RoomDirectoryCubit>().join(room.id),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: RopSpacing.md,
                    ),
                  ),
                  child: Text('join_room_action'.tr()),
                ),
        ],
      ),
    );
  }
}

String? _membersLabel(int count) {
  if (count <= 0) return null;
  if (count == 1) return 'directory_member_one'.tr();
  return 'directory_member_many'.tr(args: ['$count']);
}

class _Glyph extends StatelessWidget {
  const _Glyph(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: rop.selectionTint,
          borderRadius: BorderRadius.circular(RopSpacing.controlRadius),
        ),
        child: SizedBox.square(
          dimension: 40,
          child: Icon(icon, color: rop.textLink, size: 22),
        ),
      ),
    );
  }
}
