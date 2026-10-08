import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/userprofile/repo/userprofile_repo.dart';

class UserProfileRepoImpl implements UserProfileRepo {
  UserProfileRepoImpl(this._store);

  final MatrixStore _store;

  @override
  MatrixUser? user(String userId) => _store.userById(userId);

  @override
  bool isBlocked(String userId) =>
      _store.preferences.blockedUserIds.contains(userId);

  @override
  bool get verified => _store.preferences.sessionVerified;

  @override
  Future<String> openDirect(String userId) => _store.ensureDirectChat(userId);

  @override
  void block(String userId) => _store.blockUser(userId);

  @override
  void unblock(String userId) => _store.unblockUser(userId);
}
