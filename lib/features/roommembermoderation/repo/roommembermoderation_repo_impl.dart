import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/roommembermoderation/repo/roommembermoderation_repo.dart';

class RoomMemberModerationRepoImpl implements RoomMemberModerationRepo {
  RoomMemberModerationRepoImpl(this._store);

  final MatrixStore _store;

  @override
  RoomMember? member(String roomId, String userId) {
    for (final member in _store.membersOf(roomId)) {
      if (member.userId == userId) {
        return member;
      }
    }
    return null;
  }

  @override
  String displayName(String userId) =>
      _store.userById(userId)?.displayName ?? userId;

  @override
  void setRole(String roomId, String userId, String role) =>
      _store.setRole(roomId, userId, role);

  @override
  void kick(String roomId, String userId) => _store.kick(roomId, userId);

  @override
  void ban(String roomId, String userId) => _store.ban(roomId, userId);
}
