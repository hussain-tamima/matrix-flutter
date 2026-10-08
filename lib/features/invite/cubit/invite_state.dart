import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class InviteState extends Equatable {
  const InviteState({this.room});

  final MatrixRoom? room;

  @override
  List<Object?> get props => [room];
}
