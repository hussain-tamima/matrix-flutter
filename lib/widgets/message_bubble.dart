import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/core/utils/formatters.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.event,
    required this.senderName,
    required this.isMine,
    this.replyCount = 0,
    this.onLongPress,
    this.onVote,
    this.onOpenThread,
  });

  final TimelineEvent event;
  final String senderName;
  final bool isMine;
  final int replyCount;
  final VoidCallback? onLongPress;
  final void Function(String option)? onVote;
  final VoidCallback? onOpenThread;

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    final background = isMine ? rop.ownBubble : rop.otherBubble;
    final foreground = isMine ? rop.ownBubbleText : rop.otherBubbleText;
    final maxWidth =
        MediaQuery.sizeOf(context).width.clamp(280.0, 720.0) * 0.76;
    return Align(
      alignment: isMine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: rop.bubbleShadow,
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderName,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: foreground),
                ),
                const SizedBox(height: 4),
                Text(
                  event.body,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: foreground),
                ),
                if (event.kind == TimelineEventKind.image)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Icon(Icons.image_outlined, color: foreground),
                  ),
                if (event.kind == TimelineEventKind.voice)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Icon(Icons.graphic_eq, color: foreground),
                  ),
                if (event.kind == TimelineEventKind.poll) ...[
                  const SizedBox(height: 8),
                  for (final option in event.pollOptions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: OutlinedButton(
                        onPressed: onVote == null
                            ? null
                            : () => onVote!(option),
                        child: Text(
                          '$option · ${event.pollVotes[option] ?? 0}',
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 4),
                Text(
                  formatTime(event.timestamp),
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: foreground),
                ),
                if (event.isPinned)
                  Text(
                    'pinned'.tr(),
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: foreground),
                  ),
                if (replyCount > 0 && onOpenThread != null)
                  TextButton(
                    onPressed: onOpenThread,
                    child: Text('thread_replies'.tr(args: ['$replyCount'])),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
