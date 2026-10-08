import 'package:element_x/features/joinroom/cubit/joinroom_state.dart';
export 'package:element_x/features/joinroom/cubit/joinroom_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_error.dart';
import 'package:element_x/features/joinroom/repo/joinroom_repo.dart';

class JoinRoomCubit extends Cubit<JoinRoomState> {
  JoinRoomCubit(this._repo) : super(const JoinRoomState());

  final JoinRoomRepo _repo;

  void clearError() {
    if (state.error != null) {
      emit(JoinRoomState(completed: state.completed));
    }
  }

  Future<void> submit(String address) async {
    if (state.submitting) return;
    final value = address.trim();
    if (value.isEmpty) {
      emit(
        JoinRoomState(error: 'join_room_missing', completed: state.completed),
      );
      return;
    }
    emit(JoinRoomState(submitting: true, completed: state.completed));
    try {
      final roomId = await _repo.join(value);
      if (roomId == null) {
        emit(
          JoinRoomState(
            error: 'join_room_not_found',
            completed: state.completed,
          ),
        );
        return;
      }
      emit(JoinRoomState(roomId: roomId, completed: state.completed + 1));
    } catch (error) {
      if (!isClosed) {
        emit(
          JoinRoomState(error: matrixError(error), completed: state.completed),
        );
      }
    }
  }
}
