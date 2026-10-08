import 'package:equatable/equatable.dart';

class JoinRoomState extends Equatable {
  const JoinRoomState({
    this.error,
    this.roomId,
    this.submitting = false,
    this.completed = 0,
  });

  final String? error;
  final String? roomId;
  final bool submitting;
  final int completed;

  @override
  List<Object?> get props => [error, roomId, submitting, completed];
}
