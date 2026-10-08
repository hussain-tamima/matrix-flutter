import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class UserProfileState extends Equatable {
  const UserProfileState({
    this.user,
    this.blocked = false,
    this.verified = false,
    this.openedRoomId,
  });

  final MatrixUser? user;
  final bool blocked;
  final bool verified;
  final String? openedRoomId;

  @override
  List<Object?> get props => [user, blocked, verified, openedRoomId];
}
