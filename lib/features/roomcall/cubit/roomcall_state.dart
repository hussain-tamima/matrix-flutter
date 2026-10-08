import 'package:equatable/equatable.dart';

class RoomCallState extends Equatable {
  const RoomCallState({this.started = false, this.error});

  final bool started;
  final String? error;

  @override
  List<Object?> get props => [started, error];
}
