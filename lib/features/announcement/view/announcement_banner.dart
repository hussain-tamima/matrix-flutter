import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/announcement/cubit/announcement_cubit.dart';
import 'package:element_x/theme/rop_spacing.dart';
import 'package:element_x/theme/rop_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AnnouncementBanner extends StatelessWidget {
  const AnnouncementBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final announcement = context.watch<AnnouncementCubit>().state.announcement;
    if (announcement == null) {
      return const SizedBox.shrink();
    }
    final rop = RopTheme.of(context);
    return Material(
      color: rop.infoBadge,
      borderRadius: BorderRadius.circular(RopSpacing.controlRadius),
      child: ListTile(
        leading: Icon(Icons.campaign_outlined, color: rop.textLink),
        title: Text(announcement.title),
        subtitle: Text(announcement.body),
        trailing: IconButton(
          tooltip: 'Dismiss',
          onPressed: () => context.read<AnnouncementCubit>().dismiss(),
          icon: const Icon(Icons.close),
        ),
        onTap: () => context.push(RoutePaths.secureBackup),
      ),
    );
  }
}
