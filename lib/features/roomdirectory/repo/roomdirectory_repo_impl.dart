import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/roomdirectory/repo/roomdirectory_repo.dart';

class RoomDirectoryRepoImpl implements RoomDirectoryRepo {
  RoomDirectoryRepoImpl(this._store);

  final MatrixStore _store;

  @override
  List<MatrixRoom> rooms() => _store.directory;

  @override
  Future<void> join(String roomId) => _store.joinRoom(roomId);
}
