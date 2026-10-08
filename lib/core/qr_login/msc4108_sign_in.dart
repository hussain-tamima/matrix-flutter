import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:element_x/core/qr_login/msc4108_qr_data.dart';
import 'package:element_x/core/qr_login/rendezvous_client.dart';
import 'package:element_x/core/qr_login/secure_channel.dart';

class Msc4108LoginResult {
  const Msc4108LoginResult({
    required this.homeserver,
    required this.userId,
    required this.accessToken,
    required this.deviceId,
    this.encryptionWarning,
  });

  final Uri homeserver;
  final String userId;
  final String accessToken;
  final String deviceId;
  final String? encryptionWarning;
}

/// New-device side of MSC4108 (2024) QR sign-in.
class Msc4108SignIn {
  Msc4108SignIn(this._dio);

  final Dio _dio;

  static const _protocol = 'org.matrix.msc4108.login';

  Future<bool> homeserverSupportsMsc4108(Uri homeserver) async {
    try {
      final versions = await _dio.getUri<Map<String, dynamic>>(
        homeserver.resolve('/_matrix/client/versions'),
      );
      final unstable = versions.data?['unstable_features'];
      if (unstable is Map && unstable['org.matrix.msc4108'] == true) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<Msc4108LoginResult> signInFromQr(List<int> qrBytes) async {
    final qr = Msc4108QrData.fromBytes(qrBytes);
    if (qr.intent != Msc4108QrIntent.login) {
      throw Exception('This QR code is not for signing in on this device');
    }
    final serverName = qr.serverName;
    if (serverName == null || serverName.isEmpty) {
      throw Exception('Homeserver is missing from the QR code');
    }
    final homeserver = _homeserverUri(serverName);
    if (!await homeserverSupportsMsc4108(homeserver)) {
      throw Exception(
        'This homeserver does not support QR sign-in yet. Use password sign-in.',
      );
    }
    final channel = Msc4108SecureChannel.scanner(remotePublicKey: qr.publicKey);
    final rendezvous = RendezvousClient(_dio, qr.rendezvousUrl);

    await rendezvous.sendEncrypted(
      channel.encryptJson({
        'type': 'm.login.protocols',
        'protocols': [_protocol],
        'public_key': base64Encode(channel.localPublicKeyBytes),
      }),
    );

    final protocolReply = await _waitForType(
      rendezvous,
      channel,
      'm.login.protocol',
      timeout: const Duration(seconds: 60),
    );
    final acceptedProtocol = protocolReply['protocol'];
    if (acceptedProtocol != _protocol) {
      throw Exception('The other device does not support QR sign-in');
    }

    await rendezvous.sendEncrypted(
      channel.encryptJson({
        'type': 'm.login.protocol_accepted',
        'protocol': _protocol,
      }),
    );

    final success = await _waitForType(
      rendezvous,
      channel,
      'm.login.success',
      timeout: const Duration(minutes: 3),
    );

    final userId = success['user_id'] as String?;
    final accessToken = success['access_token'] as String?;
    final deviceId = success['device_id'] as String?;
    if (userId == null ||
        accessToken == null ||
        deviceId == null ||
        userId.isEmpty ||
        accessToken.isEmpty ||
        deviceId.isEmpty) {
      throw Exception('Sign-in did not complete on the other device');
    }

    return Msc4108LoginResult(
      homeserver: homeserver,
      userId: userId,
      accessToken: accessToken,
      deviceId: deviceId,
      encryptionWarning: success['secrets'] == null
          ? 'Sign-in succeeded. Verify this device for full encryption.'
          : null,
    );
  }

  Future<Map<String, Object?>> _waitForType(
    RendezvousClient rendezvous,
    Msc4108SecureChannel channel,
    String type, {
    required Duration timeout,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final envelope = await rendezvous.pollEncrypted(
        timeout: const Duration(seconds: 5),
      );
      if (envelope == null) {
        continue;
      }
      final payload = channel.decryptJson(envelope);
      if (payload['type'] == 'm.login.failure') {
        throw Exception('The other device declined QR sign-in');
      }
      if (payload['type'] == 'm.login.declined') {
        throw Exception('QR sign-in was declined');
      }
      if (payload['type'] == type) {
        return payload;
      }
    }
    throw Exception('Timed out waiting for the other device');
  }

  Uri _homeserverUri(String serverName) {
    final trimmed = serverName.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Uri.parse(trimmed);
    }
    return Uri.https(trimmed, '');
  }
}
