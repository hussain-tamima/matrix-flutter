import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class ShareState extends Equatable {
  const ShareState({
    required this.text,
    this.rooms = const [],
    this.sent = false,
  });

  final String text;
  final List<MatrixRoom> rooms;
  final bool sent;

  @override
  List<Object?> get props => [text, rooms, sent];
}
