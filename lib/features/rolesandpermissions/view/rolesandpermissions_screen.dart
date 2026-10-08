import 'package:element_x/features/rolesandpermissions/cubit/rolesandpermissions_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RolesAndPermissionsScreen extends StatelessWidget {
  const RolesAndPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Roles and permissions')),
      body: BlocBuilder<RolesAndPermissionsCubit, RolesAndPermissionsState>(
        builder: (context, state) {
          final cubit = context.read<RolesAndPermissionsCubit>();
          return ListView(
            children: [
              const ListTile(
                title: Text('Default role'),
                subtitle: Text(
                  'New members join as members. Admins can change roles below.',
                ),
              ),
              for (final member in state.members)
                ListTile(
                  title: Text(cubit.nameFor(member.userId)),
                  subtitle: Text(member.role),
                  trailing: DropdownButton<String>(
                    value: member.role,
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(
                        value: 'moderator',
                        child: Text('Moderator'),
                      ),
                      DropdownMenuItem(value: 'member', child: Text('Member')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        cubit.setRole(member.userId, value);
                      }
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
