import 'package:easy_localization/easy_localization.dart';
import 'package:element_x/core/config/app_config.dart';
import 'package:element_x/core/matrix/matrix_error.dart';
import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/roomaliasresolver/cubit/roomaliasresolver_cubit.dart';
import 'package:element_x/theme/rop_spacing.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:element_x/widgets/form_notice.dart';
import 'package:element_x/widgets/grouped_surface.dart';
import 'package:element_x/widgets/task_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RoomAliasResolverScreen extends StatefulWidget {
  const RoomAliasResolverScreen({super.key});

  @override
  State<RoomAliasResolverScreen> createState() =>
      _RoomAliasResolverScreenState();
}

class _RoomAliasResolverScreenState extends State<RoomAliasResolverScreen> {
  final _alias = TextEditingController();

  @override
  void dispose() {
    _alias.dispose();
    super.dispose();
  }

  void _resolve() {
    context.read<RoomAliasResolverCubit>().resolve(_alias.text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomAliasResolverCubit, RoomAliasResolverState>(
      builder: (context, state) {
        final roomId = state.resolution?.roomId;
        final error = state.resolution?.error;
        final canResolve = _alias.text.trim().isNotEmpty;
        final rop = RopTheme.of(context);
        return TaskFormPage(
          title: 'resolve_alias_title'.tr(),
          actionLabel: roomId == null
              ? 'resolve_alias_action'.tr()
              : 'resolve_alias_open'.tr(),
          busy: state.submitting,
          onAction: roomId != null
              ? () => context.push(RoutePaths.room(roomId))
              : (canResolve ? _resolve : null),
          notice: error == null
              ? null
              : FormNotice(message: userFacingError(error)),
          children: [
            TextField(
              controller: _alias,
              enabled: !state.submitting,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'resolve_alias_label'.tr(),
                hintText: '#room:${AppConfig.defaultHomeserver}',
                helperText: 'resolve_alias_help'.tr(),
                helperMaxLines: 3,
              ),
              onChanged: (_) {
                context.read<RoomAliasResolverCubit>().reset();
                setState(() {});
              },
              onSubmitted: (_) {
                if (roomId == null && canResolve) _resolve();
              },
            ),
            if (roomId != null) ...[
              const SizedBox(height: RopSpacing.lg),
              GroupedSurface(
                children: [
                  ListTile(
                    shape: const RoundedRectangleBorder(),
                    leading: ExcludeSemantics(
                      child: Icon(
                        Icons.check_circle_outline,
                        color: rop.textLink,
                      ),
                    ),
                    title: Text('resolve_alias_found'.tr()),
                    subtitle: Text(
                      roomId,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: rop.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
