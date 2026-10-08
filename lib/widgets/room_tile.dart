import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/core/utils/formatters.dart';
import 'package:element_x/core/utils/test_keys.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:element_x/widgets/user_avatar.dart';
import 'package:flutter/material.dart';

class RoomTile extends StatelessWidget {
  const RoomTile({super.key, required this.room, required this.onTap});

  final MatrixRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    return ListTile(
      key: Key(TestKeys.roomTile(room.id)),
      onTap: onTap,
      leading: UserAvatar(label: room.name),
      title: Text(room.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        room.lastMessage.isEmpty ? room.topic : room.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatTime(room.lastActivity),
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
