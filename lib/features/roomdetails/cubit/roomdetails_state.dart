import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class RoomDetailsState extends Equatable {
  const RoomDetailsState({
    this.room,
    this.members = const [],
    this.notificationMode = 'all',
    this.knockCount = 0,
    this.reported = false,
    this.missing = false,
  });

  final MatrixRoom? room;
  final List<RoomMember> members;
  final String notificationMode;
  final int knockCount;
  final bool reported;
  final bool missing;

  @override
  List<Object?> get props => [
    room,
    members,
    notificationMode,
    knockCount,
    reported,
    missing,
  ];
}
