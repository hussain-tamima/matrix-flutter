import 'package:element_x/features/home/cubit/home_state.dart';
export 'package:element_x/features/home/cubit/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/home/models/room_filter.dart';
import 'package:element_x/features/home/repo/home_repo.dart';
import 'package:flutter/foundation.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repo, this._store) : super(const HomeState()) {
    _listener = reload;
    _store.addListener(_listener);
    reload();
  }

  final HomeRepo _repo;
  final MatrixStore _store;
  late final VoidCallback _listener;

  void reload() {
    emit(
      state.copyWith(
        rooms: _repo.rooms(filter: state.filter, query: state.query),
        online: _repo.online,
        syncing: _repo.syncing,
        showFtue: !_repo.ftueSeen,
      ),
    );
  }

  void setFilter(RoomFilter filter) {
    emit(
      state.copyWith(
        filter: filter,
        rooms: _repo.rooms(filter: filter, query: state.query),
      ),
    );
  }

  void setQuery(String query) {
    emit(
      state.copyWith(
        query: query,
        rooms: _repo.rooms(filter: state.filter, query: query),
      ),
    );
  }

  Future<void> acceptInvite(String roomId) async {
    await _store.joinRoom(roomId);
    final shown = state.rooms.any((room) => room.id == roomId);
    if (!shown && state.filter != RoomFilter.all) {
      setFilter(RoomFilter.all);
    }
  }

  Future<void> declineInvite(String roomId) => _store.leaveRoom(roomId);

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}
