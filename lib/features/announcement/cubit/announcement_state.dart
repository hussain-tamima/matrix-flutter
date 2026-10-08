import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class AnnouncementState extends Equatable {
  const AnnouncementState({this.announcement});

  final MatrixAnnouncement? announcement;

  @override
  List<Object?> get props => [announcement];
}
