import 'package:element_x/features/roomcall/cubit/roomcall_state.dart';
export 'package:element_x/features/roomcall/cubit/roomcall_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_error.dart';
import 'package:element_x/features/roomcall/repo/roomcall_repo.dart';

class RoomCallCubit extends Cubit<RoomCallState> {
  RoomCallCubit(this._repo, this.roomId) : super(const RoomCallState());

  final RoomCallRepo _repo;
  final String roomId;

  Future<void> start({bool video = false}) async {
    try {
      await _repo.start(roomId, video: video);
      if (!isClosed) {
        emit(const RoomCallState(started: true));
      }
    } catch (error) {
      if (!isClosed) {
        emit(RoomCallState(error: matrixError(error)));
      }
    }
  }
}
