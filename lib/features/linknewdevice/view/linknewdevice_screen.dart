import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/linknewdevice/cubit/linknewdevice_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LinkNewDeviceScreen extends StatelessWidget {
  const LinkNewDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Link a new device')),
      body: BlocBuilder<LinkNewDeviceCubit, LinkNewDeviceState>(
        builder: (context, state) {
          final cubit = context.read<LinkNewDeviceCubit>();
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Sign in another phone'),
                  subtitle: const Text('Show a QR code for MSC4108 sign-in'),
                  trailing: const Icon(Icons.qr_code),
                  onTap: () => context.push(RoutePaths.linkDeviceSignInQr),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.status ?? 'Verify another device that is already signed in on this account.',
              ),
              if (state.emojis.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  state.emojis.join('  '),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: cubit.confirm,
                  child: const Text('They match'),
                ),
                TextButton(
                  onPressed: cubit.cancel,
                  child: const Text('Cancel'),
                ),
              ],
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              for (final device in state.devices)
                ListTile(
                  leading: Icon(
                    device.verified ? Icons.verified_user : Icons.devices,
                  ),
                  title: Text(device.name),
                  subtitle: Text(device.current ? 'This device' : device.id),
                  trailing: device.current || device.verified
                      ? null
                      : TextButton(
                          onPressed: () => cubit.verify(device.id),
                          child: const Text('Verify'),
                        ),
                ),
            ],
          );
        },
      ),
    );
  }
}
