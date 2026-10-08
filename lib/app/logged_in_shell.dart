import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:element_x/core/di/di.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/core/utils/test_keys.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:element_x/theme/rop_spacing.dart';
import 'package:element_x/widgets/app_drawer.dart';
import 'package:element_x/widgets/rop_crest.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Logged-in frame: drawer, space entry points, and settings.
class LoggedInShell extends StatelessWidget {
  const LoggedInShell({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.floatingActionButton,
    this.showBrandHeader = false,
    this.transparentAppBar = false,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final bool showBrandHeader;
  final bool transparentAppBar;

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    final store = sl<MatrixStore>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= RopSpacing.railBreakpoint;
        final glassBar = transparentAppBar && !wide;
        final dark = Theme.of(context).brightness == Brightness.dark;
        final barForeground = glassBar
            ? (dark ? rop.textOnPrimary : rop.textPrimary)
            : rop.textOnPrimary;
        final barCaption = glassBar
            ? (dark ? rop.railText : rop.textSecondary)
            : rop.railText;
        return Scaffold(
          extendBodyBehindAppBar: glassBar,
          appBar: AppBar(
            forceMaterialTransparency: glassBar,
            backgroundColor: glassBar ? Colors.transparent : rop.railStart,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
            foregroundColor: barForeground,
            iconTheme: IconThemeData(color: barForeground),
            actionsIconTheme: IconThemeData(color: barForeground),
            systemOverlayStyle: glassBar
                ? SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: dark
                        ? Brightness.light
                        : Brightness.dark,
                    statusBarBrightness: dark
                        ? Brightness.dark
                        : Brightness.light,
                    systemNavigationBarColor: rop.pageWashEnd,
                    systemNavigationBarIconBrightness: dark
                        ? Brightness.light
                        : Brightness.dark,
                  )
                : null,
            flexibleSpace: glassBar ? const _GlassAppBarBackdrop() : null,
            title: showBrandHeader
                ? Row(
                    children: [
                      const RopCrest(size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'app_name'.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: barForeground,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              'short_tagline'.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: barCaption),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Text(title),
            actions: [
              ...actions,
              IconButton(
                key: const Key(TestKeys.settings),
                tooltip: 'settings_title'.tr(),
                onPressed: () => context.push(RoutePaths.settings),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          drawer: wide ? null : AppDrawer(store: store),
          floatingActionButton: floatingActionButton,
          body: Row(
            children: [
              if (wide)
                SizedBox(width: 280, child: AppNavigationPanel(store: store)),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}

/// Frosted bar so the home artwork shows through the header.
class _GlassAppBarBackdrop extends StatelessWidget {
  const _GlassAppBarBackdrop();

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = dark ? rop.railStart : Colors.white;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: SizedBox.expand(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  tint.withValues(alpha: dark ? 0.42 : 0.28),
                  tint.withValues(alpha: dark ? 0.16 : 0.08),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: dark ? 0.16 : 0.70),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
