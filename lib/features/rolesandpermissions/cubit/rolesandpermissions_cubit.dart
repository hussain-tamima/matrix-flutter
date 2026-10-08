import 'package:element_x/features/rolesandpermissions/cubit/rolesandpermissions_state.dart';
export 'package:element_x/features/rolesandpermissions/cubit/rolesandpermissions_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:flutter/foundation.dart';
import 'package:element_x/features/rolesandpermissions/repo/rolesandpermissions_repo.dart';

class RolesAndPermissionsCubit extends Cubit<RolesAndPermissionsState> {
  RolesAndPermissionsCubit(this._repo, this._store, this.roomId)
    : super(const RolesAndPermissionsState()) {
    _listener = load;
    _store.addListener(_listener);
    load();
  }

  final RolesAndPermissionsRepo _repo;
  final MatrixStore _store;
  final String roomId;
  late final VoidCallback _listener;

  void load() => emit(RolesAndPermissionsState(members: _repo.members(roomId)));

  void setRole(String userId, String role) =>
      _repo.setRole(roomId, userId, role);

  String nameFor(String userId) => _repo.displayName(userId);

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}
