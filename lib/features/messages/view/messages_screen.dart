import 'package:element_x/core/di/di.dart';
import 'package:element_x/core/matrix/matrix_error.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/call/repo/call_repo.dart';
import 'package:element_x/core/utils/test_keys.dart';
import 'package:element_x/features/messages/cubit/messages_cubit.dart';
import 'package:element_x/theme/rop_assets.dart';
import 'package:element_x/theme/rop_spacing.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:element_x/widgets/ltr_brand_image.dart';
import 'package:element_x/widgets/message_bubble.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) {
        return;
      }
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MessagesCubit, MessagesState>(
      listenWhen: (previous, current) =>
          previous.events.length != current.events.length,
      listener: (context, state) => _scrollToEnd(),
      builder: (context, state) {
        if (state.missing || state.room == null) {
          return Scaffold(body: Center(child: Text('room_not_found'.tr())));
        }
        final cubit = context.read<MessagesCubit>();
        final room = state.room!;
        final rop = RopTheme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: InkWell(
              onTap: () => context.push(RoutePaths.roomDetails(room.id)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.name),
                  Text(
                    (room.isEncrypted ? 'encrypted' : 'not_encrypted').tr(),
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: rop.railText),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'preview_voice_call'.tr(),
                onPressed: () => _startCall(context, room.id, video: false),
                icon: const Icon(Icons.call_outlined),
              ),
              IconButton(
                tooltip: 'preview_video_call'.tr(),
                onPressed: () => _startCall(context, room.id, video: true),
                icon: const Icon(Icons.videocam_outlined),
              ),
              IconButton(
                tooltip: 'pins'.tr(),
                onPressed: () => context.push(RoutePaths.roomPins(room.id)),
                icon: const Icon(Icons.push_pin_outlined),
              ),
            ],
          ),
          body: Column(
            children: [
              if (state.typing)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RopSpacing.md,
                    vertical: RopSpacing.xs,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'typing'.tr(),
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: rop.textSecondary),
                    ),
                  ),
                ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const Positioned.fill(
                      child: LtrBrandImage(
                        asset: RopAssets.chatPattern,
                        fit: BoxFit.cover,
                      ),
                    ),
                    ColoredBox(color: rop.chatWash),
                    ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(
                        horizontal: RopSpacing.sm,
                        vertical: RopSpacing.xs,
                      ),
                      children: [
                        for (final event in state.events)
                          MessageBubble(
                            event: event,
                            senderName: cubit.nameFor(event.senderId),
                            isMine: cubit.mine(event.senderId),
                            replyCount: state.replyCounts[event.id] ?? 0,
                            onVote: (option) => cubit.vote(event.id, option),
                            onOpenThread: () => context.push(
                              RoutePaths.thread(room.id, event.id),
                            ),
                            onLongPress: () => _actions(context, event),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (state.recording)
                ListTile(
                  leading: const Icon(Icons.mic),
                  title: Text('recording'.tr()),
                  trailing: TextButton(
                    onPressed: () => context.read<MessagesCubit>().stopVoice(),
                    child: Text('send'.tr()),
                  ),
                ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    state.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ColoredBox(
                color: rop.surface,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(RopSpacing.xs),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'attach'.tr(),
                          onPressed: () => _attachments(context),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        Expanded(
                          child: TextField(
                            key: const Key(TestKeys.composer),
                            controller: _composer,
                            decoration: InputDecoration(
                              hintText: 'message_hint'.tr(),
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: _send,
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: const Alignment(-0.5, -1),
                              end: const Alignment(0.5, 1),
                              colors: [
                                rop.sendGradientStart,
                                rop.sendGradientEnd,
                              ],
                            ),
                          ),
                          child: IconButton(
                            key: const Key(TestKeys.send),
                            tooltip: 'send'.tr(),
                            onPressed: () => _send(_composer.text),
                            icon: Icon(Icons.send, color: rop.textOnPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _send(String value) {
    context.read<MessagesCubit>().send(value);
    _composer.clear();
  }

  Future<void> _startCall(
    BuildContext context,
    String roomId, {
    required bool video,
  }) async {
    try {
      await sl<CallRepo>().start(roomId, video: video);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(matrixError(error))),
      );
    }
  }

  Future<void> _attachments(BuildContext context) async {
    final cubit = context.read<MessagesCubit>();
    final roomId = widget.roomId;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text('photo'.tr()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  cubit.sendPhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: Text('file'.tr()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  cubit.sendFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic_none),
                title: Text('voice_message'.tr()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  cubit.sendVoice();
                },
              ),
              ListTile(
                leading: const Icon(Icons.poll_outlined),
                title: Text('poll'.tr()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(RoutePaths.roomPoll(roomId));
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text('location'.tr()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(RoutePaths.roomLocation(roomId));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _actions(BuildContext context, TimelineEvent event) async {
    final cubit = context.read<MessagesCubit>();
    final roomId = widget.roomId;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text((event.isPinned ? 'unpin' : 'pin').tr()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  cubit.togglePin(event);
                },
              ),
              ListTile(
                title: Text('reply_thread'.tr()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(RoutePaths.thread(roomId, event.id));
                },
              ),
              ListTile(
                title: Text('forward'.tr()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(RoutePaths.forward(roomId, event.id));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
