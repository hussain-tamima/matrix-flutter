import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class RoomMemberModerationState extends Equatable {
  const RoomMemberModerationState({
    this.member,
    this.displayName = '',
    this.removed = false,
  });

  final RoomMember? member;
  final String displayName;
  final bool removed;

  @override
  List<Object?> get props => [member, displayName, removed];
}
