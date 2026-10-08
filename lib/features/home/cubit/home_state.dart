import 'package:equatable/equatable.dart';
import 'package:element_x/features/home/models/room_filter.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class HomeState extends Equatable {
  const HomeState({
    this.rooms = const [],
    this.filter = RoomFilter.all,
    this.query = '',
    this.online = true,
    this.syncing = false,
    this.showFtue = false,
  });

  final List<MatrixRoom> rooms;
  final RoomFilter filter;
  final String query;
  final bool online;
  final bool syncing;
  final bool showFtue;

  HomeState copyWith({
    List<MatrixRoom>? rooms,
    RoomFilter? filter,
    String? query,
    bool? online,
    bool? syncing,
    bool? showFtue,
  }) {
    return HomeState(
      rooms: rooms ?? this.rooms,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      online: online ?? this.online,
      syncing: syncing ?? this.syncing,
      showFtue: showFtue ?? this.showFtue,
    );
  }

  @override
  List<Object?> get props => [rooms, filter, query, online, syncing, showFtue];
}
