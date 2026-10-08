import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/createroom/models/create_room_draft.dart';
import 'package:element_x/features/createroom/repo/createroom_repo.dart';

class CreateRoomRepoImpl implements CreateRoomRepo {
  CreateRoomRepoImpl(this._store);

  final MatrixStore _store;

  @override
  Future<String> create(CreateRoomDraft draft) async {
    final room = await _store.createRoom(
      name: draft.name,
      topic: draft.topic,
      isPublic: draft.isPublic,
      isEncrypted: draft.isEncrypted,
      isSpace: draft.isSpace,
    );
    return room.id;
  }
}
