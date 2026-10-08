import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/leaveroom/repo/leaveroom_repo.dart';

class LeaveRoomRepoImpl implements LeaveRoomRepo {
  LeaveRoomRepoImpl(this._store);

  final MatrixStore _store;

  @override
  void leave(String roomId) => _store.leaveRoom(roomId);
}
