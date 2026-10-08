import 'package:element_x/core/di/di.dart';
import 'package:element_x/core/qr_login/qr_login_service.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class LinkNewDeviceSignInQrScreen extends StatefulWidget {
  const LinkNewDeviceSignInQrScreen({super.key});

  @override
  State<LinkNewDeviceSignInQrScreen> createState() =>
      _LinkNewDeviceSignInQrScreenState();
}

class _LinkNewDeviceSignInQrScreenState
    extends State<LinkNewDeviceSignInQrScreen> {
  List<int>? _qrBytes;
  String? _warning;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final created = await sl<QrLoginService>().createReciprocateQr();
      setState(() {
        _qrBytes = created.qrBytes;
        _warning = created.warning;
      });
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in another phone')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Sign in another phone',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan this QR code on the new device. This is different from verifying an existing session with emoji matching.',
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else if (_qrBytes == null)
            const Center(child: CircularProgressIndicator())
          else
            Center(
              child: QrImageView(
                data: String.fromCharCodes(_qrBytes!),
                version: QrVersions.auto,
                size: 240,
              ),
            ),
          if (_warning != null) ...[
            const SizedBox(height: 16),
            Text(_warning!),
          ],
        ],
      ),
    );
  }
}
