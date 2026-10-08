import 'package:element_x/features/location/cubit/location_state.dart';
export 'package:element_x/features/location/cubit/location_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/location/repo/location_repo.dart';
import 'package:element_x/core/matrix/matrix_error.dart';

class LocationCubit extends Cubit<LocationState> {
  LocationCubit(this._repo, this.roomId)
    : super(LocationState(enabled: _repo.sharingEnabled));

  final LocationRepo _repo;
  final String roomId;

  Future<void> share(String label) async {
    if (!state.enabled) {
      emit(
        LocationState(
          enabled: false,
          error: 'Location sharing is turned off in settings',
        ),
      );
      return;
    }
    final place = label.trim().isEmpty ? 'Current location' : label.trim();
    try {
      await _repo.share(roomId, place);
      if (!isClosed) {
        emit(LocationState(enabled: true, shared: true));
      }
    } catch (error) {
      if (!isClosed) {
        emit(LocationState(enabled: true, error: matrixError(error)));
      }
    }
  }
}
