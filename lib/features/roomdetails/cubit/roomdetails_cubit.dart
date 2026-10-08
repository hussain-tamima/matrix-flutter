import 'package:element_x/features/roomdetails/cubit/roomdetails_state.dart';
export 'package:element_x/features/roomdetails/cubit/roomdetails_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:flutter/foundation.dart';
import 'package:element_x/features/roomdetails/repo/roomdetails_repo.dart';

class RoomDetailsCubit extends Cubit<RoomDetailsState> {
  RoomDetailsCubit(this._repo, this._store, this.roomId)
    : super(const RoomDetailsState()) {
    _listener = load;
    _store.addListener(_listener);
    load();
  }

  final RoomDetailsRepo _repo;
  final MatrixStore _store;
  final String roomId;
  late final VoidCallback _listener;

  void load() {
    final room = _repo.room(roomId);
    if (room == null) {
      emit(const RoomDetailsState(missing: true));
      return;
    }
    emit(
      RoomDetailsState(
        room: room,
        members: _repo.members(roomId),
        notificationMode: _repo.notificationMode(roomId),
        knockCount: _repo.knockCount(roomId),
        reported: _repo.isReported(roomId),
      ),
    );
  }

  void setFavourite(bool value) => _repo.setFavourite(roomId, favourite: value);

  Future<void> setNotificationMode(String mode) =>
      _repo.setNotificationMode(roomId, mode);

  String nameFor(String userId) => _repo.displayName(userId);

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}
