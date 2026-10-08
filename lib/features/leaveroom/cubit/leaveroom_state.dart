import 'package:equatable/equatable.dart';

class LeaveRoomState extends Equatable {
  const LeaveRoomState({this.left = false});

  final bool left;

  @override
  List<Object?> get props => [left];
}
