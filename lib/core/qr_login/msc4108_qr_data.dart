import 'dart:convert';
import 'dart:typed_data';

/// MSC4108 (2024) QR binary payload for sign-in.
enum Msc4108QrIntent { login, reciprocate }

class Msc4108QrData {
  Msc4108QrData({
    required this.publicKey,
    required this.rendezvousUrl,
    required this.intent,
    this.serverName,
  });

  final Uint8List publicKey;
  final Uri rendezvousUrl;
  final Msc4108QrIntent intent;
  final String? serverName;

  static const int version = 0x02;
  static const int intentLogin = 0x03;
  static const int intentReciprocate = 0x04;

  static Msc4108QrData fromBytes(List<int> bytes) {
    if (bytes.length < 36) {
      throw FormatException('QR code is too short');
    }
    final reader = ByteData.sublistView(Uint8List.fromList(bytes));
    var offset = 0;
    final versionByte = reader.getUint8(offset);
    offset += 1;
    if (versionByte != version) {
      throw FormatException('Unsupported QR sign-in version');
    }
    final intentByte = reader.getUint8(offset);
    offset += 1;
    final intent = switch (intentByte) {
      intentLogin => Msc4108QrIntent.login,
      intentReciprocate => Msc4108QrIntent.reciprocate,
      _ => throw FormatException('Unsupported QR sign-in intent'),
    };
    final publicKey = Uint8List.fromList(bytes.sublist(offset, offset + 32));
    offset += 32;
    final urlLen = reader.getUint16(offset, Endian.big);
    offset += 2;
    if (bytes.length < offset + urlLen) {
      throw FormatException('QR code is truncated');
    }
    final urlText = utf8.decode(bytes.sublist(offset, offset + urlLen));
    offset += urlLen;
    final rendezvousUrl = Uri.parse(urlText);
    String? serverName;
    if (intent == Msc4108QrIntent.reciprocate) {
      if (bytes.length < offset + 2) {
        throw FormatException('QR code is missing homeserver');
      }
      final nameLen = reader.getUint16(offset, Endian.big);
      offset += 2;
      if (bytes.length < offset + nameLen) {
        throw FormatException('QR code homeserver is truncated');
      }
      serverName = utf8.decode(bytes.sublist(offset, offset + nameLen));
    } else if (bytes.length >= offset + 2) {
      final nameLen = reader.getUint16(offset, Endian.big);
      offset += 2;
      if (nameLen > 0 && bytes.length >= offset + nameLen) {
        serverName = utf8.decode(bytes.sublist(offset, offset + nameLen));
      }
    }
    return Msc4108QrData(
      publicKey: publicKey,
      rendezvousUrl: rendezvousUrl,
      intent: intent,
      serverName: serverName,
    );
  }

  Uint8List toBytes() {
    final urlBytes = utf8.encode(rendezvousUrl.toString());
    final serverBytes = utf8.encode(serverName ?? '');
    final intentByte = intent == Msc4108QrIntent.login
        ? intentLogin
        : intentReciprocate;
    final buffer = BytesBuilder();
    buffer.addByte(version);
    buffer.addByte(intentByte);
    buffer.add(publicKey);
    buffer.addByte((urlBytes.length >> 8) & 0xff);
    buffer.addByte(urlBytes.length & 0xff);
    buffer.add(urlBytes);
    if (serverName != null && serverName!.isNotEmpty) {
      buffer.addByte((serverBytes.length >> 8) & 0xff);
      buffer.addByte(serverBytes.length & 0xff);
      buffer.add(serverBytes);
    }
    return buffer.toBytes();
  }
}
