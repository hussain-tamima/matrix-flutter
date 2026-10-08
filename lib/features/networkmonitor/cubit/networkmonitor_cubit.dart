import 'package:element_x/features/networkmonitor/cubit/networkmonitor_state.dart';
export 'package:element_x/features/networkmonitor/cubit/networkmonitor_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:flutter/foundation.dart';
import 'package:element_x/features/networkmonitor/repo/networkmonitor_repo.dart';

class NetworkMonitorCubit extends Cubit<NetworkMonitorState> {
  NetworkMonitorCubit(this._repo, this._store)
    : super(NetworkMonitorState(online: _repo.online)) {
    _listener = () => emit(NetworkMonitorState(online: _repo.online));
    _store.addListener(_listener);
  }

  final NetworkMonitorRepo _repo;
  final MatrixStore _store;
  late final VoidCallback _listener;

  void setOnline(bool value) => _repo.setOnline(online: value);

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}
