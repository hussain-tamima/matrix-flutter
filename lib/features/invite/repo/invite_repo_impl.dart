import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/invite/repo/invite_repo.dart';

class InviteRepoImpl implements InviteRepo {
  InviteRepoImpl(this._store);

  final MatrixStore _store;

  @override
  MatrixRoom? room(String roomId) => _store.roomById(roomId);
}
