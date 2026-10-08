import 'package:element_x/features/createroom/cubit/createroom_state.dart';
export 'package:element_x/features/createroom/cubit/createroom_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/createroom/models/create_room_draft.dart';
import 'package:element_x/core/matrix/matrix_error.dart';
import 'package:element_x/features/createroom/repo/createroom_repo.dart';

class CreateRoomCubit extends Cubit<CreateRoomState> {
  CreateRoomCubit(this._repo) : super(const CreateRoomState());

  final CreateRoomRepo _repo;

  void setPublic(bool value) => emit(state.copyWith(isPublic: value));
  void setEncrypted(bool value) => emit(state.copyWith(isEncrypted: value));
  void setSpace(bool value) => emit(state.copyWith(isSpace: value));

  void clearError() {
    if (state.error != null) emit(state.copyWith(clearError: true));
  }

  Future<void> submit({required String name, required String topic}) async {
    if (state.submitting) return;
    if (name.trim().isEmpty) {
      emit(
        state.copyWith(error: 'create_room_name_required', submitting: false),
      );
      return;
    }
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      final id = await _repo.create(
        CreateRoomDraft(
          name: name.trim(),
          topic: topic.trim(),
          isPublic: state.isPublic,
          isEncrypted: state.isEncrypted,
          isSpace: state.isSpace,
        ),
      );
      emit(state.copyWith(roomId: id, submitting: false, clearError: true));
    } catch (error) {
      if (!isClosed) {
        emit(state.copyWith(error: matrixError(error), submitting: false));
      }
    }
  }
}
