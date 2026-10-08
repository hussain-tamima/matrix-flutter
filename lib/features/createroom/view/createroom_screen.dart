import 'package:easy_localization/easy_localization.dart';
import 'package:element_x/core/matrix/matrix_error.dart';
import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/createroom/cubit/createroom_cubit.dart';
import 'package:element_x/theme/rop_spacing.dart';
import 'package:element_x/widgets/form_notice.dart';
import 'package:element_x/widgets/grouped_surface.dart';
import 'package:element_x/widgets/task_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _name = TextEditingController();
  final _topic = TextEditingController();
  final _topicFocus = FocusNode();

  @override
  void dispose() {
    _name.dispose();
    _topic.dispose();
    _topicFocus.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<CreateRoomCubit>().submit(
      name: _name.text,
      topic: _topic.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateRoomCubit, CreateRoomState>(
      listenWhen: (previous, current) =>
          current.roomId != null && previous.roomId != current.roomId,
      listener: (context, state) {
        final roomId = state.roomId;
        if (roomId == null) return;
        if (state.isSpace) {
          context.push(RoutePaths.space(roomId));
        } else {
          context.push(RoutePaths.room(roomId));
        }
      },
      builder: (context, state) {
        final nameMissing = state.error == 'create_room_name_required';
        final serverError = state.error != null && !nameMissing
            ? userFacingError(state.error!)
            : null;
        final canSubmit = _name.text.trim().isNotEmpty;
        return TaskFormPage(
          title: state.isSpace
              ? 'create_space_title'.tr()
              : 'create_room_title'.tr(),
          actionLabel: state.isSpace
              ? 'create_space_action'.tr()
              : 'create_room_action'.tr(),
          busy: state.submitting,
          onAction: canSubmit ? _submit : null,
          notice: serverError == null ? null : FormNotice(message: serverError),
          children: [
            AbsorbPointer(
              absorbing: state.submitting,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _name,
                    enabled: !state.submitting,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'create_room_name'.tr(),
                      errorText: nameMissing
                          ? userFacingError(state.error!)
                          : null,
                    ),
                    onChanged: (_) {
                      context.read<CreateRoomCubit>().clearError();
                      setState(() {});
                    },
                    onSubmitted: (_) => _topicFocus.requestFocus(),
                  ),
                  const SizedBox(height: RopSpacing.sm),
                  TextField(
                    controller: _topic,
                    enabled: !state.submitting,
                    focusNode: _topicFocus,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'create_room_topic'.tr(),
                      helperText: 'create_room_topic_hint'.tr(),
                      helperMaxLines: 3,
                    ),
                    onSubmitted: (_) {
                      if (canSubmit) _submit();
                    },
                  ),
                  const SizedBox(height: RopSpacing.lg),
                  GroupedSurface(
                    children: [
                      SwitchListTile(
                        shape: const RoundedRectangleBorder(),
                        title: Text('create_room_public'.tr()),
                        subtitle: Text('create_room_public_hint'.tr()),
                        value: state.isPublic,
                        onChanged: context.read<CreateRoomCubit>().setPublic,
                      ),
                      SwitchListTile(
                        shape: const RoundedRectangleBorder(),
                        title: Text('create_room_encrypted'.tr()),
                        subtitle: Text('create_room_encrypted_hint'.tr()),
                        value: state.isEncrypted,
                        onChanged: context.read<CreateRoomCubit>().setEncrypted,
                      ),
                      SwitchListTile(
                        shape: const RoundedRectangleBorder(),
                        title: Text('create_room_space'.tr()),
                        subtitle: Text('create_room_space_hint'.tr()),
                        value: state.isSpace,
                        onChanged: context.read<CreateRoomCubit>().setSpace,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
