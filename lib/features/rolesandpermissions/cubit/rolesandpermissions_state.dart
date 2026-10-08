import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class RolesAndPermissionsState extends Equatable {
  const RolesAndPermissionsState({this.members = const []});

  final List<RoomMember> members;

  @override
  List<Object?> get props => [members];
}
