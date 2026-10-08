import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/theme/app_theme.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:element_x/widgets/rop_crest.dart';
import 'package:element_x/widgets/user_avatar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.store});

  final MatrixStore store;

  @override
  Widget build(BuildContext context) {
    return Drawer(child: AppNavigationPanel(store: store, closeOnSelect: true));
  }
}

class AppNavigationPanel extends StatelessWidget {
  const AppNavigationPanel({
    super.key,
    required this.store,
    this.closeOnSelect = false,
  });

  final MatrixStore store;
  final bool closeOnSelect;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final user = store.currentUser;
    final rop = RopTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [rop.railStart, rop.railEnd],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: RopCrest(size: 40),
              ),
            ),
            ListTile(
              leading: _avatar(user.displayName, rop),
              title: Text(
                user.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: rop.textOnPrimary),
              ),
              subtitle: Text(
                user.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: rop.railText),
              ),
              onTap: () => _navigate(
                context,
                () => context.push(RoutePaths.user(user.id)),
              ),
            ),
            Divider(color: rop.railText.withValues(alpha: 0.24)),
            _destination(
              context,
              rop: rop,
              icon: Icons.home_outlined,
              label: 'home_title'.tr(),
              selected:
                  path == RoutePaths.home || path == RoutePaths.homeSearch,
              onTap: () => context.go(RoutePaths.home),
            ),
            for (final space in store.spaces)
              _destination(
                context,
                rop: rop,
                icon: Icons.workspaces_outlined,
                label: space.name,
                selected: path == RoutePaths.space(space.id),
                onTap: () => context.push(RoutePaths.space(space.id)),
              ),
            _destination(
              context,
              rop: rop,
              icon: Icons.travel_explore,
              label: 'room_directory'.tr(),
              selected: path == RoutePaths.directory,
              onTap: () => context.push(RoutePaths.directory),
            ),
            _destination(
              context,
              rop: rop,
              icon: Icons.settings_outlined,
              label: 'settings_title'.tr(),
              selected: path.startsWith(RoutePaths.settings),
              onTap: () => context.push(RoutePaths.settings),
            ),
            _destination(
              context,
              rop: rop,
              icon: Icons.bug_report_outlined,
              label: 'report_bug'.tr(),
              selected: path == RoutePaths.bugReport,
              onTap: () => context.push(RoutePaths.bugReport),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String label, RopTheme rop) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        UserAvatar(label: label),
        if (store.online)
          PositionedDirectional(
            end: -1,
            bottom: -1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.online,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: rop.railStart, width: 1.5),
                ),
              ),
              child: const SizedBox(width: 12, height: 12),
            ),
          ),
      ],
    );
  }

  Widget _destination(
    BuildContext context, {
    required RopTheme rop,
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      selected: selected,
      tileColor: selected ? rop.hoverTint : null,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(
              color: selected ? rop.railActiveMarker : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: rop.railText),
        ],
      ),
      title: Text(label, style: TextStyle(color: rop.railText)),
      onTap: () => _navigate(context, onTap),
    );
  }

  void _navigate(BuildContext context, VoidCallback action) {
    if (closeOnSelect) {
      Navigator.pop(context);
    }
    action();
  }
}
