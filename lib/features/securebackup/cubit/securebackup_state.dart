import 'package:equatable/equatable.dart';

class SecureBackupState extends Equatable {
  const SecureBackupState({
    required this.enabled,
    this.recoveryKey,
    this.error,
  });

  final bool enabled;
  final String? recoveryKey;
  final String? error;

  @override
  List<Object?> get props => [enabled, recoveryKey, error];
}
