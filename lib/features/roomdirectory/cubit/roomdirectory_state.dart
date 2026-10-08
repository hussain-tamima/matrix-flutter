import 'package:equatable/equatable.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class RoomDirectoryState extends Equatable {
  const RoomDirectoryState({
    this.rooms = const [],
    this.joinedRoomId,
    this.joiningId,
    this.loading = false,
    this.error,
    this.completed = 0,
  });

  final List<MatrixRoom> rooms;
  final String? joinedRoomId;
  final String? joiningId;
  final bool loading;
  final String? error;
  final int completed;

  @override
  List<Object?> get props => [
    rooms,
    joinedRoomId,
    joiningId,
    loading,
    error,
    completed,
  ];
}
