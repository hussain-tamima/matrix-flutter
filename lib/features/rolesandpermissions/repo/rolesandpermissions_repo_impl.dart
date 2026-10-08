import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/rolesandpermissions/repo/rolesandpermissions_repo.dart';

class RolesAndPermissionsRepoImpl implements RolesAndPermissionsRepo {
  RolesAndPermissionsRepoImpl(this._store);

  final MatrixStore _store;

  @override
  List<RoomMember> members(String roomId) => _store.membersOf(roomId);

  @override
  String displayName(String userId) =>
      _store.userById(userId)?.displayName ?? userId;

  @override
  void setRole(String roomId, String userId, String role) =>
      _store.setRole(roomId, userId, role);
}
