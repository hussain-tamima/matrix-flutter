import 'package:element_x/features/deactivation/cubit/deactivation_state.dart';
export 'package:element_x/features/deactivation/cubit/deactivation_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/deactivation/repo/deactivation_repo.dart';
import 'package:element_x/core/matrix/matrix_error.dart';

class DeactivationCubit extends Cubit<DeactivationState> {
  DeactivationCubit(this._repo) : super(const DeactivationState());

  final DeactivationRepo _repo;

  Future<void> submit({
    required String password,
    required bool confirmed,
  }) async {
    if (!confirmed) {
      emit(
        const DeactivationState(error: 'Confirm that you want to deactivate'),
      );
      return;
    }
    if (password.isEmpty) {
      emit(const DeactivationState(error: 'Enter your password'));
      return;
    }
    try {
      await _repo.deactivate(password: password);
    } catch (error) {
      if (!isClosed) {
        emit(DeactivationState(error: matrixError(error)));
      }
      return;
    }
    if (isClosed) {
      return;
    }
    emit(const DeactivationState(done: true));
  }
}
