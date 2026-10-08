import 'package:element_x/features/licenses/cubit/licenses_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final packages = context.watch<LicensesCubit>().state.packages;
    return Scaffold(
      appBar: AppBar(title: const Text('Open-source licenses')),
      body: ListView(
        children: [
          for (final package in packages) ListTile(title: Text(package)),
        ],
      ),
    );
  }
}
