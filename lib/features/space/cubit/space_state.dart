import 'package:equatable/equatable.dart';
import 'package:element_x/features/space/models/space_summary.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class SpaceState extends Equatable {
  const SpaceState({this.summary, this.rooms = const []});

  final SpaceSummary? summary;
  final List<MatrixRoom> rooms;

  @override
  List<Object?> get props => [summary, rooms];
}
