import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class ForwardState extends Equatable {
  const ForwardState({
    this.event,
    this.rooms = const [],
    this.sentTo,
    this.sending = false,
    this.error,
  });

  final TimelineEvent? event;
  final List<MatrixRoom> rooms;
  final String? sentTo;
  final bool sending;
  final String? error;

  @override
  List<Object?> get props => [event, rooms, sentTo, sending, error];
}
