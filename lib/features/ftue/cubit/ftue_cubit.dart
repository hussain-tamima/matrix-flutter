import 'package:element_x/features/ftue/cubit/ftue_state.dart';
export 'package:element_x/features/ftue/cubit/ftue_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/ftue/repo/ftue_repo.dart';

class FtueCubit extends Cubit<FtueState> {
  FtueCubit(this._repo) : super(const FtueState(page: 0, done: false));

  final FtueRepo _repo;
  static const pageCount = 3;

  void next() {
    if (state.page >= pageCount - 1) {
      return;
    }
    emit(FtueState(page: state.page + 1, done: false));
  }

  Future<void> finish() async {
    await _repo.complete();
    if (isClosed) {
      return;
    }
    emit(FtueState(page: state.page, done: true));
  }
}
