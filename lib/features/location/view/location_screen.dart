import 'package:element_x/features/location/cubit/location_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _label = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocationCubit, LocationState>(
      listenWhen: (previous, current) => current.shared && !previous.shared,
      listener: (context, state) => context.pop(),
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Share location')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                height: 180,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('Map preview'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _label,
                decoration: const InputDecoration(
                  labelText: 'Place',
                  hintText: 'Current location',
                ).copyWith(errorText: state.error),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    context.read<LocationCubit>().share(_label.text),
                child: const Text('Share location'),
              ),
            ],
          ),
        );
      },
    );
  }
}
