import 'package:element_x/features/enterprise/cubit/enterprise_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EnterpriseScreen extends StatelessWidget {
  const EnterpriseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final available = context.watch<EnterpriseCubit>().state.available;
    return Scaffold(
      appBar: AppBar(title: const Text('Enterprise')),
      body: SwitchListTile(
        title: const Text('Enterprise features'),
        subtitle: Text(available ? 'Enabled' : 'Not included in this build.'),
        value: available,
        onChanged: null,
      ),
    );
  }
}
