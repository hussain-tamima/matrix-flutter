import 'package:element_x/core/matrix/matrix_error.dart';
import 'package:element_x/features/forward/cubit/forward_state.dart';
export 'package:element_x/features/forward/cubit/forward_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/forward/repo/forward_repo.dart';

class ForwardCubit extends Cubit<ForwardState> {
  ForwardCubit(this._repo, this.roomId, this.eventId)
    : super(
        ForwardState(
          event: _repo.event(eventId),
          rooms: _repo.destinations(roomId),
        ),
      );

  final ForwardRepo _repo;
  final String roomId;
  final String eventId;

  Future<void> send(String destinationId) async {
    if (state.event == null || state.sending) {
      return;
    }
    emit(ForwardState(event: state.event, rooms: state.rooms, sending: true));
    try {
      await _repo.send(destinationId, eventId);
      emit(
        ForwardState(
          event: state.event,
          rooms: state.rooms,
          sentTo: destinationId,
        ),
      );
    } catch (error) {
      emit(
        ForwardState(
          event: state.event,
          rooms: state.rooms,
          error: matrixError(error),
        ),
      );
    }
  }
}
