import 'dart:typed_data';

import 'package:element_x/core/qr_login/msc4108_qr_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips MSC4108 login QR bytes', () {
    final original = Msc4108QrData(
      publicKey: Uint8List.fromList(List<int>.generate(32, (index) => index)),
      rendezvousUrl: Uri.parse('https://matrix.example/rendezvous/abc'),
      intent: Msc4108QrIntent.login,
      serverName: 'matrix.example',
    );
    final decoded = Msc4108QrData.fromBytes(original.toBytes());
    expect(decoded.publicKey, original.publicKey);
    expect(decoded.rendezvousUrl, original.rendezvousUrl);
    expect(decoded.intent, original.intent);
    expect(decoded.serverName, original.serverName);
  });
}
