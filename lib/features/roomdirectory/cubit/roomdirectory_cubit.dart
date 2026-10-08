import 'package:element_x/features/roomdirectory/cubit/roomdirectory_state.dart';
export 'package:element_x/features/roomdirectory/cubit/roomdirectory_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_error.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:flutter/foundation.dart';
import 'package:element_x/features/roomdirectory/repo/roomdirectory_repo.dart';

class RoomDirectoryCubit extends Cubit<RoomDirectoryState> {
  RoomDirectoryCubit(this._repo, this._store)
    : super(RoomDirectoryState(rooms: _repo.rooms(), loading: true)) {
    _listener = reload;
    _store.addListener(_listener);
    _store.refreshDirectory();
  }

  final RoomDirectoryRepo _repo;
  final MatrixStore _store;
  late final VoidCallback _listener;

  void reload() {
    if (state.joinedRoomId != null) return;
    emit(
      RoomDirectoryState(
        rooms: _repo.rooms(),
        loading: _store.directoryLoading,
        joiningId: state.joiningId,
        error: state.joiningId == null ? state.error : null,
        completed: state.completed,
      ),
    );
  }

  Future<void> join(String roomId) async {
    if (state.joiningId != null) return;
    emit(
      RoomDirectoryState(
        rooms: state.rooms,
        loading: state.loading,
        joiningId: roomId,
        completed: state.completed,
      ),
    );
    try {
      await _repo.join(roomId);
      if (isClosed) return;
      emit(
        RoomDirectoryState(
          rooms: _repo.rooms(),
          joinedRoomId: roomId,
          completed: state.completed + 1,
        ),
      );
    } catch (error) {
      if (!isClosed) {
        emit(
          RoomDirectoryState(
            rooms: _repo.rooms(),
            error: matrixError(error),
            completed: state.completed,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}
