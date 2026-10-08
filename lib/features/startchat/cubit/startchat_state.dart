import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class StartChatState extends Equatable {
  const StartChatState({
    this.people = const [],
    this.openedRoomId,
    this.error,
    this.openingUserId,
    this.completed = 0,
  });

  final List<MatrixUser> people;
  final String? openedRoomId;
  final String? error;
  final String? openingUserId;
  final int completed;

  StartChatState copyWith({
    List<MatrixUser>? people,
    String? openedRoomId,
    String? error,
    String? openingUserId,
    int? completed,
    bool clearError = false,
    bool clearOpening = false,
  }) {
    return StartChatState(
      people: people ?? this.people,
      openedRoomId: openedRoomId ?? this.openedRoomId,
      error: clearError ? null : error ?? this.error,
      openingUserId: clearOpening ? null : openingUserId ?? this.openingUserId,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => [
    people,
    openedRoomId,
    error,
    openingUserId,
    completed,
  ];
}
