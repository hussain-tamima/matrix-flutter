import 'package:equatable/equatable.dart';

class CreateRoomState extends Equatable {
  const CreateRoomState({
    this.isPublic = false,
    this.isEncrypted = true,
    this.isSpace = false,
    this.submitting = false,
    this.error,
    this.roomId,
  });

  final bool isPublic;
  final bool isEncrypted;
  final bool isSpace;
  final bool submitting;
  final String? error;
  final String? roomId;

  CreateRoomState copyWith({
    bool? isPublic,
    bool? isEncrypted,
    bool? isSpace,
    bool? submitting,
    String? error,
    String? roomId,
    bool clearError = false,
  }) {
    return CreateRoomState(
      isPublic: isPublic ?? this.isPublic,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      isSpace: isSpace ?? this.isSpace,
      submitting: submitting ?? this.submitting,
      error: clearError ? null : error ?? this.error,
      roomId: roomId ?? this.roomId,
    );
  }

  @override
  List<Object?> get props => [
    isPublic,
    isEncrypted,
    isSpace,
    submitting,
    error,
    roomId,
  ];
}
