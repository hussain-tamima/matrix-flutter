import 'package:easy_localization/easy_localization.dart';
import 'package:element_x/core/matrix/matrix_error.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/startchat/cubit/startchat_cubit.dart';
import 'package:element_x/theme/rop_spacing.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:element_x/widgets/form_notice.dart';
import 'package:element_x/widgets/grouped_surface.dart';
import 'package:element_x/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class StartChatScreen extends StatefulWidget {
  const StartChatScreen({super.key});

  @override
  State<StartChatScreen> createState() => _StartChatScreenState();
}

class _StartChatScreenState extends State<StartChatScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    context.read<StartChatCubit>().clearError();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StartChatCubit, StartChatState>(
      listenWhen: (previous, current) =>
          current.completed != previous.completed,
      listener: (context, state) {
        final roomId = state.openedRoomId;
        if (roomId != null) context.push(RoutePaths.room(roomId));
      },
      child: Scaffold(
        appBar: AppBar(title: Text('new_chat'.tr())),
        body: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: RopSpacing.contentMaxWidth,
            ),
            child: BlocBuilder<StartChatCubit, StartChatState>(
              builder: (context, state) {
                final query = _query.text;
                final people = [...state.people]
                  ..sort(
                    (a, b) => a.displayName.toLowerCase().compareTo(
                      b.displayName.toLowerCase(),
                    ),
                  );
                final visible = people
                    .where((person) => _matches(person, query))
                    .toList();
                final showDirect =
                    _looksLikeUserId(query) &&
                    !people.any(
                      (person) =>
                          person.id.toLowerCase() == query.trim().toLowerCase(),
                    );
                final showJoin = _looksLikeRoomAddress(query);
                final opening = state.openingUserId != null;

                return ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    RopSpacing.md,
                    RopSpacing.sm,
                    RopSpacing.md,
                    RopSpacing.xl,
                  ),
                  children: [
                    TextField(
                      controller: _query,
                      autofocus: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'start_chat_search_hint'.tr(),
                        hintStyle: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(
                              color: RopTheme.of(context).textSecondary,
                            ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: RopTheme.of(context).textSecondary,
                        ),
                        suffixIcon: query.trim().isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'clear'.tr(),
                                onPressed: () {
                                  _query.clear();
                                  _onQueryChanged('');
                                },
                                icon: Icon(
                                  Icons.close,
                                  color: RopTheme.of(context).textSecondary,
                                ),
                              ),
                      ),
                      onChanged: _onQueryChanged,
                      onSubmitted: (value) {
                        if (_looksLikeUserId(value)) {
                          context.read<StartChatCubit>().open(value);
                        }
                      },
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: RopSpacing.sm),
                      FormNotice(message: userFacingError(state.error!)),
                    ],
                    if (query.trim().isEmpty) ...[
                      const SizedBox(height: RopSpacing.lg),
                      GroupedSurface(
                        dividerStart: 72,
                        children: [
                          _ActionRow(
                            icon: Icons.group_add_outlined,
                            title: 'start_chat_new_room'.tr(),
                            subtitle: 'start_chat_new_room_hint'.tr(),
                            onTap: opening
                                ? null
                                : () => context.push(RoutePaths.createRoom),
                          ),
                          _ActionRow(
                            icon: Icons.tag,
                            title: 'start_chat_join'.tr(),
                            subtitle: 'start_chat_join_hint'.tr(),
                            onTap: opening
                                ? null
                                : () => context.push(RoutePaths.joinRoom),
                          ),
                          _ActionRow(
                            icon: Icons.public,
                            title: 'start_chat_directory'.tr(),
                            subtitle: 'start_chat_directory_hint'.tr(),
                            onTap: opening
                                ? null
                                : () => context.push(RoutePaths.directory),
                          ),
                        ],
                      ),
                    ],
                    if (showDirect || showJoin) ...[
                      const SizedBox(height: RopSpacing.md),
                      if (showDirect)
                        _DirectRow(
                          userId: query.trim(),
                          opening: state.openingUserId == query.trim(),
                          enabled: !opening,
                          onTap: () =>
                              context.read<StartChatCubit>().open(query),
                        ),
                      if (showJoin)
                        GroupedSurface(
                          dividerStart: 72,
                          children: [
                            _ActionRow(
                              icon: Icons.tag,
                              title: query.trim(),
                              subtitle: 'start_chat_join_query'.tr(),
                              onTap: opening
                                  ? null
                                  : () => context.push(
                                      RoutePaths.joinRoom,
                                      extra: query.trim(),
                                    ),
                            ),
                          ],
                        ),
                    ],
                    if (visible.isNotEmpty) ...[
                      _SectionLabel('start_chat_people'.tr()),
                      for (var i = 0; i < visible.length; i++) ...[
                        _PersonRow(
                          person: visible[i],
                          opening: state.openingUserId == visible[i].id,
                          enabled: !opening,
                          onTap: () => context.read<StartChatCubit>().open(
                            visible[i].id,
                          ),
                        ),
                        if (i < visible.length - 1)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 72,
                            ),
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: RopTheme.of(context).separatorSubtle,
                            ),
                          ),
                      ],
                    ] else if (!showDirect && !showJoin)
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          RopSpacing.md,
                          RopSpacing.lg,
                          RopSpacing.md,
                          RopSpacing.sm,
                        ),
                        child: Text(
                          query.trim().isEmpty
                              ? 'start_chat_people_empty'.tr()
                              : 'start_chat_no_matches'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: RopTheme.of(context).textSecondary,
                                height: 1.4,
                              ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

bool _matches(MatrixUser person, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  return person.displayName.toLowerCase().contains(needle) ||
      person.id.toLowerCase().contains(needle);
}

bool _looksLikeUserId(String value) {
  return RegExp(r'^@[^\s:]+:[^\s]+$').hasMatch(value.trim());
}

bool _looksLikeRoomAddress(String value) {
  final text = value.trim();
  return text.startsWith('#') || text.startsWith('!');
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        RopSpacing.md,
        RopSpacing.lg,
        RopSpacing.md,
        RopSpacing.xs,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: RopTheme.of(context).textSecondary),
      ),
    );
  }
}

class _ActionGlyph extends StatelessWidget {
  const _ActionGlyph(this.icon);

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

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: const RoundedRectangleBorder(),
      leading: _ActionGlyph(icon),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      enabled: onTap != null,
      onTap: onTap,
    );
  }
}

class _DirectRow extends StatelessWidget {
  const _DirectRow({
    required this.userId,
    required this.opening,
    required this.enabled,
    required this.onTap,
  });

  final String userId;
  final bool opening;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GroupedSurface(
      children: [
        ListTile(
          shape: const RoundedRectangleBorder(),
          leading: UserAvatar(label: userId),
          title: Text(userId, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('start_chat_direct'.tr()),
          enabled: enabled,
          trailing: opening ? const _OpeningMark() : null,
          onTap: enabled ? onTap : null,
        ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.person,
    required this.opening,
    required this.enabled,
    required this.onTap,
  });

  final MatrixUser person;
  final bool opening;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = person.displayName.trim().isEmpty
        ? person.id
        : person.displayName.trim();
    return ListTile(
      leading: UserAvatar(label: name),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: name == person.id
          ? null
          : Text(person.id, maxLines: 1, overflow: TextOverflow.ellipsis),
      enabled: enabled,
      trailing: opening ? const _OpeningMark() : null,
      onTap: enabled ? onTap : null,
    );
  }
}

class _OpeningMark extends StatelessWidget {
  const _OpeningMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 20,
      child: CircularProgressIndicator(strokeWidth: 2.4),
    );
  }
}
