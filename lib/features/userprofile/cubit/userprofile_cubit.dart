import 'package:element_x/features/userprofile/cubit/userprofile_state.dart';
export 'package:element_x/features/userprofile/cubit/userprofile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:flutter/foundation.dart';
import 'package:element_x/features/userprofile/repo/userprofile_repo.dart';

class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit(this._repo, this._store, this.userId)
    : super(const UserProfileState()) {
    _listener = load;
    _store.addListener(_listener);
    load();
  }

  final UserProfileRepo _repo;
  final MatrixStore _store;
  final String userId;
  late final VoidCallback _listener;

  void load() {
    emit(
      UserProfileState(
        user: _repo.user(userId),
        blocked: _repo.isBlocked(userId),
        verified: _repo.verified,
      ),
    );
  }

  Future<void> message() async {
    final roomId = await _repo.openDirect(userId);
    emit(
      UserProfileState(
        user: state.user,
        blocked: state.blocked,
        verified: state.verified,
        openedRoomId: roomId,
      ),
    );
  }

  void toggleBlock() {
    if (state.blocked) {
      _repo.unblock(userId);
    } else {
      _repo.block(userId);
    }
  }

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}
