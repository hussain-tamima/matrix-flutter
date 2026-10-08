import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/joinroom/repo/joinroom_repo.dart';

class JoinRoomRepoImpl implements JoinRoomRepo {
  JoinRoomRepoImpl(this._store);

  final MatrixStore _store;

  @override
  Future<String?> join(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (_store.isJoined(trimmed)) {
      return trimmed;
    }
    return _store.joinRoom(trimmed);
  }
}
