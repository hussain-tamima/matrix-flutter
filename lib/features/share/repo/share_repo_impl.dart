import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/share/repo/share_repo.dart';

class ShareRepoImpl implements ShareRepo {
  ShareRepoImpl(this._store);

  final MatrixStore _store;

  @override
  List<MatrixRoom> rooms() => _store.rooms;

  @override
  void share(String roomId, String text) {
    _store.sendMessage(roomId: roomId, body: text);
  }
}
