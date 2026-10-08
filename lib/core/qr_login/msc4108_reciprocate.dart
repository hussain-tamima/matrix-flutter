import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:element_x/core/qr_login/msc4108_qr_data.dart';
import 'package:element_x/core/qr_login/rendezvous_client.dart';
import 'package:element_x/core/qr_login/secure_channel.dart';
import 'package:matrix/matrix.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

/// Existing-device side: show a QR so another phone can sign in.
class Msc4108Reciprocate {
  Msc4108Reciprocate(this._dio, this._client);

  final Dio _dio;
  final Client _client;

  Future<({Uint8List qrBytes, String warning})> createLoginQr() async {
    final homeserver = _client.homeserver;
    if (homeserver == null) {
      throw Exception('Not signed in');
    }
    final rendezvousUrl = await _createRendezvous(homeserver);
    final localDecryption = vod.PkDecryption();
    final publicKey = vod.Curve25519PublicKey.fromBase64(
      localDecryption.publicKey,
    ).toBytes();
    final qr = Msc4108QrData(
      publicKey: Uint8List.fromList(publicKey),
      rendezvousUrl: rendezvousUrl,
      intent: Msc4108QrIntent.login,
      serverName: homeserver.host,
    );
    final rendezvous = RendezvousClient(_dio, rendezvousUrl);
    unawaited(_serveLogin(rendezvous, localDecryption));
    return (
      qrBytes: qr.toBytes(),
      warning:
          'Keep this screen open until the other device finishes signing in.',
    );
  }

  Future<Uri> _createRendezvous(Uri homeserver) async {
    final response = await _dio.postUri<Map<String, dynamic>>(
      homeserver.resolve(
        '/_matrix/client/unstable/org.matrix.msc4108/rendezvous',
      ),
      options: Options(
        headers: {
          if (_client.accessToken != null)
            'Authorization': 'Bearer ${_client.accessToken}',
        },
      ),
    );
    final url = response.data?['url'];
    if (url is! String || url.isEmpty) {
      throw Exception('Could not start QR sign-in session');
    }
    return Uri.parse(url);
  }

  Future<void> _serveLogin(
    RendezvousClient rendezvous,
    vod.PkDecryption localDecryption,
  ) async {
    try {
      final channel = Msc4108SecureChannel.publisher(localDecryption);
      final first = await rendezvous.pollEncrypted(
        timeout: const Duration(minutes: 3),
      );
      if (first == null) {
        return;
      }
      final payload = channel.decryptJson(first);
      if (payload['type'] != 'm.login.protocols') {
        return;
      }
      final remoteKey = payload['public_key'];
      if (remoteKey is List) {
        channel.setRemotePublicKey(Uint8List.fromList(remoteKey.cast<int>()));
      } else if (remoteKey is String) {
        channel.setRemotePublicKey(base64.decode(remoteKey));
      }
      await rendezvous.sendEncrypted(
        channel.encryptJson({
          'type': 'm.login.protocol',
          'protocol': 'org.matrix.msc4108.login',
        }),
      );
      final accepted = await rendezvous.pollEncrypted(
        timeout: const Duration(minutes: 3),
      );
      if (accepted == null) {
        return;
      }
      final acceptedPayload = channel.decryptJson(accepted);
      if (acceptedPayload['type'] != 'm.login.protocol_accepted') {
        return;
      }
      await rendezvous.sendEncrypted(
        channel.encryptJson({
          'type': 'm.login.success',
          'user_id': _client.userID,
          'access_token': _client.accessToken,
          'device_id': _client.deviceID,
        }),
      );
    } catch (_) {}
  }
}
