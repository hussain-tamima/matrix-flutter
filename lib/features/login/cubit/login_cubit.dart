import 'package:element_x/features/login/cubit/login_state.dart';
export 'package:element_x/features/login/cubit/login_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/login/repo/login_repo.dart';
import 'package:element_x/core/matrix/matrix_error.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._repo) : super(const LoginState());

  final LoginRepo _repo;

  void setHomeserver(String value) {
    emit(state.copyWith(homeserver: value, clearHomeserverError: true));
  }

  bool confirmHomeserver() {
    if (state.homeserver.trim().isEmpty) {
      emit(state.copyWith(homeserverError: 'Enter a homeserver'));
      return false;
    }
    emit(state.copyWith(clearHomeserverError: true));
    return true;
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    final usernameError = username.trim().isEmpty
        ? 'Enter your username'
        : null;
    final passwordError = password.isEmpty ? 'Enter your password' : null;
    if (usernameError != null || passwordError != null) {
      emit(
        state.copyWith(
          username: username,
          usernameError: usernameError,
          passwordError: passwordError,
          clearUsernameError: usernameError == null,
          clearPasswordError: passwordError == null,
        ),
      );
      return false;
    }
    emit(
      state.copyWith(
        username: username.trim(),
        submitting: true,
        clearUsernameError: true,
        clearPasswordError: true,
      ),
    );
    try {
      await _repo.login(
        homeserver: state.homeserver,
        username: username.trim(),
        password: password,
      );
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(submitting: false, passwordError: matrixError(error)),
        );
      }
      return false;
    }
    if (isClosed) {
      return false;
    }
    emit(state.copyWith(submitting: false));
    return true;
  }

  Future<bool> loginWithQrFromScan(List<int> qrBytes) async {
    emit(state.copyWith(submitting: true, clearPasswordError: true));
    try {
      final warning = await _repo.loginWithQrPayload(qrBytes);
      if (!isClosed) {
        emit(state.copyWith(submitting: false, passwordError: warning));
      }
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(submitting: false, passwordError: matrixError(error)),
        );
      }
      return false;
    }
  }

  Future<bool> createAccount({
    required String displayName,
    required String username,
    required String password,
  }) async {
    final displayNameError = displayName.trim().isEmpty
        ? 'Enter a display name'
        : null;
    final usernameError = username.trim().isEmpty ? 'Enter a username' : null;
    final passwordError = password.isEmpty ? 'Enter a password' : null;
    if (displayNameError != null ||
        usernameError != null ||
        passwordError != null ||
        !confirmHomeserver()) {
      emit(
        state.copyWith(
          displayName: displayName,
          username: username,
          displayNameError: displayNameError,
          usernameError: usernameError,
          passwordError: passwordError,
          clearDisplayNameError: displayNameError == null,
          clearUsernameError: usernameError == null,
          clearPasswordError: passwordError == null,
        ),
      );
      return false;
    }
    emit(
      state.copyWith(
        submitting: true,
        displayName: displayName.trim(),
        username: username.trim(),
      ),
    );
    try {
      await _repo.createAccount(
        homeserver: state.homeserver,
        username: username.trim(),
        password: password,
        displayName: displayName.trim(),
      );
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(submitting: false, passwordError: matrixError(error)),
        );
      }
      return false;
    }
    if (isClosed) {
      return false;
    }
    emit(state.copyWith(submitting: false));
    return true;
  }
}
