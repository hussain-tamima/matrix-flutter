import 'package:element_x/features/rageshake/cubit/rageshake_state.dart';
export 'package:element_x/features/rageshake/cubit/rageshake_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/rageshake/repo/rageshake_repo.dart';

class RageshakeCubit extends Cubit<RageshakeState> {
  RageshakeCubit(this._repo) : super(const RageshakeState());

  final RageshakeRepo _repo;

  Future<void> submit(String description) async {
    if (description.trim().isEmpty) {
      emit(const RageshakeState(error: 'Describe the problem'));
      return;
    }
    await _repo.submit(description.trim());
    if (isClosed) {
      return;
    }
    emit(const RageshakeState(sent: true));
  }
}
