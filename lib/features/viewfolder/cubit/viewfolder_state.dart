import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class ViewFolderState extends Equatable {
  const ViewFolderState({this.files = const []});

  final List<TimelineEvent> files;

  @override
  List<Object?> get props => [files];
}
