import 'package:element_x/features/logout/cubit/logout_state.dart';
export 'package:element_x/features/logout/cubit/logout_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/logout/repo/logout_repo.dart';

class LogoutCubit extends Cubit<LogoutState> {
  LogoutCubit(this._repo) : super(const LogoutState());

  final LogoutRepo _repo;

  Future<void> confirm() async {
    await _repo.logout();
    if (isClosed) {
      return;
    }
    emit(const LogoutState(done: true));
  }
}
