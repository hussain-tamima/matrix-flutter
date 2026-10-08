import 'package:element_x/features/startchat/cubit/startchat_state.dart';
export 'package:element_x/features/startchat/cubit/startchat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_error.dart';
import 'package:element_x/features/startchat/repo/startchat_repo.dart';

class StartChatCubit extends Cubit<StartChatState> {
  StartChatCubit(this._repo) : super(StartChatState(people: _repo.people()));

  final StartChatRepo _repo;

  Future<void> open(String userId) async {
    final id = userId.trim();
    if (state.openingUserId != null) return;
    if (id.isEmpty) {
      emit(state.copyWith(error: 'start_chat_id_required', clearOpening: true));
      return;
    }
    emit(state.copyWith(openingUserId: id, clearError: true));
    try {
      final roomId = await _repo.openDirect(id);
      emit(
        state.copyWith(
          openedRoomId: roomId,
          completed: state.completed + 1,
          clearOpening: true,
          clearError: true,
        ),
      );
    } catch (error) {
      if (!isClosed) {
        emit(state.copyWith(error: matrixError(error), clearOpening: true));
      }
    }
  }

  void clearError() {
    if (state.error != null) emit(state.copyWith(clearError: true));
  }
}
