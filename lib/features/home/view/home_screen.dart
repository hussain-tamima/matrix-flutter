import 'dart:ui';

import 'package:element_x/app/logged_in_shell.dart';
import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/announcement/view/announcement_banner.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/home/cubit/home_cubit.dart';
import 'package:element_x/features/home/models/room_filter.dart';
import 'package:element_x/theme/rop_assets.dart';
import 'package:element_x/theme/rop_spacing.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:element_x/widgets/ltr_brand_image.dart';
import 'package:element_x/widgets/room_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        return LoggedInShell(
          title: 'home_title'.tr(),
          showBrandHeader: true,
          transparentAppBar: true,
          actions: [
            IconButton(
              tooltip: 'search'.tr(),
              onPressed: () => context.push(RoutePaths.homeSearch),
              icon: const Icon(Icons.search),
            ),
          ],
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push(RoutePaths.startChat),
            icon: const Icon(Icons.edit_outlined),
            label: Text('new_chat'.tr()),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final appBarInset =
                  constraints.maxWidth < RopSpacing.railBreakpoint
                  ? MediaQuery.paddingOf(context).top + kToolbarHeight
                  : 0.0;
              final dark = Theme.of(context).brightness == Brightness.dark;
              return Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: AlignmentDirectional.centerStart,
                        end: AlignmentDirectional.centerEnd,
                        colors: [rop.pageWashStart, rop.pageWashEnd],
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: LtrBrandImage(
                      asset: RopAssets.homeGlass,
                      fit: BoxFit.cover,
                      alignment: Alignment(0.15, -0.05),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.18, 0.55, 1.0],
                        colors: [
                          dark
                              ? rop.railStart.withValues(alpha: 0.42)
                              : const Color(0xFFD7E8F8).withValues(alpha: 0.16),
                          Colors.transparent,
                          Colors.transparent,
                          rop.fortWashStart.withValues(
                            alpha: dark ? 0.28 : 0.05,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        RopSpacing.sm,
                        appBarInset + RopSpacing.xs,
                        RopSpacing.sm,
                        RopSpacing.sm,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: RopSpacing.contentMaxWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!state.online)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: RopSpacing.xs,
                                  ),
                                  child: _OfflineBanner(rop: rop),
                                ),
                              const Padding(
                                padding: EdgeInsets.only(bottom: RopSpacing.xs),
                                child: AnnouncementBanner(),
                              ),
                              _RoomFilterBar(
                                selected: state.filter,
                                onSelected: (filter) =>
                                    context.read<HomeCubit>().setFilter(filter),
                              ),
                              const SizedBox(height: RopSpacing.xs),
                              Expanded(
                                child: _GlassRoomPanel(
                                  rop: rop,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 280),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    child: state.syncing && state.rooms.isEmpty
                                        ? const Center(
                                            key: ValueKey('loading'),
                                            child: CircularProgressIndicator(),
                                          )
                                        : state.rooms.isEmpty
                                        ? _EmptyRooms(
                                            key: const ValueKey('empty'),
                                            onStartChat: () => context.push(
                                              RoutePaths.startChat,
                                            ),
                                          )
                                        : _AnimatedRoomList(
                                            key: ValueKey(
                                              'rooms-${state.filter.name}',
                                            ),
                                            rooms: state.rooms,
                                            rop: rop,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _GlassRoomPanel extends StatelessWidget {
  const _GlassRoomPanel({required this.rop, required this.child});

  final RopTheme rop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(RopSpacing.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: dark
                ? const Color.fromRGBO(12, 20, 36, 0.22)
                : const Color.fromRGBO(255, 255, 255, 0.16),
            borderRadius: BorderRadius.circular(RopSpacing.cardRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: dark ? 0.22 : 0.62),
              width: 1.25,
            ),
            boxShadow: [
              BoxShadow(
                color: rop.cardShadow.withValues(alpha: 0.45),
                blurRadius: 36,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    );
  }
}

class _RoomFilterBar extends StatelessWidget {
  const _RoomFilterBar({required this.selected, required this.onSelected});

  final RoomFilter selected;
  final ValueChanged<RoomFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: RoomFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: RopSpacing.xs),
        itemBuilder: (context, index) {
          final filter = RoomFilter.values[index];
          final isSelected = selected == filter;
          return ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: AnimatedScale(
                scale: isSelected ? 1.0 : 0.96,
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: rop.primaryButton.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: FilterChip(
                    label: Text(filter.translationKey.tr()),
                    selected: isSelected,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? rop.textOnPrimary : rop.textPrimary,
                    ),
                    selectedColor: rop.primaryButton,
                    backgroundColor: rop.canvas.withValues(alpha: 0.42),
                    side: BorderSide(
                      color: isSelected
                          ? rop.primaryButton
                          : Colors.white.withValues(alpha: dark ? 0.18 : 0.72),
                    ),
                    onSelected: (_) => onSelected(filter),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PersonGlassCard extends StatelessWidget {
  const _PersonGlassCard({required this.rop, required this.child});

  final RopTheme rop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: dark ? 0.16 : 0.50),
              Colors.white.withValues(alpha: dark ? 0.07 : 0.28),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: dark ? 0.30 : 0.88),
          ),
          boxShadow: [
            BoxShadow(
              color: rop.cardShadow.withValues(alpha: dark ? 0.35 : 0.22),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(15), child: child),
      ),
    );
  }
}

class _AnimatedRoomList extends StatelessWidget {
  const _AnimatedRoomList({super.key, required this.rooms, required this.rop});

  final List<MatrixRoom> rooms;
  final RopTheme rop;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        final tile = _PersonGlassCard(
          rop: rop,
          child: RoomTile(
            room: room,
            onTap: () => context.push(
              room.isSpace
                  ? RoutePaths.space(room.id)
                  : RoutePaths.room(room.id),
            ),
            onAccept: () => context.read<HomeCubit>().acceptInvite(room.id),
            onDecline: () => context.read<HomeCubit>().declineInvite(room.id),
          ),
        );
        if (reduceMotion) return tile;
        return TweenAnimationBuilder<double>(
          key: ValueKey('${room.id}-$index'),
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 320 + (index.clamp(0, 8) * 45)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 14 * (1 - value)),
                child: child,
              ),
            );
          },
          child: tile,
        );
      },
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.rop});

  final RopTheme rop;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(RopSpacing.controlRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: rop.warningSurface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(RopSpacing.controlRadius),
          child: ListTile(
            dense: true,
            leading: Icon(Icons.cloud_off_outlined, color: rop.warningText),
            title: Text(
              'offline_message'.tr(),
              style: TextStyle(color: rop.warningText),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms({super.key, required this.onStartChat});

  final VoidCallback onStartChat;

  @override
  Widget build(BuildContext context) {
    final rop = RopTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(RopSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Icon(
                Icons.forum_outlined,
                size: 52,
                color: rop.textLink.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: RopSpacing.md),
            Text(
              'empty_rooms_title'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RopSpacing.xs),
            Text(
              'empty_rooms_body'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: rop.textSecondary),
            ),
            const SizedBox(height: RopSpacing.lg),
            FilledButton.icon(
              onPressed: onStartChat,
              icon: const Icon(Icons.edit_outlined),
              label: Text('start_chat'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
