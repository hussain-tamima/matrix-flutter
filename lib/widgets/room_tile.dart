import 'package:easy_localization/easy_localization.dart';
import 'package:element_x/core/matrix/matrix_error.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/core/matrix/room_preview.dart';
import 'package:element_x/core/utils/formatters.dart';
import 'package:element_x/core/utils/test_keys.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:element_x/widgets/user_avatar.dart';
import 'package:flutter/material.dart';

class RoomTile extends StatelessWidget {
  const RoomTile({
    super.key,
    required this.room,
    required this.onTap,
    this.onAccept,
    this.onDecline,
  });

  final MatrixRoom room;
  final VoidCallback onTap;
  final Future<void> Function()? onAccept;
  final Future<void> Function()? onDecline;

  @override
  Widget build(BuildContext context) {
    if (room.isInvited) {
      return _InviteTile(room: room, onAccept: onAccept, onDecline: onDecline);
    }
    final rop = RopTheme.of(context);
    return ListTile(
      key: Key(TestKeys.roomTile(room.id)),
      onTap: onTap,
      leading: UserAvatar(label: room.name),
      title: Text(room.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        room.lastMessage.isEmpty
            ? room.topic
            : roomPreviewText(room.lastMessage),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerEnd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatTime(room.lastActivity),
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            if (room.unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rop.primaryButton,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  '${room.unreadCount}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: rop.textOnPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InviteTile extends StatefulWidget {
  const _InviteTile({
    required this.room,
    required this.onAccept,
    required this.onDecline,
  });

  final MatrixRoom room;
  final Future<void> Function()? onAccept;
  final Future<void> Function()? onDecline;

  @override
  State<_InviteTile> createState() => _InviteTileState();
}

class _InviteTileState extends State<_InviteTile> {
  var _busy = false;

  Future<void> _run(Future<void> Function()? action) async {
    if (_busy || action == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(matrixError(error))));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final invitedBy = room.invitedBy.isEmpty
        ? 'invite_pending'.tr()
        : 'invite_by'.tr(args: [room.invitedBy]);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          key: Key(TestKeys.roomTile(room.id)),
          leading: UserAvatar(label: room.name),
          title: Text(room.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            invitedBy,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.onAccept != null || widget.onDecline != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: Key(TestKeys.declineInvite(room.id)),
                  onPressed: _busy || widget.onDecline == null
                      ? null
                      : () => _run(widget.onDecline),
                  child: Text('decline'.tr()),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: Key(TestKeys.acceptInvite(room.id)),
                  onPressed: _busy || widget.onAccept == null
                      ? null
                      : () => _run(widget.onAccept),
                  child: Text('accept'.tr()),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
