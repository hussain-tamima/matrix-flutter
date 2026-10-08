import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/roomdetails/repo/roomdetails_repo.dart';

class RoomDetailsRepoImpl implements RoomDetailsRepo {
  RoomDetailsRepoImpl(this._store);

  final MatrixStore _store;

  @override
  MatrixRoom? room(String roomId) => _store.roomById(roomId);

  @override
  List<RoomMember> members(String roomId) => _store.membersOf(roomId);

  @override
  String displayName(String userId) =>
      _store.userById(userId)?.displayName ?? userId;

  @override
  String notificationMode(String roomId) => _store.notificationMode(roomId);

  @override
  int knockCount(String roomId) => _store.knocksFor(roomId).length;

  @override
  bool isReported(String roomId) => _store.isReported(roomId);

  @override
  void setFavourite(String roomId, {required bool favourite}) {
    _store.setFavourite(roomId, favourite: favourite);
  }

  @override
  Future<void> setNotificationMode(String roomId, String mode) =>
      _store.setNotificationMode(roomId, mode);
}
