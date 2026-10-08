import 'package:element_x/features/roomdetailsedit/cubit/roomdetailsedit_state.dart';
export 'package:element_x/features/roomdetailsedit/cubit/roomdetailsedit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_error.dart';
import 'package:element_x/features/roomdetailsedit/repo/roomdetailsedit_repo.dart';

class RoomDetailsEditCubit extends Cubit<RoomDetailsEditState> {
  RoomDetailsEditCubit(this._repo, this.roomId)
    : super(const RoomDetailsEditState()) {
    final details = _repo.details(roomId);
    if (details != null) {
      emit(RoomDetailsEditState(name: details.name, topic: details.topic));
    }
  }

  final RoomDetailsEditRepo _repo;
  final String roomId;

  Future<void> save({required String name, required String topic}) async {
    if (name.trim().isEmpty) {
      emit(
        RoomDetailsEditState(name: name, topic: topic, error: 'Enter a name'),
      );
      return;
    }
    try {
      await _repo.save(roomId, name: name.trim(), topic: topic.trim());
      emit(
        RoomDetailsEditState(
          name: name.trim(),
          topic: topic.trim(),
          saved: true,
        ),
      );
    } catch (error) {
      if (!isClosed) {
        emit(
          RoomDetailsEditState(
            name: name,
            topic: topic,
            error: matrixError(error),
          ),
        );
      }
    }
  }
}
