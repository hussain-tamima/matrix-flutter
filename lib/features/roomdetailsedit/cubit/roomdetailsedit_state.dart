import 'package:equatable/equatable.dart';

class RoomDetailsEditState extends Equatable {
  const RoomDetailsEditState({
    this.name = '',
    this.topic = '',
    this.error,
    this.saved = false,
  });

  final String name;
  final String topic;
  final String? error;
  final bool saved;

  @override
  List<Object?> get props => [name, topic, error, saved];
}
