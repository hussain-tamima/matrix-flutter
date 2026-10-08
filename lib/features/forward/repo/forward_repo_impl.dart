import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/forward/repo/forward_repo.dart';

class ForwardRepoImpl implements ForwardRepo {
  ForwardRepoImpl(this._store);

  final MatrixStore _store;

  @override
  TimelineEvent? event(String eventId) => _store.eventById(eventId);

  @override
  List<MatrixRoom> destinations(String fromRoomId) => _store.rooms
      .where((room) => room.id != fromRoomId && !room.isSpace)
      .toList();

  @override
  Future<void> send(String roomId, String sourceEventId) => _store.forwardEvent(
    destinationRoomId: roomId,
    sourceEventId: sourceEventId,
  );
}
