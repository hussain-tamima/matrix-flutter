import 'package:element_x/features/login/cubit/login_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrLoginScreen extends StatefulWidget {
  const QrLoginScreen({super.key});

  @override
  State<QrLoginScreen> createState() => _QrLoginScreenState();
}

class _QrLoginScreenState extends State<QrLoginScreen> {
  var _handled = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) {
      return;
    }
    final raw = capture.barcodes.firstOrNull?.rawDecodedBytes;
    final bytes = switch (raw) {
      DecodedBarcodeBytes(:final bytes) => bytes,
      DecodedVisionBarcodeBytes(bytes: final decoded?) => decoded,
      _ => null,
    };
    if (bytes == null || bytes.isEmpty) {
      return;
    }
    _handled = true;
    final cubit = context.read<LoginCubit>();
    final ok = await cubit.loginWithQrFromScan(bytes);
    if (!mounted) {
      return;
    }
    if (ok) {
      context.go('/home');
      return;
    }
    _handled = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR code sign-in')),
      body: Column(
        children: [
          Expanded(child: MobileScanner(onDetect: _onDetect)),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Scan the QR code shown on your other signed-in device.',
                ),
                const SizedBox(height: 12),
                BlocBuilder<LoginCubit, LoginState>(
                  builder: (context, state) {
                    if (state.submitting) {
                      return const LinearProgressIndicator();
                    }
                    if (state.passwordError == null) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      state.passwordError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
