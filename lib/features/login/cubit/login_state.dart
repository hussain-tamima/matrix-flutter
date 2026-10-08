import 'package:equatable/equatable.dart';
import 'package:element_x/core/config/app_config.dart';

class LoginState extends Equatable {
  const LoginState({
    this.homeserver = AppConfig.defaultHomeserver,
    this.username = '',
    this.displayName = '',
    this.homeserverError,
    this.usernameError,
    this.passwordError,
    this.displayNameError,
    this.submitting = false,
  });

  final String homeserver;
  final String username;
  final String displayName;
  final String? homeserverError;
  final String? usernameError;
  final String? passwordError;
  final String? displayNameError;
  final bool submitting;

  LoginState copyWith({
    String? homeserver,
    String? username,
    String? displayName,
    String? homeserverError,
    String? usernameError,
    String? passwordError,
    String? displayNameError,
    bool clearHomeserverError = false,
    bool clearUsernameError = false,
    bool clearPasswordError = false,
    bool clearDisplayNameError = false,
    bool? submitting,
  }) {
    return LoginState(
      homeserver: homeserver ?? this.homeserver,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      homeserverError: clearHomeserverError
          ? null
          : homeserverError ?? this.homeserverError,
      usernameError: clearUsernameError
          ? null
          : usernameError ?? this.usernameError,
      passwordError: clearPasswordError
          ? null
          : passwordError ?? this.passwordError,
      displayNameError: clearDisplayNameError
          ? null
          : displayNameError ?? this.displayNameError,
      submitting: submitting ?? this.submitting,
    );
  }

  @override
  List<Object?> get props => [
    homeserver,
    username,
    displayName,
    homeserverError,
    usernameError,
    passwordError,
    displayNameError,
    submitting,
  ];
}
