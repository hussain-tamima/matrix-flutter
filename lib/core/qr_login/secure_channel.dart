import 'dart:convert';
import 'dart:typed_data';

import 'package:vodozemac/vodozemac.dart' as vod;

/// ECIES payloads for MSC4108 (2024) rendezvous messages.
class Msc4108SecureChannel {
  Msc4108SecureChannel(this._local, this._remote);

  final vod.PkDecryption _local;
  vod.Curve25519PublicKey _remote;

  factory Msc4108SecureChannel.scanner({required Uint8List remotePublicKey}) {
    return Msc4108SecureChannel(
      vod.PkDecryption(),
      vod.Curve25519PublicKey.fromBytes(remotePublicKey),
    );
  }

  factory Msc4108SecureChannel.publisher(vod.PkDecryption local) {
    return Msc4108SecureChannel(
      local,
      vod.Curve25519PublicKey.fromBytes(
        vod.Curve25519PublicKey.fromBase64(local.publicKey).toBytes(),
      ),
    );
  }

  void setRemotePublicKey(Uint8List remotePublicKey) {
    _remote = vod.Curve25519PublicKey.fromBytes(remotePublicKey);
  }

  Uint8List get localPublicKeyBytes =>
      vod.Curve25519PublicKey.fromBase64(_local.publicKey).toBytes();

  Map<String, Object?> encryptJson(Map<String, Object?> payload) {
    final encryption = vod.PkEncryption.fromPublicKey(_remote);
    final message = encryption.encrypt(jsonEncode(payload));
    final encoded = message.toBase64();
    return {
      'ciphertext': encoded.$1,
      'mac': encoded.$2,
      'ephemeral_key': encoded.$3,
    };
  }

  Map<String, Object?> decryptJson(Map<String, Object?> envelope) {
    final ciphertext = envelope['ciphertext'];
    final mac = envelope['mac'];
    final ephemeral = envelope['ephemeral_key'];
    if (ciphertext is! String || mac is! String || ephemeral is! String) {
      throw FormatException('Invalid secure channel envelope');
    }
    final message = vod.PkMessage.fromBase64(
      ciphertext: ciphertext,
      mac: mac,
      ephemeralKey: ephemeral,
    );
    final plaintext = _local.decrypt(message);
    final decoded = jsonDecode(plaintext);
    if (decoded is! Map<String, Object?>) {
      throw FormatException('Invalid secure channel payload');
    }
    return decoded;
  }
}
