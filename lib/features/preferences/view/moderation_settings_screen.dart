import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/widgets/settings_row.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ModerationSettingsScreen extends StatelessWidget {
  const ModerationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moderation')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Room tools'),
            subtitle: Text(
              'Kick, ban, and role changes are available from each room’s details.',
            ),
          ),
          SettingsRow(
            title: 'Blocked users',
            onTap: () => context.push(RoutePaths.settingsBlocked),
          ),
        ],
      ),
    );
  }
}
