import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class CallState extends Equatable {
  const CallState({
    this.call,
    this.roomName = '',
    this.mediaGeneration = 0,
    this.error,
    this.answering = false,
  });

  final MatrixCall? call;
  final String roomName;
  final int mediaGeneration;
  final String? error;
  final bool answering;

  CallState copyWith({
    MatrixCall? call,
    String? roomName,
    int? mediaGeneration,
    String? error,
    bool clearError = false,
    bool? answering,
  }) {
    return CallState(
      call: call ?? this.call,
      roomName: roomName ?? this.roomName,
      mediaGeneration: mediaGeneration ?? this.mediaGeneration,
      error: clearError ? null : (error ?? this.error),
      answering: answering ?? this.answering,
    );
  }

  @override
  List<Object?> get props => [
    call,
    roomName,
    mediaGeneration,
    error,
    answering,
  ];
}
