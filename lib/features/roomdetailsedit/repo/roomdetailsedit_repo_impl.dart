import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/roomdetailsedit/repo/roomdetailsedit_repo.dart';

class RoomDetailsEditRepoImpl implements RoomDetailsEditRepo {
  RoomDetailsEditRepoImpl(this._store);

  final MatrixStore _store;

  @override
  ({String name, String topic})? details(String roomId) {
    final room = _store.roomById(roomId);
    if (room == null) {
      return null;
    }
    return (name: room.name, topic: room.topic);
  }

  @override
  Future<void> save(
    String roomId, {
    required String name,
    required String topic,
  }) {
    return _store.updateRoom(roomId, name: name, topic: topic);
  }
}
