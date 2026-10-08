import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class InvitePeopleState extends Equatable {
  const InvitePeopleState({this.people = const [], this.invited = const []});

  final List<MatrixUser> people;
  final List<String> invited;

  @override
  List<Object?> get props => [people, invited];
}
