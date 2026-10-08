import 'package:element_x/features/lockscreen/cubit/lockscreen_state.dart';
export 'package:element_x/features/lockscreen/cubit/lockscreen_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/lockscreen/repo/lockscreen_repo.dart';

class LockscreenCubit extends Cubit<LockscreenState> {
  LockscreenCubit(this._repo) : super(const LockscreenState());

  final LockscreenRepo _repo;

  bool submit(String pin) {
    if (pin.trim().length < 4) {
      emit(const LockscreenState(error: 'Enter your 4-digit PIN'));
      return false;
    }
    if (!_repo.unlock(pin.trim())) {
      emit(const LockscreenState(error: 'Incorrect PIN'));
      return false;
    }
    emit(const LockscreenState());
    return true;
  }
}
