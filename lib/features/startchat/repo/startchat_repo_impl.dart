import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/core/utils/matrix_user_ids.dart';
import 'package:element_x/features/startchat/repo/startchat_repo.dart';

class StartChatRepoImpl implements StartChatRepo {
  StartChatRepoImpl(this._store);

  final MatrixStore _store;

  @override
  String get homeserver => defaultUserHomeserver(_store);

  @override
  List<MatrixUser> people() {
    final blocked = _store.preferences.blockedUserIds.toSet();
    return _store.users
        .where(
          (user) =>
              user.id != _store.currentUser.id && !blocked.contains(user.id),
        )
        .toList();
  }

  @override
  Future<String> openDirect(String userId) => _store.ensureDirectChat(userId);
}
