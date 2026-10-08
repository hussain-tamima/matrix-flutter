import 'package:element_x/core/matrix/matrix_database.dart';
import 'package:element_x/core/matrix/stale_room.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

void main() {
  const roomId = '!obbayLnkFPpyPGAwtj:st1rop.eko.bz';

  MatrixException forbidden() {
    return MatrixException.fromJson({
      'errcode': 'M_FORBIDDEN',
      'error':
          'User @test1002:st1rop.eko.bz not in room $roomId, and room previews are disabled',
    });
  }

  test('reads the room id from the preview 403', () {
    expect(roomIdMissingOnServer(forbidden()), roomId);
    expect(
      roomIdMissingOnServer(
        MatrixException.fromJson({
          'errcode': 'M_FORBIDDEN',
          'error': 'You are not allowed to join',
        }),
      ),
      isNull,
    );
  });

  test('forgets a joined room once per process', () async {
    final handle = await openMatrixClient(inMemory: true);
    final client = handle.client;
    addTearDown(client.dispose);

    client.rooms.add(Room(id: roomId, client: client));

    expect(queueRoomMissingOnServer(client, forbidden()), roomId);
    await finishStaleRoomCleanup();
    expect(client.getRoomById(roomId), isNull);

    client.rooms.add(Room(id: roomId, client: client));
    expect(queueRoomMissingOnServer(client, forbidden()), roomId);
    await finishStaleRoomCleanup();
    expect(client.getRoomById(roomId)?.membership, Membership.join);
  });
}
