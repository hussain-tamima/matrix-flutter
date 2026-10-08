import 'package:element_x/features/roommembermoderation/cubit/roommembermoderation_state.dart';
export 'package:element_x/features/roommembermoderation/cubit/roommembermoderation_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:flutter/foundation.dart';
import 'package:element_x/features/roommembermoderation/repo/roommembermoderation_repo.dart';

class RoomMemberModerationCubit extends Cubit<RoomMemberModerationState> {
  RoomMemberModerationCubit(this._repo, this._store, this.roomId, this.userId)
    : super(const RoomMemberModerationState()) {
    _listener = load;
    _store.addListener(_listener);
    load();
  }

  final RoomMemberModerationRepo _repo;
  final MatrixStore _store;
  final String roomId;
  final String userId;
  late final VoidCallback _listener;

  void load() {
    emit(
      RoomMemberModerationState(
        member: _repo.member(roomId, userId),
        displayName: _repo.displayName(userId),
      ),
    );
  }

  void setRole(String role) => _repo.setRole(roomId, userId, role);

  void kick() {
    _repo.kick(roomId, userId);
    emit(
      RoomMemberModerationState(displayName: state.displayName, removed: true),
    );
  }

  void ban() {
    _repo.ban(roomId, userId);
    emit(
      RoomMemberModerationState(displayName: state.displayName, removed: true),
    );
  }

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}
