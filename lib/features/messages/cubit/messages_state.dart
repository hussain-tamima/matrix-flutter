import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class MessagesState extends Equatable {
  const MessagesState({
    this.room,
    this.events = const [],
    this.replyCounts = const {},
    this.typing = false,
    this.missing = false,
    this.recording = false,
    this.groupCall,
    this.error,
  });

  final MatrixRoom? room;
  final List<TimelineEvent> events;
  final Map<String, int> replyCounts;
  final bool typing;
  final bool missing;
  final bool recording;
  final MatrixGroupCall? groupCall;
  final String? error;

  @override
  List<Object?> get props => [
    room,
    events,
    replyCounts,
    typing,
    missing,
    recording,
    groupCall,
    error,
  ];
}
