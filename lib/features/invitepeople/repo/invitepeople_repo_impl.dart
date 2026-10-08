import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/invitepeople/repo/invitepeople_repo.dart';

class InvitePeopleRepoImpl implements InvitePeopleRepo {
  InvitePeopleRepoImpl(this._store);

  final MatrixStore _store;

  @override
  List<MatrixUser> candidates(String roomId) {
    final room = _store.roomById(roomId);
    final members = room?.memberIds.toSet() ?? {};
    return _store.users.where((user) => !members.contains(user.id)).toList();
  }

  @override
  void invite(String roomId, String userId) => _store.invite(roomId, userId);
}
