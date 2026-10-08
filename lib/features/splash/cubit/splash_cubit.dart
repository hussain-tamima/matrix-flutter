import 'package:element_x/features/splash/cubit/splash_state.dart';
export 'package:element_x/features/splash/cubit/splash_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/splash/repo/splash_repo.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit(this._repo) : super(const SplashState());

  final SplashRepo _repo;
  static const bootDelay = Duration(milliseconds: 300);

  Future<void> decide() async {
    await Future<void>.delayed(bootDelay);
    if (isClosed) {
      return;
    }
    emit(SplashState(route: _repo.nextRoute()));
  }
}
