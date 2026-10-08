import 'package:easy_localization/easy_localization.dart';
import 'package:element_x/core/config/app_config.dart';
import 'package:element_x/core/matrix/matrix_error.dart';
import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/joinroom/cubit/joinroom_cubit.dart';
import 'package:element_x/theme/rop_spacing.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:element_x/widgets/form_notice.dart';
import 'package:element_x/widgets/grouped_surface.dart';
import 'package:element_x/widgets/task_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key, this.initialAddress});

  final String? initialAddress;

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  late final TextEditingController _address = TextEditingController(
    text: widget.initialAddress ?? '',
  );

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAddress;
    if (initial != null && initial.isNotEmpty) {
      _address.selection = TextSelection(
        baseOffset: 0,
        extentOffset: initial.length,
      );
    }
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<JoinRoomCubit>().submit(_address.text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JoinRoomCubit, JoinRoomState>(
      listenWhen: (previous, current) =>
          current.completed != previous.completed,
      listener: (context, state) {
        final roomId = state.roomId;
        if (roomId != null) context.push(RoutePaths.room(roomId));
      },
      builder: (context, state) {
        final canSubmit = _address.text.trim().isNotEmpty;
        return TaskFormPage(
          title: 'join_room_title'.tr(),
          actionLabel: 'join_room_action'.tr(),
          busy: state.submitting,
          onAction: canSubmit ? _submit : null,
          notice: state.error == null
              ? null
              : FormNotice(message: userFacingError(state.error!)),
          children: [
            AbsorbPointer(
              absorbing: state.submitting,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _address,
                    enabled: !state.submitting,
                    autofocus: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'join_room_address'.tr(),
                      hintText: '#room:${AppConfig.defaultHomeserver}',
                      helperText: 'join_room_help'.tr(),
                      helperMaxLines: 3,
                    ),
                    onChanged: (_) {
                      context.read<JoinRoomCubit>().clearError();
                      setState(() {});
                    },
                    onSubmitted: (_) {
                      if (canSubmit) _submit();
                    },
                  ),
                  const SizedBox(height: RopSpacing.lg),
                  GroupedSurface(
                    dividerStart: 72,
                    children: [
                      ListTile(
                        shape: const RoundedRectangleBorder(),
                        leading: const _Glyph(Icons.manage_search),
                        title: Text('join_room_resolve'.tr()),
                        subtitle: Text('resolve_alias_help'.tr()),
                        enabled: !state.submitting,
                        onTap: state.submitting
                            ? null
                            : () => context.push(RoutePaths.resolveAlias),
                      ),
                      ListTile(
                        shape: const RoundedRectangleBorder(),
                        leading: const _Glyph(Icons.public),
                        title: Text('start_chat_directory'.tr()),
                        subtitle: Text('start_chat_directory_hint'.tr()),
                        enabled: !state.submitting,
                        onTap: state.submitting
                            ? null
                            : () => context.push(RoutePaths.directory),
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
